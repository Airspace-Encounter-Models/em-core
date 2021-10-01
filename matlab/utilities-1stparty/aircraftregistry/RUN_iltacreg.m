% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Inputs
clear all;
% https://www.ilent.nl/onderwerpen/luchtvaartuigregister/documenten/publicaties/2019/05/27/luchtvaartuigregister-aircraft-registration
% https://www.ilent.nl/onderwerpen/luchtvaartuigregister
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'ILT-AircraftRegistry' filesep '2020-06-10 Aircraft registrations.xlsx'];
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregilt-' '2020' '.mat'];

%% Load
opts = detectImportOptions(inFile,'NumHeaderLines',1);
opts.VariableTypes{6} = 'string'; opts.VariableNames{6} = 'acMfr';
opts.VariableTypes{8} = 'string'; opts.VariableNames{8} = 'acModel';
opts.VariableTypes{12} = 'string'; opts.VariableNames{12} = 'acType';
opts.VariableTypes{2} = 'datetime'; opts.VariableNames{2} = 'dateCert';
opts.VariableTypes{37} = 'string'; opts.VariableNames{37} = 'dateAir';
opts.VariableTypes{38} = 'string'; opts.VariableNames{38} = 'dateExp';
opts.VariableTypes{10} = 'string'; opts.VariableNames{10} = 'modeSHex'; % Mode S Transponder, binary
opts.VariableTypes{19} = 'double'; opts.VariableNames{19} = 'engNum'; % Number of Engines
Traw = readtable(inFile,opts,'ReadVariableNames',false);

% Remove rows with missing icao24
Traw(strcmpi(Traw.modeSHex,''),:) = [];

%% Parse
modeSHex = strtrim(Traw.modeSHex);
acMfr = strtrim(Traw.acMfr);
acModel = strtrim(Traw.acModel);

% The Dutch are nice and we know which are drones
acSeats = nan(size(modeSHex));
acSeats(contains(Traw.acType,'RPAS')) = 0;

%% Parse aircraft type
acType = Traw.acType;
acType = strrep(acType,'Balloon (Gas)','Balloon');
acType = strrep(acType,'Balloon (Hot Air)','Balloon');
acType(contains(acType,'Glider','IgnoreCase',true))= 'Glider';
acType(contains(acType,'Sailplane','IgnoreCase',true))= 'Glider';
acType(contains(acType,'Gyroplane','IgnoreCase',true)) = 'Gyroplane';
acType = strrep(acType,'Powered Parachute (Paramoteur)','PoweredParachute');
acType(contains(acType,'helicopter','IgnoreCase',true)) = 'Rotorcraft';
acType = strrep(acType,'Micro Light Aeroplane','Microlight');

isFW = contains(acType,{'aeroplane', 'turbo fan', 'prop-driven' ,'other' ,'aircraft'},'IgnoreCase',true);
acType(isFW & Traw.engNum <= 1) = 'FixedWingSingleEngine'; 
acType(isFW & Traw.engNum > 1) = 'FixedWingMultiEngine'; 

%% Parse Time
% Certification Date
dateCert = Traw.dateCert;

% Airworthiness date
dateAir = NaT(size(modeSHex)); % Preallocate
strAir = Traw.dateAir;
dateAir(~cellfun(@isempty,strAir)) = datetime(datenum(strAir(~cellfun(@isempty,strAir)),'yyyy-mm-dd'),'ConvertFrom','datenum');

% Expiration date
dateExp = NaT(size(modeSHex)); % Preallocate
strExp = Traw.dateExp;
dateExp(~cellfun(@isempty,strExp)) = datetime(datenum(strExp(~cellfun(@isempty,strExp)),'yyyy-mm-dd'),'ConvertFrom','datenum');

%% Save
% We don't need to save the input parser or raw data
clear Traw opts

% Save
save(outFile);