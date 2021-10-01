/* Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause */

#define _USE_MATH_DEFINES /* Use definitions defined in math.h */

#include <stdlib.h>
#include <math.h>
#include "mex.h"
#include "matrix.h"
#include "minmax.h"

/* Input Arguments */
#define	I_in	prhs[0] /* initial AC1 */
#define C_in    prhs[1] /* controls AC1 */
#define D_in    prhs[2] /* dynamics AC1 */
#define	I2_in	prhs[3] /* initial AC2 */
#define C2_in   prhs[4] /* controls AC2 */
#define D2_in   prhs[5] /* dynamics AC2 */
#define R_in    prhs[6] /* runtime */
#define opt_in  prhs[7] /* options in [nmac/enc cylinder break flag,renc,hend] */

/* Output Arguments */
#define results	plhs[0] /* results */
#define stats plhs[1]   /* stats */

/* Constants */
#define dt      0.1         /* Time step [s] */
#define K       1           /* Integration gain */
#define g       32.2        /* Acceleration of gravity [g] */
//#define qmax    3*M_PI/180  /* As in DEGAS [rad/s]     */
//#define rmax    1000000     /* As in DEGAS GA_psidotMAX = 1e6; */
#define phi_max 75*M_PI/180
#define phidotmax       0.524 
//#define v_high  1116      /* Airspeed limits - Mach 1*/
//#define v_low   1.7
#define num_ac  2           /* Number of Aircraft */
//#define dh_ftps_max    10000  /* Vertical Rate limits */
//#define dh_ftps_min    -10000  /* Vertical Rate limits */

/* Column Definitions */
#define col_v 0
#define col_N 1
#define col_E 2
#define col_h 3
#define col_psi 4
#define col_theta 5
#define col_phi 6
#define col_a 7

/* Output Definitions */
#define numout 8    /* Number of outputs for each aircraft */
#define numout_tot numout*num_ac    /* Number of total outputs */
#define Tout 0      /* Output locations */
#define Nout 1
#define Eout 2
#define hout 3
#define vout 4
#define phiout 5
#define thetaout 6
#define psiout 7

static void degas(
		   double	x[],
           double   d[],
		   double	*ptrc,
 		   unsigned int	cmd_i,
           unsigned int c_m
		   )
{    
    double      v_low,v_high,dh_ftps_min,dh_ftps_max,qmax,rmax, 
                s_theta,c_theta,t_theta, /* Trig. values of Euler angles */
                s_phi,c_phi,
                s_psi,c_psi,
                acmd,dpsicmd,dhcmd,         /* Current commands */
                hd,hddcmd,
                q,
                r,
                hdd_cmd_phi,
                sqrt_arg,phimax,phi_max_2,cphi1,
                phi_cmd0,psidot_if_no_change,dpsidot,psidot_err_out,p,psidot_err_in=0,
                phidot,thetadot,psidot,
                Ndot,Edot,hdot;    
  
    
    v_low = d[0];
    v_high = d[1];
    dh_ftps_min = d[2];
    dh_ftps_max = d[3];
    qmax = d[4];
    rmax = d[5];
    
    /* Computing angles here is more efficient than computing within each function */
    s_theta = sin(x[col_theta]); c_theta = cos(x[col_theta]); t_theta = tan(x[col_theta]);
    s_phi = sin(x[col_phi]); c_phi = cos(x[col_phi]);
    s_psi = sin(x[col_psi]); c_psi = cos(x[col_psi]);
    
    /* Get commands */
    acmd = *(ptrc+3*c_m+cmd_i);
    dpsicmd = *(ptrc+2*c_m+cmd_i);
    dhcmd = *(ptrc+1*c_m+cmd_i);
    dhcmd = MAX( MIN( dh_ftps_max, dhcmd ), dh_ftps_min ); /* Vertical rate saturation */
    
    /* resolve TCAS and script */
    hd = x[col_v]*s_theta;
    hddcmd = 1/dt*(dhcmd-hd); 
    
    /* Compute and saturate q */
    q = 1/(MAX(x[col_v],1)*c_phi)*(hddcmd/c_theta+g*c_theta*s_phi*s_phi-acmd*t_theta);
    q = MAX(q,-qmax); q = MIN(q,qmax);
    
    /* Compute and saturate r */
    r = g*s_phi*c_theta/MAX(x[col_v],1);
    r = MAX(r,-rmax); r = MIN(r,rmax);
    
    /* Compute phimax */
    hdd_cmd_phi = MIN( hddcmd , MAX(x[col_v],1)*qmax*c_phi*c_theta );
    
    /* calculate discriminant */
    sqrt_arg = pow(MAX(x[col_v],1),2)*pow(qmax,2) - 4*g*acmd*s_theta + 4*g*hdd_cmd_phi + 4*pow(g,2)*pow(c_theta,2);
    if(sqrt_arg<0)
        phi_max_2 = 10000;
    else
    {
        /* calculate cos(phi) */
        cphi1 = ( -MAX(x[col_v],1)*qmax + sqrt( sqrt_arg ) ) / (2*g*c_theta);
        
        if(abs(cphi1) < 1)
            phi_max_2  = acos( cphi1 )*.98; /* add a small buffer to prevent jittering */
        else
            phi_max_2 = 0; /* well, we can't achieve rate, so set bank angle to zero and do our best */
    }
    
    phimax = MIN(phi_max,phi_max_2);
    
    /* Compute and saturate p */
    phi_cmd0 = atan(dpsicmd*x[col_v]/g);
    psidot_if_no_change = (q*s_phi+r*c_phi)/c_theta;
    dpsidot = dpsicmd - psidot_if_no_change;
    psidot_err_out = psidot_err_in + dpsidot;
    p = 0*(phi_cmd0 - x[col_phi]) + 20*dpsidot + 0.0*psidot_err_out;
    /* limit max rollrate */
    if(p > phidotmax)
        p = phidotmax;
    if(p < -phidotmax)
        p = -phidotmax;
    
    /* limit max bank angle */
    if(x[col_phi]+p*dt > phimax)
        p = (phimax - x[col_phi])/dt;
    if(x[col_phi]+p*dt < -phimax)
        p = (-phimax - x[col_phi])/dt; 
    
    psidot_err_in = psidot_err_out;
    
    /* If need to do compute r1 (when encountering sideslip), do here */
    /* Compute phidot,thetadot, psidot */
    phidot = p+q*s_phi*t_theta+r*c_phi*t_theta;
    thetadot = q*c_phi-r*s_phi;
    psidot = q*s_phi/c_theta+r*c_phi/c_theta;
    
    /* Compute Ndot, Edot and hdot */
    Ndot = x[col_v]*c_theta*c_psi;
    Edot = x[col_v]*c_theta*s_psi;
    hdot = x[col_v]*s_theta;
    
    /* Backwards Euler integration of the states (as in DEGAS) */
    x[col_v] = x[col_v]+(acmd)*dt*K;
    x[col_N] = x[col_N]+(Ndot)*dt*K;
    x[col_E] = x[col_E]+(Edot)*dt*K;
    x[col_h] = x[col_h]+(hdot)*dt*K;
    x[col_phi] = x[col_phi]+(phidot)*dt*K;
    x[col_theta] = x[col_theta]+(thetadot)*dt*K;
    x[col_psi] = x[col_psi]+(psidot)*dt*K;
    
    if(x[col_v] < 1.7)
        x[col_v] = 1.7;
    if(x[col_v] >= v_high)
                x[col_v] = v_high-0.000001;    
}


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 
    mxArray *stateout[8],*bufout;   /* Output variables */
    
    mwSize c_n,c_n2,        /* Matrix size types */
        c_m,c_m2;
    
    double  *ptri,*ptri2,   /* Input pointers */
            *ptrc,*ptrc2,   
            *ptrd,*ptrd2,         
            *ptrr,*ptropt;    
    
    double  *ptrout[8],     /* Output pointer array  */
            *ptrstats,
            *ptrbuf;     
    
    double  x[8],x2[8],   	/* Initial array             */
            d[6],d2[6],     /* dynamic limits array             */
            runtime,        /* Runtime [s] */
            nvalues,        /* Number of total time steps */
            currt,          /* Current time */
            cmd_max,cmd_max2,  /* Maximum (last) command index */
            Rhorz,Rvert,    /* Horizontal and vertical range components [ft] */
            renc=1000000,henc=1000000,      /* Encounter cylinder radius and height [ft] */
            tstop=0,        /* Time at which simulated ended [s] */
            timecontinue=0, /* Time to continue after cylinder has been penetrated (set to zero if don't want this option) */
            timecount=0,    /* Time from exit of encounter cylinder */
            minsimtime=0;   /* Minimum simulation run time [s] */
    
    unsigned int i,istop,j,     /* Dummy indices */
            cmd_i,cmd_i2,   /* Command indices */
            currac,         /* Current aircraft  */
            curracstate,    /* Current aircraft state (for saving) */
            nmac=0,           /* NMAC state */
            nenccyl=0,        /* Not in encounter cylinder state */
            prevenccyl=0,      /* Previous value of not in encounter cylinder state flag (to detect change) */
            breakflag=0,      /* Break flag for NMAC state or encounter cylinder state */
            latchcyl=0,     /* Latch breakout input (will only breakout of cylinder if have been in cylinder for some time) */
            latchcylflag=0, /* When true (1), indicates that intruder has penetrated cylinder */
            latchbreak=0,   /* Allow break out of function if latch break true */
            timebreak=0;    /* Allow break out of function if time break true */
    
    /* Define fieldnames for output */
    const char *fieldnames[8];
        fieldnames[Tout] = "time";
        fieldnames[Nout] = "north_ft";
        fieldnames[Eout] = "east_ft";
        fieldnames[hout] = "up_ft";
        fieldnames[vout] = "speed_ftps";
        fieldnames[phiout] = "phi_rad";
        fieldnames[thetaout] = "theta_rad";
        fieldnames[psiout] = "psi_rad";
       
    /* Get pointers to inputs     */
    ptri = mxGetPr(I_in); ptri2 = mxGetPr(I2_in);
    ptrc = mxGetPr(C_in); ptrc2 = mxGetPr(C2_in); 
    ptrd = mxGetPr(D_in); ptrd2 = mxGetPr(D2_in);       
    ptrr = mxGetPr(R_in); 
    
    if (nrhs < 7) {
        mexErrMsgTxt("More input arguments required.");        
    }
    if(nrhs==8){ /* If input parameters specified */
        if(mxGetN(opt_in)<6)
            mexErrMsgTxt("Six elements (columns) required in input parameters vector.");     
        ptropt = mxGetPr(opt_in); 
        breakflag = (unsigned int)*(ptropt+0);
        renc = *(ptropt+1);
        henc = *(ptropt+2); 
        latchcyl = *(ptropt+3);
        timecontinue = *(ptropt+4);  
        minsimtime = *(ptropt+5);
    } /* If not specified, do not break or care about encounter cylinder      */
     
    /* Size of controls matrix */
    c_n = mxGetN(C_in); c_m = mxGetM(C_in); 
    c_n2 = mxGetN(C2_in); c_m2 = mxGetM(C2_in); 
    cmd_max = (double)c_m;      /* Number of commands */
    cmd_max2 = (double)c_m2;    /* Number of commands */
    cmd_i = 0;  /* Current command index  */
    cmd_i2 = 0;
    
    /* Get input options     */
    runtime = *ptrr;        /* Runtime [s]     */
    nvalues = runtime/dt+1; /* Number of total time steps       */

    /* Create buffer for outputs (cols = outputs) */
    bufout = mxCreateDoubleMatrix((mwSize)nvalues,numout_tot,mxREAL);
    ptrbuf = mxGetPr(bufout);
    
    /* Create output structure */
    results = mxCreateStructMatrix(1,num_ac,numout,fieldnames);
   
    /* Create stats output */
    stats = mxCreateDoubleMatrix(3,1,mxREAL);
    ptrstats = mxGetPr(stats);
    
    /* Get the initial conditions (second value through end value) */
    for(i=0;i<8;i++){        
        x[i] = *(ptri+i+1); 
        x2[i] = *(ptri2+i+1);} 

    /* Get the dynamic limits */
    for(i=0;i<7;i++){        
        d[i] = *(ptrd+i); 
        d2[i] = *(ptrd2+i);}              

    /* Loop through each time */
    for(i=0;i<(int)nvalues;i++) /* Loop over all time */
    {
        currt = i*dt;   /* Current time */

        if(i>0)         /* If any time step but first */
        {            
            /* Determine current input command */
            if(*(ptrc+cmd_i+1)==currt && (cmd_i+1)<(int)cmd_max)
                cmd_i++;           
          
            if(*(ptrc2+cmd_i2+1)==currt && (cmd_i2+1)<(int)cmd_max2)
                cmd_i2++;  
            
            degas(x,d,ptrc,cmd_i,c_m);      /* Run dynamics AC1 */
            degas(x2,d2,ptrc2,cmd_i2,c_m2);  /* Run dynamics AC2 */
        }
        
        /* Save outputs to buffer (AC1)         */
        *(ptrbuf+(unsigned int)(Tout*nvalues)+i) = currt;
        *(ptrbuf+(unsigned int)(Nout*nvalues)+i) = x[col_N];
        *(ptrbuf+(unsigned int)(Eout*nvalues)+i) = x[col_E];
        *(ptrbuf+(unsigned int)(hout*nvalues)+i) = x[col_h];
        *(ptrbuf+(unsigned int)(vout*nvalues)+i) = x[col_v];
        *(ptrbuf+(unsigned int)(phiout*nvalues)+i) = x[col_phi];
        *(ptrbuf+(unsigned int)(thetaout*nvalues)+i) = x[col_theta];
        *(ptrbuf+(unsigned int)(psiout*nvalues)+i) = x[col_psi];                                     
        
        /* Save outputs to buffer (AC2) */
        *(ptrbuf+(unsigned int)((Tout+numout)*nvalues)+i) = currt;
        *(ptrbuf+(unsigned int)((Nout+numout)*nvalues)+i) = x2[col_N];
        *(ptrbuf+(unsigned int)((Eout+numout)*nvalues)+i) = x2[col_E];
        *(ptrbuf+(unsigned int)((hout+numout)*nvalues)+i) = x2[col_h];      
        *(ptrbuf+(unsigned int)((vout+numout)*nvalues)+i) = x2[col_v];
        *(ptrbuf+(unsigned int)((phiout+numout)*nvalues)+i) = x2[col_phi];
        *(ptrbuf+(unsigned int)((thetaout+numout)*nvalues)+i) = x2[col_theta];
        *(ptrbuf+(unsigned int)((psiout+numout)*nvalues)+i) = x2[col_psi];     
        
        /* Compute vertical and horizontal norm for execution stop */
        Rhorz = sqrt(pow(fabs(x[col_N]-x2[col_N]),2)+pow(fabs(x[col_E]-x2[col_E]),2));
        Rvert = fabs(x[col_h]-x2[col_h]);        
        
        /* Determine current nmac and encounter state */
        if(Rhorz<500 && Rvert<100)
            nmac=1;    
        
        nenccyl = Rhorz>renc || Rvert>henc; /* Not in encounter cylinder */
 
        if(Rhorz<=renc && Rvert<=henc) /* Set latch once encounter cylinder penetrated */
            latchcylflag=1;
        
        if(prevenccyl==1) /* Increment time after first encounter cylinder exit */
            timecount=timecount+dt;
        
        if(nenccyl==1 && latchcylflag==1) /* Start exit time counter if exited encounter cylinder for first time */
            prevenccyl=1;            
        
        /* Determine if we have satisfied the initial latch criteria */
        latchbreak = (latchcylflag==1 && latchcyl==1) || (latchcyl==0);
        
        /* Time to break out after exiting cylinder */
        timebreak = timecount>=timecontinue; /* If timecontinue zero, nothing changes (always true) */
        
        /* Determine if we need to break out */
        if(breakflag==1 && nenccyl==1 && latchbreak==1 && timebreak==1 && currt>=minsimtime) /* Breakout with exit of cylinder, latched, and time after exit satisfied */ 
            break;
        if(breakflag==2 && nmac==1 && currt>=minsimtime) /* Breakout with NMAC reached */
            break;
    }
    
    tstop = currt;  /* Last time dynamics executed [s] */
    istop = (unsigned int)(tstop/dt); /* Last index */
    
    /* Save stats outputs */
    *(ptrstats) = tstop;
    *(ptrstats+1) = (double)nmac;
    *(ptrstats+2) = (double)nenccyl;
    
    /* Save outputs to output structure */
    currac = 0; curracstate = 0;    
    for(i=0;i<numout_tot;i++){  
        stateout[i] = mxCreateDoubleMatrix((mwSize)(istop+1),1,mxREAL);
        ptrout[i] = mxGetPr(stateout[i]);
        for(j=0;j<istop+1;j++){
            *(ptrout[i]+j) = *(ptrbuf+(unsigned int)(i*nvalues)+j);
        }
        mxSetField(results,currac,fieldnames[curracstate],stateout[i]);  
        curracstate++;
        if(curracstate==numout){
            curracstate=0;
            currac++;
        }
    }
   
    return;    
}
