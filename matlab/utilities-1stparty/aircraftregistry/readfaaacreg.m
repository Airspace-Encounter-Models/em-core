function readfaaacreg(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%
% SEE ALSO parseCert

%% Input parser
p = inputParser;

% Name of input file
addOptional(p,'inDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-AircraftRegistry']);

% Name if output file
addOptional(p,'outFile',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregfaa-' date '.mat']);

% Parse
parse(p,varargin{:});

%% Load aircraft reference file
fid = fopen([p.Results.inDir filesep 'ACFTREF.txt'],'r'); % Open File

% Based on number of characters in header row, read in data
% The FAA changed the aircraft reference file in 2020, the switch / case is
% to promotes backwards compatibility with data prior to 2020/12/03
% https://github.com/Airspace-Encounter-Models/em-core/issues/4
textHeader = fgetl(fid); % Get headerline
switch numel(strfind(textHeader,','))
    case 11
        textACREF = textscan(fid,'%07.0s %030.0s %020.0s %01.0s %02.0s %01.0s %01.0s %02.0s %03.0f %07.0s %04.0s','HeaderLines',0,'Delimiter',',');
    case 13
        textACREF = textscan(fid,'%07.0s %030.0s %020.0s %01.0s %02.0s %01.0s %01.0s %02.0s %03.0f %07.0s %04.0s %015.0s %050.0s','HeaderLines',0,'Delimiter',',');
    otherwise
        error('readfaaacreg:acreflen','%i fields in aircraft reference file, was expecting 11 or 13 fields',numel(strfind(textHeader,',')));
end
fclose(fid); % Close file

% Parse
acRefCode = strtrim(string(textACREF{1}));
acRefMfr = strtrim(string(textACREF{2}));
acRefModel = strtrim(string(textACREF{3}));
acRefSeats = textACREF{9};
acRefWeight = cellfun(@(x)(str2double(x(end))),textACREF{10},'uni',true); % Raw is CLASS 1, CLASS 2...we just want the numeric value
isAcRefsUAV = cellfun(@(x)(strcmpi(x,'CLASS4')),textACREF{10}); % Is small UAV, MGTOW < 55 lbs

%% Load master file and get raw data
fid = fopen([p.Results.inDir filesep 'MASTER.txt'],'r'); % Open File
textMaster = textscan(fid,'%05.0s %030.0s %07.0s %05.0s %04.0s %01.0s %050.0s %033.0s %033.0s %018.0s %02.0s %010.0s %01.0s %03.0s %02.0s %08.0s %08.0s %010.0s %01.0s %02.0s %02.0s %08.0s %01.0s %08.0s %050.0s %050.0s %050.0s %050.0s %050.0s %08.0s %08.0s %030.0s %020.0s %010.0s','HeaderLines',1,'Delimiter',',');
fclose(fid); % Close file

% Determine the number of lines in master
numLines = size(textMaster{1},1);

% Display status
fprintf('%s has %i lines\n',[p.Results.inDir filesep 'MASTER.txt'],numLines);

%% Assign or Preallocate
% Assign: Identifical Codes
numN = strtrim(string(textMaster{1})); % N-Number
numSerial = strtrim(string(textMaster{2})); % Serial number
uId = strtrim(string(textMaster{31})); % Unique Identification Number

% Assign: Aircraft Mfr Model Code
codeManu_AC = strtrim(string(cellfun(@(x)(x(1:3)),textMaster{3},'uni',false))); % Positions (38-40) - Manufacturer Code
codeModel_AC = strtrim(string(cellfun(@(x)(x(4:5)),textMaster{3},'uni',false))); % Positions (41-42) - Model Code
codeSeries_AC =  strtrim(string(cellfun(@(x)(x(6:7)),textMaster{3},'uni',false))); % Positions (43-44) - Series Code

% Assign: Engine
isEng = ~cellfun(@isempty,textMaster{4});
engMfr = strings(numLines,1);
engModel = strings(numLines,1);
engMfr(isEng) = strtrim(string(cellfun(@(x)(x(1:3)),textMaster{4}(isEng),'uni',false))); % Positions (46-48) - Manufacturer Code
engModel(isEng) = strtrim(string(cellfun(@(x)(x(4:5)),textMaster{4}(isEng),'uni',false))); % Positions (49-50) - Model Code

% Assign: Year manufactured
yearMfr = strtrim(string(textMaster{5}));

% Assign: Mode S
modeSHex = strtrim(string(textMaster{34})); % Mode S Code Hex
modeSCode = strtrim(string(textMaster{22})); % Aircraft Transponder Code

% Assign: Dates
dateLast = datetime(textMaster{16},'InputFormat','yyyyMMdd'); % Last Activity Date
dateCert = datetime(textMaster{17},'InputFormat','yyyyMMdd'); % Certificate Issue Date
dateAir = datetime(textMaster{24},'InputFormat','yyyyMMdd'); % Date of Airworthiness
dateExp = datetime(textMaster{30},'InputFormat','yyyyMMdd'); % Expiration date

% Preallocate (we need additional processing)
regType = strings(numLines,1);
codeAir = strings(numLines,1);
codeOpt = strings(numLines,1);
acType = strings(numLines,1);
acMfr = strings(numLines,1); % Name of the aircraft manufacturer
acModel = strings(numLines,1); % Name of the aircraft model and series
acSeats = zeros(numLines,1); % Maximum number of seats in the aircraft
acWeightClass = zeros(numLines,1); % Class code for Aircraft maximum gross take off weight in pounds
isSmallUAV = false(numLines,1);
engType = strings(numLines,1);

% Not parsed: Assign: Registration
% regName = string(textMaster{7}); % Registrant Name
% regState = string(textMaster{11}); % Registrant’s State
% codeStatus = string(textMaster{21}); % Status Code

% Not parsed: Kit
% kitMfr = string(textMaster{32}); % Kit Manufacturer Name
% kitModel = string(textMaster{33}); % Kit Model Name

% Not parsed: Other names
% textMaster(8); % Street1
% textMaster(9); % Street2
% textMaster(10); % Registrant’s City
% textMaster(12); % Zip Code
% textMaster(13); % Region
% textMaster(14); % County Mail
% textMaster(15); % Country Mail
% textMaster(25); % 1ST co-owner or partnership name
% textMaster(26); % 2ND co-owner or partnership name
% textMaster(27); % 3RD co-owner or partnership name
% textMaster(28); % 4TH co-owner or partnership name
% textMaster(29); % 5TH co-owner or partnership name

%% Iterate through file
for i = 1:numLines
    % Registrant Type
    if ~isempty(textMaster{6}{i})
        switch strtrim(textMaster{6}{i})
            case '1'
                regType(i) = "Individual";
            case '2'
                regType(i) = "Partnership";
            case '3'
                regType(i) = "Corporation";
            case '4'
                regType(i) = "CoOwned";
            case '5'
                regType(i) = "Government";
            case '8'
                regType(i) = "NonCitizenCorporation";
            case '9'
                regType(i) = "NonCitizenCoOwned";
        end
    else
        regType(i) = "";
    end
    
    % A - Airworthiness Classification Code
    % B - Approved Operation Codes
    cert = char(strtrim(textMaster{18}{i})); % Certification requested and uses
    [codeAir(i), codeOpt(i)] = parseCert(cert);
    
    % Type Aircraft
    if ~isempty(textMaster{19}{i})
        switch strtrim(textMaster{19}{i})
            case '1'
                acType(i) = "Glider";
            case '2'
                acType(i) = "Balloon";
            case '3'
                acType(i) = "BlimpDirigible";
            case '4'
                acType(i) = "FixedWingSingleEngine";
            case '5'
                acType(i) = "FixedWingMultiEngine";
            case '6'
                acType(i) = "Rotorcraft";
            case '7'
                acType(i) = "WeightShiftControl";
            case '8'
                acType(i) = "PoweredParachute";
            case '9'
                acType(i) = "Gyroplane";
            otherwise
                acType(i) = "ERROR";
        end
    else
        acType(i) = "BLANK";
    end
    
    % Type Engine
    if ~isempty(textMaster{20}{i})
        switch strtrim(textMaster{20}{i})
            case '0'
                engType(i) = "None";
            case '1'
                engType(i) = "Reciprocating";
            case '2'
                engType(i) = "TurboProp";
            case '3'
                engType(i) = "TurboShaft";
            case '4'
                engType(i) = "TurboJet";
            case '5'
                engType(i) = "TurboFan";
            case '6'
                engType(i) = "Ramjet";
            case '7'
                engType(i) = "Cycle2";
            case '8'
                engType(i) = "Cycle4";
            case '9'
                engType(i) = "Unknown";
            case '10'
                engType(i) = "Electric";
            case '11'
                engType(i) = "Rotary";
            otherwise
                engType(i) = "ERROR";
        end
    else
        engType(i) = "BLANK"
    end
    
    % Find the corresponding row in the aircraft reference file
    idxRef = find(textMaster{3}(i)==acRefCode,1,'first');
    acMfr(i) = acRefMfr{idxRef};
    acModel(i) = acRefModel{idxRef};
    acSeats(i) = acRefSeats(idxRef);
    acWeightClass(i) = acRefWeight(idxRef);
    isSmallUAV(i) = isAcRefsUAV(idxRef);
    
    % Display status
    if mod(i,1e4)==0; fprintf('i = %i, n = %i\n',i,numLines); end
    
end % End i for() loop

%% Save All
% We don't need to save the input parser or raw data
clear fid textMaster textACREF
% Also don't need to save aircraft reference file
clear acRefCode acRefMfr acRefModel acRefSeats acRefWeight isAcRefUAV
% Save
save(p.Results.outFile);
