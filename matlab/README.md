# MATLAB

Utilities to support MATLAB code. To streamline technology transfer, code is organized into two directories: one for third party software and the other for software developed directly by the aerospace encounter models team.

## MEX

This repository includes [MEX functions](https://www.mathworks.com/help/matlab/call-mex-file-functions.html) that will need to be compiled using [`mex`](https://www.mathworks.com/help/matlab/ref/mex.html). All functions can be compiled using the script, `RUN_mex`. If compiling manually, depending on the code you'll either need to call `mex` directly or use a build script. This table lists all the MEX functions.

| Function        |  Path |
| :-------------| :--  |
run_dynamics_fast | em-core\matlab\utilities-1stparty\run_dynamics_fast
InPolygon| em-core\matlab\utilities-3rdparty\InPolygon-MEX
mksqlite | em-core\matlab\utilities-3rdparty\mksqlite

### Note about run_dynamics_fast

 According to [MATLAB documentation](https://www.mathworks.com/help/matlab/ref/mex.html), `-g,` "Adds symbolic information and disables optimizing built object code." While this is flag is primarily used for debugging, there is a known bug, likely in the .c source, where the compiled mex functions will cause segmentation faults on Mac and Linux environments when compiled without the flag. This will generate a [MEX function](https://www.mathworks.com/help/matlab/call-mex-file-functions.html)--e.g., `filename.mexw64` for windows or `filename.mexa64` for linux. For some windows users, there have been issues compiling with `-g` and compiling without the flag works.

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2018, 2019, 2020, 2021 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
*