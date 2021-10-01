% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Inputs
clear all;

% Canadian Civil Aircraft Register
%https://wwwapps.tc.gc.ca/Saf-Sec-Sur/2/CCARCS-RIACC/DDZip.aspx
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'TC-AircraftRegistry' filesep 'carscurr.txt'];
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregtc-' '2020' '.mat'];

%% Read inFile
% see carslay.out
opts = detectImportOptions(inFile,'NumHeaderLines',0);
opts.VariableTypes{5} = 'string'; opts.VariableNames{5} = 'acModel';
opts.VariableTypes{8} = 'string'; opts.VariableNames{8} = 'acMfr';
opts.VariableTypes{11} = 'string'; opts.VariableNames{11} = 'acType';
opts.VariableTypes{18} = 'double'; opts.VariableNames{18} = 'engNum'; % Number of Engines
opts.VariableTypes{22} = 'string'; opts.VariableNames{22} = 'dateCert'; % Certificate Issue Date
opts.VariableTypes{23} = 'string'; opts.VariableNames{23} = 'dateAir'; % Date the Registration became effective
opts.VariableTypes{24} = 'string'; opts.VariableNames{24} = 'dateExp'; % Date the Registration expires
opts.VariableTypes{43} = 'string'; opts.VariableNames{43} = 'modeSBin'; % Mode S Transponder, binary
Traw = readtable(inFile,opts);
Traw(end,:) = []; % total row

%% Filter
Traw(isnan(Traw.engNum),:) = [];

%% Parse aircraft type
acType = strtrim(Traw.acType);
acType = strrep(acType,'Helicopter','Rotorcraft');
acType(Traw.engNum > 1) = strrep(acType(Traw.engNum > 1),'Aeroplane','FixedWingMultiEngine');
acType(Traw.engNum <= 1) = strrep(acType(Traw.engNum <= 1),'Aeroplane','FixedWingSingleEngine');

%% Parse
% https://www.mathworks.com/matlabcentral/answers/89526-binary-string-to-vector#answer_98970
modeSHex = strings(size(Traw,1),1);
for i=1:1:size(Traw,1)
   modeSHex(i) = strtrim(binaryVectorToHex(Traw.modeSBin{i}-'0')); 
end

acMfr = strtrim(Traw.acMfr);
acModel = strtrim(Traw.acModel);

%% Parse Time
% Date the Registration became effective
dateAir = datetime(datenum(Traw.dateAir,'yyyy/mm/dd'),'ConvertFrom','datenum');

% Expiration date
dateExp = NaT(size(modeSHex)); % Preallocate
strExp = Traw.dateExp;
dateExp(~cellfun(@isempty,strExp)) = datetime(datenum(strExp(~cellfun(@isempty,strExp)),'yyyy/mm/dd'),'ConvertFrom','datenum');

%% Create variables that we don't have data for
% These variables are created by readfaaacreg()
acSeats = nan(size(modeSHex));

%% Save
% We don't need to save the input parser or raw data
clear Traw opts

% Save
save(outFile);