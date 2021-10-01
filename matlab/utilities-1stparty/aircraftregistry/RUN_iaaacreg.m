% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Inputs
clear all;
% https://www.iaa.ie/commercial-aviation/aircraft-registration-2/latest-register-and-monthly-changes-1
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'IAA-AircraftRegistry' filesep '31-may-2020.xlsx'];
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregiaa-' '2020' '.mat'];

%% Read inFile
opts = detectImportOptions(inFile,'NumHeaderLines',1);
opts.VariableTypes{2} = 'string'; opts.VariableNames{2} = 'acMfr';
opts.VariableTypes{3} = 'string'; opts.VariableNames{3} = 'acModel';
opts.VariableTypes{4} = 'string'; opts.VariableNames{4} = 'acType';
opts.VariableTypes{5} = 'string'; opts.VariableNames{5} = 'dateAir';
opts.VariableTypes{9} = 'string'; opts.VariableNames{9} = 'modeSHex'; % Mode S Transponder, binary
opts.VariableTypes{12} = 'double'; opts.VariableNames{12} = 'engNum'; % Number of Engines
Traw = readtable(inFile,opts,'ReadVariableNames',false);
Traw(end-2:end,:) = []; % Remove empty and total row

%% Remove rows without a mode s
Traw(strcmpi(Traw.modeSHex,'N/A'),:) = [];

%% Parse
modeSHex = strtrim(Traw.modeSHex);
acMfr = strtrim(Traw.acMfr);
acModel = strtrim(Traw.acModel);

%% Parse aircraft type
acType = Traw.acType;
acType = strrep(acType,'BALLOON','Balloon');
acType = strrep(acType,'HOMEBUILD / SAILPLANE','Glider');
acType = strrep(acType,'POWERED Glider','Glider');
acType = strrep(acType,'SAILPLANE','Glider');
acType = strrep(acType,'HOMEBUILD / GYROCOPTER','Gyroplane');
acType = strrep(acType,'GYROCOPTER','Gyroplane');
acType = strrep(acType,'HOMEBUILD / MICROLIGHT','Microlight');
acType = strrep(acType,'MICROLIGHT','Microlight');
acType = strrep(acType,'POWER PARAGLIDER','PoweredParachute');
acType = strrep(acType,'ROTORCRAFT','Rotorcraft');

acType(Traw.engNum > 1) = strrep(acType(Traw.engNum > 1),'HOMEBUILD / AMPHIBIAN','FixedWingMultiEngine');
acType(Traw.engNum <= 1) = strrep(acType(Traw.engNum <= 1),'HOMEBUILD / LAND AEROPLANE','FixedWingSingleEngine');

acType(Traw.engNum > 1) = strrep(acType(Traw.engNum > 1),'HOMEBUILD / LAND AEROPLANE','FixedWingMultiEngine');
acType(Traw.engNum <= 1) = strrep(acType(Traw.engNum <= 1),'HOMEBUILD / AMPHIBIAN','FixedWingSingleEngine');

acType(Traw.engNum <= 1) = strrep(acType(Traw.engNum <= 1),'AMPHIBIAN','FixedWingSingleEngine');
acType(Traw.engNum > 1) = strrep(acType(Traw.engNum > 1),'AMPHIBIAN','FixedWingMultiEngine');

acType(Traw.engNum <= 1) = strrep(acType(Traw.engNum <= 1),'LAND AEROPLANE','FixedWingSingleEngine');
acType(Traw.engNum > 1) = strrep(acType(Traw.engNum > 1),'LAND AEROPLANE','FixedWingMultiEngine');

%% Parse Time
% Certificate Issue Date ?
dateAir = datetime(datenum(Traw.dateAir,'dd/mm/yyyy'),'ConvertFrom','datenum');

%% Create variables that we don't have data for
% These variables are created by readfaaacreg()
acSeats = nan(size(modeSHex));
dateExp = NaT(size(modeSHex)); % Preallocate

%% Save
% We don't need to save the input parser or raw data
clear Traw opts

% Save
save(outFile);