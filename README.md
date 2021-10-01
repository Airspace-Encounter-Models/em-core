# em-core

Software and data used by multiple repositories in the [Aerospace Encounter Models organization](https://github.com/Airspace-Encounter-Models).

- [em-core](#em-core)
  - [Initial Setup](#initial-setup)
    - [Persistent System Environment Variables](#persistent-system-environment-variables)
    - [MINGW Requirements](#mingw-requirements)
    - [Scripts](#scripts)
    - [MATLAB MEX](#matlab-mex)
    - [Process FAA Data](#process-faa-data)
  - [Data](#data)
  - [Language Specific Directories](#language-specific-directories)
  - [Output](#output)
  - [Distribution Statement](#distribution-statement)

## Initial Setup

This section specifies the run order and requirements for the initial setup the repository. Other repositories in this organization are reliant upon this setup being completed.

### Persistent System Environment Variables

Immediately after cloning this repository, [create a persistent system environment](https://superuser.com/q/284342/44051) variable titled `AEM_DIR_CORE` with a value of the full path to this repository root directory.

On unix there are many ways to do this, here is an example using [`/etc/profile.d`](https://unix.stackexchange.com/a/117473). Create a new file `aem-env.sh` using `sudo vi /etc/profile.d/aem-env.sh` and add the command to set the variable:

```bash
export AEM_DIR_CORE=PATH TO /em-core
```

You can confirm `AEM_DIR_CORE` was set in unix by inspecting the output of `env`.

### MINGW Requirements

To run the code within a MINGW environment, a working installation of Perl is required. If Perl is not already installed in your environment (e.g., when using Git Bash for Windows), you can download [Strawberry Perl](https://strawberryperl.com/), install it and add it to your PATH. This step must be done before running the setup script when using MINGW. The `bootstrap.sh` (see below) script will install `xpath` and` Scalar::Util` using Perl's cpan tool.

### Scripts

This is a set of boilerplate scripts describing the [normalized script pattern that GitHub uses in its projects](https://github.blog/2015-06-30-scripts-to-rule-them-all/). The [GitHub Scripts To Rule Them All](https://github.com/github/scripts-to-rule-them-all) was used as a template. Refer to the [script directory README](./script/README.md) for more details.

You will need to run these scripts in this order to download dependencies, initialize git submodules, download the default digital elevation models, airspace data, etc.

1. [bootstrap](./script/README.md#scriptbootstrap)
2. [setup](./script/README.md#scriptsetup)

### MATLAB MEX

Compile the [MEX functions](https://www.mathworks.com/help/matlab/call-mex-file-functions.html) detailed in the [MATLAB directory README](./matlab/README.md).

### Process FAA Data

1. Run in MATLAB `RUN_Airspace_1.m` to parse and process the [FAA class airspace definitions](./data/FAA-NASR/README.md)
2. Run in MATLAB `RUN_readfaaacreg.m` to parse and process the [FAA aircraft registry](./data/FAA-AircraftRegistry/README.md)
3. Run in MATLAB `RUN_readfaadof.m` to parse and process the [FAA digital obstacle file](./data/FAA-DOF/README.md)

## Data

Commonly used datasets, refer to the [data directory README](./data/README.md) for more details. Data directories are organized by prefixes.

## Language Specific Directories

Utilities to support specific software. Each programming language (i.e. MATLAB) should have their own dedicated directory.

## Output

Default output directory for RUN scripts and functions.

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2018, 2019, 2020, 2021 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
