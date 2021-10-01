% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Inputs
% https://ardis.iomaircraftregistry.com/
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'ARDIS-AircraftRegistry' filesep '2020-06-11-IsleofManAircraftRegister.csv'];
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregardis-' '2020' '.mat'];

%% Read inFile
Traw = readtable(inFile,'HeaderLines',2,'ReadVariableNames',true);

%% Parse
modeSHex = strtrim(string(Traw.ModeSNumber));
acMfr = strtrim(string(Traw.AircraftManufacturer));
acModel = strtrim(string(Traw.AircraftType));

%% Parse Time
% Certificate Issue Date ?
dateCert = datetime(datenum(string(Traw.DateRegistered),'dd mmm yyyy'),'ConvertFrom','datenum');

% Expiration date
dateExp = NaT(size(modeSHex)); % Preallocate
strExp = string(Traw.DeRegisteredDate);
dateExp(~strcmp(strExp,"")) = datetime(datenum(strExp(~strcmp(strExp,"")),'dd mmm yyyy'),'ConvertFrom','datenum');

%% Create variables that we don't have data for
% These variables are created by readfaaacreg()
acSeats = nan(size(modeSHex));

%% Save
% We don't need to save the input parser or raw data
clear Traw

% Save
save(outFile);
