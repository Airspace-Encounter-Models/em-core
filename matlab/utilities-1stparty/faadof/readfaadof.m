function Tdof = readfaadof(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Input parser
p = inputParser;

% Name of input file
addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-DOF' filesep 'DOF.DAT']);

% Save
addOptional(p,'isSave',true);
addOptional(p,'outFile',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof-' date '.mat']);

% Parse
p.parse(p,varargin{:});

%% Iterate through file and get raw data
% Open File
fid = fopen(p.Results.inFile,'r');
% Read all lines
textRaw = textscan(fid,'%s','delimiter','\n');
% Close file
fclose(fid);

% Reformat into N X 1 cell array and remove header line if needed
textRaw = textRaw{1}(1:end);

% Determine the number of lines
% numLines = length(textRaw{1});
numLines = size(textRaw,1);
numLines = numLines-5;

% Display status
fprintf('%s has %i lines\n',p.Results.inFile,numLines);

%% Preallocate - Fields
% https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/media/DOF_README_09-03-2019.pdf
oas_code = cell(numLines,1);
obs_num = cell(numLines,1); % Observation Number
verification_status = strings(numLines,1);

id_country = cell(numLines,1);
id_state = cell(numLines,1);

id_city = cell(numLines,1);

% Latitude
latDeg = zeros(numLines,1);
latMin = zeros(numLines,1);
latSec = zeros(numLines,1);
latHemi = strings(numLines,1);

% Longitude
lonDeg = zeros(numLines,1);
lonMin = zeros(numLines,1);
lonSec = zeros(numLines,1);
lonHemi = strings(numLines,1);

obs_type = strings(numLines,1);
quantity = zeros(numLines,1);

% Height
alt_ft_agl = zeros(numLines,1);
alt_ft_msl = zeros(numLines,1);

lighting = strings(numLines,1);
mark = strings(numLines,1);

% Accuracy
acc_horz_ft = zeros(numLines,1);
acc_vert_ft = zeros(numLines,1);

studyNum = cell(numLines,1);
action = strings(numLines,1);
date_julian = strings(numLines,1);

%% Iterate through file
for i = 1:1:numLines
    % Filter for ith line
    % Start on line 5
    texti = textRaw{i+4}; %regexprep(textRaw{i}, '\s+', '');
    
    oas_code{i} = texti(1:2);
    obs_num{i} = texti(4:9); % Observation Number
    verification_status(i) = texti(11);
    
    id_country{i} = lower(strtrim(texti(13:14)));
    id_state{i} = lower(strtrim(texti(16:17)));
    id_city{i} = lower(strtrim(texti(19:34)));
    
    % Latitude
    latDeg(i) = str2double(texti(36:37));
    latMin(i) = str2double(texti(39:40));
    latSec(i) = str2double(texti(42:46));
    latHemi(i) = texti(47);
    
    % Longitude
    lonDeg(i) = str2double(texti(49:51));
    lonMin(i) = str2double(texti(53:54));
    lonSec(i) = str2double(texti(56:60));
    lonHemi(i) = texti(61);
    
    obs_type(i) = lower(strtrim(texti(63:80)));
    quantity(i) = str2double(texti(82));
    
    % Height
    alt_ft_agl(i) = str2double(texti(84:88));
    alt_ft_msl(i) = str2double(texti(90:94));
    
    lighting(i) = str2double(texti(96));
    mark(i) = str2double(texti(102));
    
    % Horizontal Accuracy
    switch texti(98)
        case '1'
            acc_horz_ft(i) = 20;
        case '2'
            acc_horz_ft(i) = 50;
        case '3'
            acc_horz_ft(i) = 100;
        case '4'
            acc_horz_ft(i) = 250;
        case '5'
            acc_horz_ft(i) = 500;
        case '6'
            acc_horz_ft(i) = 1000;
        case '7'
            acc_horz_ft(i) = 3038; % 1/2 nm % unitsratio('ft','nm')*0.5;
        case '8'
            acc_horz_ft(i) = 6076; % 1 nm % unitsratio('ft','nm')*1;
        case '9'
            acc_horz_ft(i) = NaN;
        otherwise
    end
    
    % Vertical Accuracy
    switch texti(100)
        case 'A'
            acc_vert_ft(i) = 3;
        case 'B'
            acc_vert_ft(i) = 10;
        case 'C'
            acc_vert_ft(i) = 20;
        case 'D'
            acc_vert_ft(i) = 50;
        case 'E'
            acc_vert_ft(i) = 125;
        case 'F'
            acc_vert_ft(i) = 250;
        case 'G'
            acc_vert_ft(i) = 500;
        case 'H'
            acc_vert_ft(i) = 1000;
        case 'I'
            acc_vert_ft(i) = NaN;
        otherwise
    end
    
    studyNum{i} = texti(104:117);
    action(i) = lower(strtrim(texti(119)));
    date_julian(i) = lower(strtrim(texti(121:127)));
end

%% Processing
% Convert to DMS
lat_deg = dms2degrees([latDeg, latMin, latSec]); lat_deg(latHemi == 'S') = -1*lat_deg(latHemi == 'S');
lon_deg = dms2degrees([lonDeg, lonMin, lonSec]); lon_deg(lonHemi == 'W') = -1*lon_deg(lonHemi == 'W');

% Convert to human readable
verification_status(verification_status=='O') = 'verified';
verification_status(verification_status=='U') = 'unverified';

% Create
iso_3166_2 = upper(strcat(id_country,'-',id_state));

%% Aggregate into table
% Organized columns into something more useful
Tdof = table(obs_num,iso_3166_2,obs_type,lat_deg,lon_deg,alt_ft_agl,alt_ft_msl,acc_horz_ft,acc_vert_ft,id_city,oas_code,action,date_julian,verification_status);
Tdof = sortrows(Tdof,{'iso_3166_2','verification_status','obs_type','obs_num'},{'ascend','descend','ascend','ascend'});

%% Save
if p.Results.isSave
    save(p.Results.outFile,'Tdof');
end

