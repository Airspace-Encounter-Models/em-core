#!/bin/sh
# Copyright 2018 - 2021, MIT Lincoln Laboratory
# SPDX-License-Identifier: BSD-2-Clause

# script/setup:
# Set up application for the first time after cloning,
# or set it back to the initial first unused state.

####### DOWNLOAD FAA Aircraft Registry
URL_AIRCRAFT_REG='http://registry.faa.gov/database/ReleasableAircraft.zip'

# Download file from FAA website
wget $URL_AIRCRAFT_REG -O $AEM_DIR_CORE/data/FAA-AircraftRegistry/faa_acreg_current.zip

# unzip all files
unzip -j -o $AEM_DIR_CORE/data/FAA-AircraftRegistry/faa_acreg_current.zip -d $AEM_DIR_CORE/data/FAA-AircraftRegistry/

####### DOWNLOAD FAA Aircraft Characteristics Database
# https://www.faa.gov/airports/engineering/aircraft_char_database/

URL_AIRCRAFT_DB='https://www.faa.gov/airports/engineering/aircraft_char_database/media/FAA-Aircraft-Char-Database-v2-201810.xlsx'

# Download file from FAA website
wget $URL_AIRCRAFT_DB -O $AEM_DIR_CORE/data/FAA-AircraftCharacteristicsDB/faa_acdb_current.xlsx

###### DOWNLOAD FAA AIRPORTS
# https://ais-faa.opendata.arcgis.com/datasets/e747ab91a11045e8b3f8a3efd093d3b5_0
URL_AIRPORTS='https://opendata.arcgis.com/datasets/e747ab91a11045e8b3f8a3efd093d3b5_0.zip'

# Download file
wget $URL_AIRPORTS -O $AEM_DIR_CORE/data/FAA-Airports/faa_airports_current.zip

# unzip all files
unzip -j -o $AEM_DIR_CORE/data/FAA-Airports/faa_airports_current.zip -d $AEM_DIR_CORE/data/FAA-Airports/

####### DOWNLOAD FAA DOF

URL_DOF='https://aeronav.faa.gov/Obst_Data/DAILY_DOF_DAT.ZIP'

# Download file from FAA website
wget $URL_DOF -O $AEM_DIR_CORE/data/FAA-DOF/faa_dof_current.zip

# unzip all files
unzip -j -o $AEM_DIR_CORE/data/FAA-DOF/faa_dof_current.zip -d $AEM_DIR_CORE/data/FAA-DOF/

####### DOWNLOAD FAA 28 DAY NASR SUBSCRIPTION

# Variable of URL for NASR metadata
URL_NASR_EDITION='https://soa.smext.faa.gov/apra/nfdc/nasr/chart?edition=current'

# 3 things happen in this command:
# Step #1: Using curl, download xml file
# Step #2: Using xpath, parse xml file for url attribute
# Step #3: Using command substitution, assign the URL string to a variable
# https://stackoverflow.com/q/4651437

# https://stackoverflow.com/a/3466183/363829
case "$(uname -s)" in
   Darwin)
    # Do something under Mac OS X platform
	URL_NASR_CURRENT=$(curl -s $URL_NASR_EDITION | xmllint --format - | xpath 'string(//product/@url)')
     ;;

   Linux)
	# xpath for xml parsing
	URL_NASR_CURRENT=$(curl -s $URL_NASR_EDITION | xpath -q -e 'string(//productSet/edition/product/@url)')
     ;;

   MINGW*)
	# MINGW (Windows). Running the command "xpath" does not seem to be guaranteed to work. xpath.bat is, however.
	URL_NASR_CURRENT=$(curl -s $URL_NASR_EDITION | xpath.bat -q -e 'string(//productSet/edition/product/@url)')
	;;
esac

# Download file from FAA website
wget $URL_NASR_CURRENT -O $AEM_DIR_CORE/data/FAA-NASR/faa_nasr_current.zip

# unzip only airspace class shape files
# -j strips all path info, and all files go into the target
# -o to silently force overwrite
# https://unix.stackexchange.com/a/59285/1408
unzip -j -o $AEM_DIR_CORE/data/FAA-NASR/faa_nasr_current.zip 'Additional_Data/Shape_Files/*' -d $AEM_DIR_CORE/data/FAA-NASR/

####### DOWNLOAD NATURAL EARTH DATA INTERNAL ADMINISTRATIVE BOUNDARIES
# https://www.naturalearthdata.com/

# Variable of URL for file
URL_NE_admin1='https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces.zip'

# Download file from Natural Earth Data - Admin
wget $URL_NE_admin1 -O $AEM_DIR_CORE/data/NE-Adminstrative/ne_admin1_current.zip

# unzip
# -o to silently force overwrite
# https://unix.stackexchange.com/a/59285/1408
unzip -o $AEM_DIR_CORE/data/NE-Adminstrative/ne_admin1_current.zip -d $AEM_DIR_CORE/data/NE-Adminstrative/

####### DOWNLOAD Global Self-consistent, Hierarchical, High-resolution Geography Database (GSHHG)
URL_GSHHG="https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhg/latest/gshhg-shp-2.3.7.zip"

# Download file
wget $URL_GSHHG -O $AEM_DIR_CORE/data/GSHHG/gshhg_current.zip

# Unzip all files (does not use -j option)
unzip -o $AEM_DIR_CORE/data/GSHHG/gshhg_current.zip -d $AEM_DIR_CORE/data/GSHHG/

####### DOWNLOAD NATURAL EARTH DATA OCEAN POLYGONS
# https://www.naturalearthdata.com/

# Variable of URL for file
URL_NE_ocean='https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_ocean.zip'

# Download file from Natural Earth Data - Admin
wget $URL_NE_ocean -O $AEM_DIR_CORE/data/NE-Ocean/ne_land_ocean.zip

# unzip
# -o to silently force overwrite
# https://unix.stackexchange.com/a/59285/1408
unzip -o $AEM_DIR_CORE/data/NE-Ocean/ne_land_ocean.zip -d $AEM_DIR_CORE/data/NE-Ocean/

####### DOWNLOAD NOAA GLOBE tiles
# https://www.ngdc.noaa.gov/mgg/topo/gltiles.html
URL_NOAA_GLOBE='https://www.ngdc.noaa.gov/mgg/topo/DATATILES/elev/all10g.zip'

# Download file
wget $URL_NOAA_GLOBE -O $AEM_DIR_CORE/data/DEM-GLOBE/noaa_globe_current.zip

# unzip
unzip -j -o $AEM_DIR_CORE/data/DEM-GLOBE/noaa_globe_current.zip -d $AEM_DIR_CORE/data/DEM-GLOBE/

####### DOWNLOAD NOAA GLOBE ESRI HEADERS
URL_GLOBE_HDR='ngdc.noaa.gov/mgg/topo/elev/esri/hdr'

# Create arrays
globehdr=a10g:b10g:c10g:d10g:e10g:f10g:g10g:h10g:i10g:j10g:k10g:l10b:l10g:m10g:n10g:o10g:p10g

# Iterate over arrays to download data and extract into directories
# https://www.rosettacode.org/wiki/Loop_over_multiple_arrays_simultaneously#UNIX_Shell
# http://www.jochenhebbrecht.be/site/2012-10-25/linux/changing-a-forward-slash-another-character-in-bash
oldifs=$IFS
IFS=:
i=0
for hdr in $globehdr; do
	URL_CURRENT=$URL_GLOBE_HDR/$hdr.hdr
	FILE_DOWNLOAD=$AEM_DIR_CORE/data/DEM-GLOBE/$hdr.hdr

	echo $URL_CURRENT
	echo $FILE_DOWNLOAD

	# Download file
	wget $URL_CURRENT -O $FILE_DOWNLOAD
done
IFS=$oldifs

####### THINGS A USER MUST DO
echo "THIS SCRIPT CAN'T DO EVERYTHING, HERE IS A LIST OF USER SPECIFIC TASKS"
echo "0) Download additional digital elevation models to \em-core\data\*"
echo "1) For MATLAB users, you need to MEX files"
