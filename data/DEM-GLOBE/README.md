# NOAA GLOBE

The NOAA Global Land One-km Base Elevation Project (GLOBE) project to develop the best available 30 arc-second elevation digital elevation model with worldwide coverage. The data is for elevations only. Elevations are given in meters above mean sea level using the WGS84 reference ellipsoid.

According to the [GLOBE documentation](https://www.ngdc.noaa.gov/mgg/topo/report/globedocumentationmanual.pdf):
> GLOBE is an internationally designed, developed, and independently peer-reviewed global
digital elevation model (DEM), at a latitude-longitude grid spacing of 30 arc-seconds (30").

> The Global Land One-Kilometer Base Elevation (GLOBE) digital elevation model (DEM) is a global
data set covering 180o  West to 180 degrees East longitude and 90 degrees North to 90 degrees South latitude. The horizontal
grid spacing is 30 arc-seconds (0.008333... degrees) in latitude and longitude, resulting in dimensions of 21,600 rows and 43,200 columns. At the Equator, a degree of latitude is about 111 kilometers. GLOBE has 120 values per degree, giving GLOBE slightly better than 1 km gridding at the Equator, and progressively finer longitudinally toward the Poles

## Download Instructions

### Script (Recommended)

[`script/setup.sh`](../../script/setup.sh) is used to set up the project in an initial state. It will download and extract the tiles and headers.

### Manual

The data are available directly from NOAA for download (For USA coverage, download data for tiles A,B,E,F):

* [Elevation tiles](https://www.ngdc.noaa.gov/mgg/topo/gltiles.html)
* [ESRI headers](https://www.ngdc.noaa.gov/mgg/topo/elev/esri/hdr/)

## Citation

<details> <summary>D. A. Hastings, P. K. Dunbar, "Global Land One-kilometer Base Elevation (GLOBE) Digital Elevation Model Documentation Volume 1.0", National Oceanic and Atmospheric Administration Key to Geophysical Records Documentation (KGRD), vol. 34, May 1999.</summary>
<p>

```tex
@techreport{hastingsGlobalLandOne1999,
  address = {{325 Broadway, Boulder, Colorado 80303, U.S.A}},
  type = {Professional {{Paper}}},
  title = {Global {{Land One Kilometer Base Elevation}} ({{GLOBE}}) {{Digital Elevation Model}}, {{Documentation}}, {{Volume}} 1.0. {{Key}}},
  abstract = {"This is the first version of documentation for the Global Land One-kilometer Base Elevation (GLOBE) data set. GLOBE is an internationally designed, developed, and independently peer-reviewed global digital elevation model (DEMj, at a latitude-longitude grid spacing of 30 arc-seconds (30"). This report describes the history of the GLOBE project, the candidate data sets, data compilation techniques, organization, and use of the data base. The data are available on CD-ROM and the World Wide Web"--Executive Summary.},
  language = {en},
  number = {NGDC Key to Geophysical Records Documentation No. 34},
  institution = {{National Oceanic and Atmospheric Administration,}},
  author = {Hastings, D. A. (David A.) and Dunbar, Paula K.},
  collaborator = {{National Geophysical Data Center}},
  month = may,
  year = {1999},
  keywords = {Computer programs,Digital elevation models,Documentation,Global differential geometry},
  pages = {133}
}
```
</p>
</details>

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2018, 2019, 2020, 2021 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
