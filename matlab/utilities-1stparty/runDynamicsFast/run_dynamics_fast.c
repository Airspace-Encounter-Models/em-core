/* Copyright 2018 - 2022, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause */

#define _USE_MATH_DEFINES /* Use definitions defined in math.h */

#include <math.h>
#include <stdlib.h>

#include "matrix.h"
#include "mex.h"
#include "minmax.h"

/* Input Arguments */
#define IN_INIT_1 prhs[0] /* initial AC1 */
#define IN_C_1 prhs[1]    /* controls AC1 */
#define IN_DYN_1 prhs[2]  /* dynamics AC1 */
#define IN_INIT_2 prhs[3] /* initial AC2 */
#define IN_C_2 prhs[4]    /* controls AC2 */
#define IN_DYN_2 prhs[5]  /* dynamics AC2 */
#define IN_R prhs[6]      /* runtime_s */
#define IN_OPT                                                               \
  prhs[7]          /* options in [nmac/enc cylinder break flag,renc_ft,hend] \
                    */
#define NUM_INIT 8 /* Number of initial variables */
#define NUM_DYN 6  /* Number of dynamic limit variables */

/* Output Arguments */
#define RESULTS plhs[0] /* RESULTS */
#define STATS plhs[1]   /* STATS */

/* Constants */
#define dt 0.1 /* Time step [s] */
#define K 1    /* Integration gain */
#define g 32.2 /* Acceleration of gravity [g] */
//#define qmax    3*M_PI/180  /* As in DEGAS [rad/s]     */
//#define rmax    1000000     /* As in DEGAS GA_psidotMAX = 1e6; */
#define MAX_PHI 75 * M_PI / 180
#define MAX_PHI_DOT 0.524
//#define v_ftps_max  1116      /* Airspeed limits - Mach 1*/
//#define v_ftps_min   1.7
#define NUM_AC 2 /* Number of Aircraft */
//#define dh_ftps_max    10000  /* Vertical Rate limits */
//#define dh_ftps_min    -10000  /* Vertical Rate limits */

/* Column Definitions */
#define COL_V 0
#define COL_N 1
#define COL_E 2
#define COL_H 3
#define COL_PSI 4
#define COL_THETA 5
#define COL_PHI 6
#define COL_A 7

/* Output Definitions */
#define NUM_OUT_AC 8 /* Number of outputs for each aircraft */
#define NUM_OUT_TOTAL NUM_OUT_AC *NUM_AC /* Number of total outputs */
#define OUT_T 0                          /* Output locations */
#define OUT_N 1
#define OUT_E 2
#define OUT_H 3
#define OUT_V 4
#define OUT_PHI 5
#define OUT_THETA 6
#define OUT_PSI 7

static void degas(double x[], double d[], double *ptrc, unsigned int cmd_i,
                  unsigned int c_m) {
  double v_ftps_min, v_ftps_max, dh_ftps_min, dh_ftps_max, qmax, rmax, s_theta,
      c_theta, t_theta, /* Trig. values of Euler angles */
      s_phi, c_phi, s_psi, c_psi, acmd, dpsicmd, dhcmd, /* Current commands */
      hd, hddcmd, q, r, hdd_cmd_phi, sqrt_arg, phimax, phi_max_2, cphi1,
      phi_cmd0, psidot_if_no_change, dpsidot, psidot_err_out, p,
      psidot_err_in = 0, phidot, thetadot, psidot, Ndot, Edot, hdot;

  v_ftps_min = d[0];
  v_ftps_max = d[1];
  dh_ftps_min = d[2];
  dh_ftps_max = d[3];
  qmax = d[4];
  rmax = d[5];

  /* Computing angles here is more efficient than computing within each function
   */
  s_theta = sin(x[COL_THETA]);
  c_theta = cos(x[COL_THETA]);
  t_theta = tan(x[COL_THETA]);
  s_phi = sin(x[COL_PHI]);
  c_phi = cos(x[COL_PHI]);
  s_psi = sin(x[COL_PSI]);
  c_psi = cos(x[COL_PSI]);

  /* Get commands */
  acmd = *(ptrc + 3 * c_m + cmd_i);
  dpsicmd = *(ptrc + 2 * c_m + cmd_i);
  dhcmd = *(ptrc + 1 * c_m + cmd_i);
  dhcmd =
      MAX(MIN(dh_ftps_max, dhcmd), dh_ftps_min); /* Vertical rate saturation */

  /* resolve TCAS and script */
  hd = x[COL_V] * s_theta;
  hddcmd = 1 / dt * (dhcmd - hd);

  /* Compute and saturate q */
  q = 1 / (MAX(x[COL_V], 1) * c_phi) *
      (hddcmd / c_theta + g * c_theta * s_phi * s_phi - acmd * t_theta);
  q = MAX(q, -qmax);
  q = MIN(q, qmax);

  /* Compute and saturate r */
  r = g * s_phi * c_theta / MAX(x[COL_V], 1);
  r = MAX(r, -rmax);
  r = MIN(r, rmax);

  /* Compute phimax */
  hdd_cmd_phi = MIN(hddcmd, MAX(x[COL_V], 1) * qmax * c_phi * c_theta);

  /* calculate discriminant */
  sqrt_arg = pow(MAX(x[COL_V], 1), 2) * pow(qmax, 2) - 4 * g * acmd * s_theta +
             4 * g * hdd_cmd_phi + 4 * pow(g, 2) * pow(c_theta, 2);
  if (sqrt_arg < 0)
    phi_max_2 = 10000;
  else {
    /* calculate cos(phi) */
    cphi1 = (-MAX(x[COL_V], 1) * qmax + sqrt(sqrt_arg)) / (2 * g * c_theta);

    if (abs(cphi1) < 1)
      phi_max_2 =
          acos(cphi1) * .98; /* add a small buffer to prevent jittering */
    else
      phi_max_2 = 0; /* well, we can't achieve rate, so set bank angle to zero
                  and do our best */
  }

  phimax = MIN(MAX_PHI, phi_max_2);

  /* Compute and saturate p */
  phi_cmd0 = atan(dpsicmd * x[COL_V] / g);
  psidot_if_no_change = (q * s_phi + r * c_phi) / c_theta;
  dpsidot = dpsicmd - psidot_if_no_change;
  psidot_err_out = psidot_err_in + dpsidot;
  p = 0 * (phi_cmd0 - x[COL_PHI]) + 20 * dpsidot + 0.0 * psidot_err_out;
  /* limit max rollrate */
  if (p > MAX_PHI_DOT) p = MAX_PHI_DOT;
  if (p < -MAX_PHI_DOT) p = -MAX_PHI_DOT;

  /* limit max bank angle */
  if (x[COL_PHI] + p * dt > phimax) p = (phimax - x[COL_PHI]) / dt;
  if (x[COL_PHI] + p * dt < -phimax) p = (-phimax - x[COL_PHI]) / dt;

  psidot_err_in = psidot_err_out;

  /* If need to do compute r1 (when encountering sideslip), do here */
  /* Compute phidot,thetadot, psidot */
  phidot = p + q * s_phi * t_theta + r * c_phi * t_theta;
  thetadot = q * c_phi - r * s_phi;
  psidot = q * s_phi / c_theta + r * c_phi / c_theta;

  /* Compute Ndot, Edot and hdot */
  Ndot = x[COL_V] * c_theta * c_psi;
  Edot = x[COL_V] * c_theta * s_psi;
  hdot = x[COL_V] * s_theta;

  /* Backwards Euler integration of the states (as in DEGAS) */
  x[COL_V] = x[COL_V] + (acmd)*dt * K;
  x[COL_N] = x[COL_N] + (Ndot)*dt * K;
  x[COL_E] = x[COL_E] + (Edot)*dt * K;
  x[COL_H] = x[COL_H] + (hdot)*dt * K;
  x[COL_PHI] = x[COL_PHI] + (phidot)*dt * K;
  x[COL_THETA] = x[COL_THETA] + (thetadot)*dt * K;
  x[COL_PSI] = x[COL_PSI] + (psidot)*dt * K;

  if (x[COL_V] < v_ftps_min) x[COL_V] = v_ftps_min;
  if (x[COL_V] >= v_ftps_max) x[COL_V] = v_ftps_max - 0.000001;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])

{
  mxArray *stateout[NUM_OUT_TOTAL], *bufout; /* Output variables */

  mwSize c_n, c_n2, /* Matrix size types */
      c_m, c_m2;

  double *ptri, *ptri2, /* Input pointers */
      *ptrc, *ptrc2, *ptrd, *ptrd2, *ptrr, *ptropt;

  double *ptrout[NUM_OUT_TOTAL], /* Output pointer array  */
      *ptrstats, *ptrbuf;

  double x[NUM_INIT], x2[NUM_INIT], /* Initial array             */
      d[NUM_DYN], d2[NUM_DYN],      /* dynamic limits array             */
      runtime_s,                    /* runtime_s [s] */
      nvalues,                      /* Number of total time steps */
      currt,                        /* Current time */
      cmd_max, cmd_max2,            /* Maximum (last) command index */
      Rhorz_ft, Rvert_ft, /* Horizontal and vertical range components [ft] */
      renc_ft = 1000000,
      henc_ft = 1000000, /* Encounter cylinder radius and height [ft] */
      tstop_s = 0,       /* Time at which simulated ended [s] */
      timecontinue = 0,  /* Time to continue after cylinder has been penetrated
                          (set to zero if don't want this option) */
      timecount = 0,     /* Time from exit of encounter cylinder */
      minsimtime = 0;    /* Minimum simulation run time [s] */

  unsigned int i, istop, j, /* Dummy indices */
      cmd_i, cmd_i2,        /* Command indices */
      currac,               /* Current aircraft  */
      curracstate,          /* Current aircraft state (for saving) */
      nmac = 0,             /* NMAC state */
      nenccyl = 0,          /* Not in encounter cylinder state */
      prevenccyl = 0, /* Previous value of not in encounter cylinder state flag
                 (to detect change) */
      breakflag = 0, /* Break flag for NMAC state or encounter cylinder state */
      latchcyl = 0,  /* Latch breakout input (will only breakout of cylinder if
               have been in cylinder for some time) */
      latchcylflag = 0, /* When true (1), indicates that intruder has penetrated
                     cylinder */
      latchbreak = 0,   /* Allow break out of function if latch break true */
      timebreak = 0;    /* Allow break out of function if time break true */

  /* Define fieldnames for output */
  const char *fieldnames[8];
  fieldnames[OUT_T] = "time";
  fieldnames[OUT_N] = "north_ft";
  fieldnames[OUT_E] = "east_ft";
  fieldnames[OUT_H] = "up_ft";
  fieldnames[OUT_V] = "speed_ftps";
  fieldnames[OUT_PHI] = "phi_rad";
  fieldnames[OUT_THETA] = "theta_rad";
  fieldnames[OUT_PSI] = "psi_rad";

  /* Get pointers to inputs     */
  ptri = mxGetPr(IN_INIT_1);
  ptri2 = mxGetPr(IN_INIT_2);
  ptrc = mxGetPr(IN_C_1);
  ptrc2 = mxGetPr(IN_C_2);
  ptrd = mxGetPr(IN_DYN_1);
  ptrd2 = mxGetPr(IN_DYN_2);
  ptrr = mxGetPr(IN_R);

  if (nrhs < 7) {
    mexErrMsgTxt("More input arguments required.");
  }
  if (nrhs == 8) { /* If input parameters specified */
    if (mxGetN(IN_OPT) < 6)
      mexErrMsgTxt(
          "Six elements (columns) required in input parameters vector.");
    ptropt = mxGetPr(IN_OPT);
    breakflag = (unsigned int)*(ptropt + 0);
    renc_ft = *(ptropt + 1);
    henc_ft = *(ptropt + 2);
    latchcyl = *(ptropt + 3);
    timecontinue = *(ptropt + 4);
    minsimtime = *(ptropt + 5);
  } /* If not specified, do not break or care about encounter cylinder      */

  /* Size of controls matrix */
  c_n = mxGetN(IN_C_1);
  c_m = mxGetM(IN_C_1);
  c_n2 = mxGetN(IN_C_2);
  c_m2 = mxGetM(IN_C_2);
  cmd_max = (double)c_m;   /* Number of commands */
  cmd_max2 = (double)c_m2; /* Number of commands */
  cmd_i = 0;               /* Current command index  */
  cmd_i2 = 0;

  /* Get input options     */
  runtime_s = *ptrr;            /* runtime_s [s]     */
  nvalues = runtime_s / dt + 1; /* Number of total time steps       */

  /* Create buffer for outputs (cols = outputs) */
  bufout = mxCreateDoubleMatrix((mwSize)nvalues, NUM_OUT_TOTAL, mxREAL);
  ptrbuf = mxGetPr(bufout);

  /* Create output structure */
  RESULTS = mxCreateStructMatrix(1, NUM_AC, NUM_OUT_AC, fieldnames);

  /* Create STATS output */
  STATS = mxCreateDoubleMatrix(3, 1, mxREAL);
  ptrstats = mxGetPr(STATS);

  /* Get the initial conditions */
  for (i = 0; i < NUM_INIT; i++) {
    x[i] = *(ptri + i);
    x2[i] = *(ptri2 + i);
  }

  /* Get the dynamic limits */
  for (i = 0; i < NUM_DYN; i++) {
    d[i] = *(ptrd + i);
    d2[i] = *(ptrd2 + i);
  }

  /* Loop through each time */
  for (i = 0; i < (int)nvalues; i++) /* Loop over all time */
  {
    currt = i * dt; /* Current time */

    if (i > 0) /* If any time step but first */
    {
      /* Determine current input command */
      if (*(ptrc + cmd_i + 1) == currt && (cmd_i + 1) < (int)cmd_max) cmd_i++;

      if (*(ptrc2 + cmd_i2 + 1) == currt && (cmd_i2 + 1) < (int)cmd_max2)
        cmd_i2++;

      degas(x, d, ptrc, cmd_i, c_m);      /* Run dynamics AC1 */
      degas(x2, d2, ptrc2, cmd_i2, c_m2); /* Run dynamics AC2 */
    }

    /* Save outputs to buffer (AC1)         */
    *(ptrbuf + (unsigned int)(OUT_T * nvalues) + i) = currt;
    *(ptrbuf + (unsigned int)(OUT_N * nvalues) + i) = x[COL_N];
    *(ptrbuf + (unsigned int)(OUT_E * nvalues) + i) = x[COL_E];
    *(ptrbuf + (unsigned int)(OUT_H * nvalues) + i) = x[COL_H];
    *(ptrbuf + (unsigned int)(OUT_V * nvalues) + i) = x[COL_V];
    *(ptrbuf + (unsigned int)(OUT_PHI * nvalues) + i) = x[COL_PHI];
    *(ptrbuf + (unsigned int)(OUT_THETA * nvalues) + i) = x[COL_THETA];
    *(ptrbuf + (unsigned int)(OUT_PSI * nvalues) + i) = x[COL_PSI];

    /* Save outputs to buffer (AC2) */
    *(ptrbuf + (unsigned int)((OUT_T + NUM_OUT_AC) * nvalues) + i) = currt;
    *(ptrbuf + (unsigned int)((OUT_N + NUM_OUT_AC) * nvalues) + i) = x2[COL_N];
    *(ptrbuf + (unsigned int)((OUT_E + NUM_OUT_AC) * nvalues) + i) = x2[COL_E];
    *(ptrbuf + (unsigned int)((OUT_H + NUM_OUT_AC) * nvalues) + i) = x2[COL_H];
    *(ptrbuf + (unsigned int)((OUT_V + NUM_OUT_AC) * nvalues) + i) = x2[COL_V];
    *(ptrbuf + (unsigned int)((OUT_PHI + NUM_OUT_AC) * nvalues) + i) =
        x2[COL_PHI];
    *(ptrbuf + (unsigned int)((OUT_THETA + NUM_OUT_AC) * nvalues) + i) =
        x2[COL_THETA];
    *(ptrbuf + (unsigned int)((OUT_PSI + NUM_OUT_AC) * nvalues) + i) =
        x2[COL_PSI];

    /* Compute vertical and horizontal norm for execution stop */
    Rhorz_ft = sqrt(pow(fabs(x[COL_N] - x2[COL_N]), 2) +
                    pow(fabs(x[COL_E] - x2[COL_E]), 2));
    Rvert_ft = fabs(x[COL_H] - x2[COL_H]);

    /* Determine current nmac and encounter state */
    if (Rhorz_ft < 500 && Rvert_ft < 100) nmac = 1;

    nenccyl = Rhorz_ft > renc_ft ||
              Rvert_ft > henc_ft; /* Not in encounter cylinder */

    if (Rhorz_ft <= renc_ft &&
        Rvert_ft <= henc_ft) /* Set latch once encounter cylinder penetrated */
      latchcylflag = 1;

    if (prevenccyl ==
        1) /* Increment time after first encounter cylinder exit */
      timecount = timecount + dt;

    if (nenccyl == 1 && latchcylflag == 1) /* Start exit time counter if exited
                                          encounter cylinder for first time */
      prevenccyl = 1;

    /* Determine if we have satisfied the initial latch criteria */
    latchbreak = (latchcylflag == 1 && latchcyl == 1) || (latchcyl == 0);

    /* Time to break out after exiting cylinder */
    timebreak =
        timecount >=
        timecontinue; /* If timecontinue zero, nothing changes (always true) */

    /* Determine if we need to break out */
    if (breakflag == 1 && nenccyl == 1 && latchbreak == 1 && timebreak == 1 &&
        currt >= minsimtime) /* Breakout with exit of cylinder, latched, and
                            time after exit satisfied */
      break;
    if (breakflag == 2 && nmac == 1 &&
        currt >= minsimtime) /* Breakout with NMAC reached */
      break;
  }

  tstop_s = currt;                      /* Last time dynamics executed [s] */
  istop = (unsigned int)(tstop_s / dt); /* Last index */

  /* Save STATS outputs */
  *(ptrstats) = tstop_s;
  *(ptrstats + 1) = (double)nmac;
  *(ptrstats + 2) = (double)nenccyl;

  /* Save outputs to output structure */
  currac = 0;
  curracstate = 0;
  for (i = 0; i < NUM_OUT_TOTAL; i++) {
    stateout[i] = mxCreateDoubleMatrix((mwSize)(istop + 1), 1, mxREAL);
    ptrout[i] = mxGetPr(stateout[i]);
    for (j = 0; j < istop + 1; j++) {
      *(ptrout[i] + j) = *(ptrbuf + (unsigned int)(i * nvalues) + j);
    }
    mxSetField(RESULTS, currac, fieldnames[curracstate], stateout[i]);
    curracstate++;
    if (curracstate == NUM_OUT_AC) {
      curracstate = 0;
      currac++;
    }
  }

  return;
}
