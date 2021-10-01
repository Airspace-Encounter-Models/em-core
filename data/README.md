# Data

Directories to store commonly used external datasets.

## Digital Elevation Models (DEM-)

A key feature of this repository is downloading and organizing digital elevation models (DEMs) to calculate the terrain elevation in mean sea level (MSL) and when using other repositories to generate aircraft track altitudes. For defaults, the [scripts](../script/README.md) will download [GLOBE](./DEM-GLOBE/README.md). For scalability, default directories for many DEMS are provided in this repository, however only the default DEMs will be populated during initial setup.

These defaults are based on the availability of [Matlab Mapping Toolbox functions to read and identify files](https://www.mathworks.com/help/map/determine-what-elevation-data-exists-for-a-region.html). We recognize that GLOBE does not have the same resolution as [USGS 3D Elevation Program (3DEP) Datasets from The National Map / National Elevation Dataset (NED)](https://www.sciencebase.gov/catalog/item/4f70a58ce4b058caae3f8ddb) OR SRTM1 / SRTM3. These differences are summarized by extending a table found in the [SRTM documentation](https://dds.cr.usgs.gov/srtm/version2_1/Documentation/SRTM_Topo.pdf):

| Posting (sample spacing)  | SRTM name |  DTED equivalent | Other|
| :-------------: | :--: | :-------------: | :-------------: |
| 1 arc-second| [SRTM1](https://dds.cr.usgs.gov/srtm/version2_1/SRTM1/) | [DTED2](https://www.nga.mil/ProductsServices/TopographicalTerrestrial/Pages/DigitalTerrainElevationData.aspx) | |
| 3 arc-second | [SRTM3](https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/) | [DTED1](https://www.nga.mil/ProductsServices/TopographicalTerrestrial/Pages/DigitalTerrainElevationData.aspx)  | |
| 30 arc-second | [SRTM30](./data/DEM-SRTM30/README.md) | [DTED0](https://www.nga.mil/ProductsServices/TopographicalTerrestrial/Pages/DigitalTerrainElevationData.aspx) | [GLOBE](./data/DEM-GLOBE/README.md), [GMTED2010](https://www.usgs.gov/land-resources/eros/coastal-changes-and-impacts/gmted2010), [GTOPO30](./data/DEM-GTOPO30/README.md) |

1 and 3 arc-second data are often formatted as hgt (SRTM), ArcGrid, GridFloat, or IMG files. You can review by inspecting formats listed by the [USGS Elevation Products (3DEP)](https://viewer.nationalmap.gov/datasets/) or the [SRTM data availability](https://dds.cr.usgs.gov/srtm/version2_1/Documentation/SRTM_Topo.pdf). The Matlab Mapping Toolbox currently does not fully support these formats. Specifically, while [`arcgridread`](https://www.mathworks.com/help/map/ref/arcgridread.html) can read a ArcGrid or GridFloat file, it can't read multiple files from a directory or filter based on latitude and longitude limits, such as [`globedem`](https://www.mathworks.com/help/map/ref/globedem.html).

SRTM1 and SRTM3 data are available in the DTED format via [mail order]((https://dds.cr.usgs.gov/srtm/version2_1/Documentation/SRTM_Topo.pdf)). [According to the NGA](https://www.nga.mil/ProductsServices/TopographicalTerrestrial/Pages/DigitalTerrainElevationData.aspx), distribution of DTED2 and DTED1 are authorized to the Department of Defense, U.S. DOD contractors, and to U.S. Government agencies that support DOD functions. Through these means, MIT Lincoln Laboratory has 1 and 3 arc-second data in the DTED format, however they are not authorized to release this datasets to the public.

## Federal Aviation Adminstration (FAA-)

Data download directory from the FAA. This includes data from the [28 day FAA NASR](./FAA-NASR/README.md) and [Digital Obstacle File (DOF)](./FAA-DOF/README.md) and aircraft registry.

## Natural Earth (NE-)

Administrative and oceanic vector data provided by [Natural Earth Data](https://www.naturalearthdata.com/).

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2018, 2019, 2020, 2021 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
