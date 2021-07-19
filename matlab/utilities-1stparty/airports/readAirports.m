function [T] = readAirports(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Set up input parser
p = inputParser;

addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-Airports' filesep 'Airports']); % Filename of ESRI shapefile of airspace classes
addOptional(p,'bbox_deg',[-Inf, -Inf; Inf, Inf],@isnumeric); % Bounding box, default is no limits
addOptional(p,'classInclude',["B","C","D"],@isstring); % Airspace classes to keep, default is all

parse(p,varargin{:});

%% Load airspace
load([getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat'],'airspace');

%% Load airports shapefile
% Convert bounding box to m_shaperead UBR format
% User-specified minimum bounding rectangle (UBR), in the format
% [minX  minY  maxX maxY]
UBR = [min(p.Results.bbox_deg(:,1)) min(p.Results.bbox_deg(:,2)) max(p.Results.bbox_deg(:,1)) max(p.Results.bbox_deg(:,2))];

% Load shapefile
S = m_shaperead(p.Results.inFile,UBR);
fprintf('LOADED: %s\n',p.Results.inFile); % Display status to screen

%%
% Parse airports
% Find column index
idxName = find(strcmpi(S.fieldnames,'name'));
idxLat = find(strcmpi(S.fieldnames,'latitude'));
idxLon = find(strcmpi(S.fieldnames,'longitude'));
idxEl = find(strcmpi(S.fieldnames,'elevation'));
idxid = find(strcmpi(S.fieldnames,'ident'));
idxICAO = find(strcmpi(S.fieldnames,'icao_id'));
idxStatus = find(strcmpi(S.fieldnames,'OPERSTATUS'));
idxPrivate = find(strcmpi(S.fieldnames,'PRIVATEUSE'));
idxMil = find(strcmpi(S.fieldnames,'MIL_CODE'));

% Parse
names = lower(string(S.dbfdata(:,idxName)));
latAirports_dms = S.dbfdata(:,idxLat);
lonAirports_dms = S.dbfdata(:,idxLon);
elevation_ft_msl = cell2mat(S.dbfdata(:,idxEl));
idFAA = upper(string(S.dbfdata(:,idxid)));
idICAO = upper(string(S.dbfdata(:,idxICAO)));
status = lower(string(S.dbfdata(:,idxStatus)));
isPrivate = cell2mat(S.dbfdata(:,idxPrivate));
milCode = lower(string(S.dbfdata(:,idxMil)));

% String split to break out each individual word
namesSplit = cellfun(@strsplit,names,'uni',false);
namesSplit = cellfun(@string,namesSplit,'UniformOutput',false);

% Parse hemisphere
lat_sense = cellfun(@(x)(x(end)),latAirports_dms,'uni',false);
lon_sense = cellfun(@(x)(x(end)),lonAirports_dms,'uni',false);

% String split degrees, minutes, seconds
latAirports_dms = cellfun(@(x)(str2double(strsplit(x(1:end-1),'-'))),latAirports_dms,'uni',false);
lonAirports_dms = cellfun(@(x)(str2double(strsplit(x(1:end-1),'-'))),lonAirports_dms,'uni',false);

% Filter out bad lat / lon
lbad = (cellfun(@numel,latAirports_dms) ~= 3) | (cellfun(@numel,lonAirports_dms) ~= 3);
names = names(~lbad);
latAirports_dms = latAirports_dms(~lbad);
lonAirports_dms = lonAirports_dms(~lbad);
elevation_ft_msl = elevation_ft_msl(~lbad);
lat_sense = lat_sense(~lbad);
lon_sense = lon_sense(~lbad);
idFAA = idFAA(~lbad);
idICAO = idICAO(~lbad);
status = status(~lbad);
isPrivate = isPrivate(~lbad);
milCode = milCode(~lbad);

% Convert to decimal degrees
latAirports_dms = cell2mat(latAirports_dms);
lonAirports_dms = cell2mat(lonAirports_dms);
if any(strcmpi(lat_sense,'S'));latAirports_dms(strcmpi(lat_sense,'S'),1) = -1* latAirports_dms(strcmpi(lat_sense,'S'),1); end
if any(strcmpi(lon_sense,'W'));lonAirports_dms(strcmpi(lon_sense,'W'),1) = -1* lonAirports_dms(strcmpi(lon_sense,'W'),1); end;
latAirports_deg = dms2degrees(latAirports_dms);
lonAirports_deg = dms2degrees(lonAirports_dms);

%% Create output table
airportClass = repmat(categorical("O"), numel(idFAA),1);
T = table(idFAA,idICAO,latAirports_deg,lonAirports_deg,elevation_ft_msl,airportClass,isPrivate,milCode,status,names,'VariableNames',{'id_FAA','id_ICAO','lat_deg','lon_deg','elevation_ft_msl','class','private_use','miltary_code','status','name'});

%% Filter Airspace
% Calculate altitude AGL extremes
airspace.minAGL_ft = cellfun(@min,airspace.LOWALT_ft_agl);
airspace.maxAGL_ft = cellfun(@min,airspace.HIGHALT_ft_agl);

% Filter airspace table based on SFC altitude
isSFC = airspace.minAGL_ft == 0;
airspace = airspace(isSFC,:);

% Create filters for individual airspace classes
isF = airspace.CLASS == 'F';
isE = airspace.CLASS == 'E';
isD = airspace.CLASS == 'D';
isC = airspace.CLASS == 'C';
isB = airspace.CLASS == 'B';

% Create aggregate logical filter
isClass = false(size(airspace,1),1);
if any(strcmpi('B',p.Results.classInclude)); isClass = isClass | isB; end;
if any(strcmpi('C',p.Results.classInclude)); isClass = isClass | isC; end;
if any(strcmpi('D',p.Results.classInclude)); isClass = isClass | isD; end;
if any(strcmpi('E',p.Results.classInclude)); isClass = isClass | isE; end;
if any(strcmpi('F',p.Results.classInclude)); isClass = isClass | isF; end;

% Filter airspace table based on class
airspace = airspace(isClass,:);
isF = isF(isClass);
isE =  isE(isClass);
isD =  isD(isClass);
isC =  isC(isClass);
isB =  isB(isClass);

%% Identify airspace
% Identify
[isInB, ~] = identifyairspace(airspace(isB,:), T.lat_deg, T.lon_deg,zeros(size(T,1),1),'agl');
[isInC, ~] = identifyairspace(airspace(isC,:), T.lat_deg, T.lon_deg,zeros(size(T,1),1),'agl');
[isInD, ~] = identifyairspace(airspace(isD,:), T.lat_deg, T.lon_deg,zeros(size(T,1),1),'agl');

% Assign
T.class(isInB) = categorical("B");
T.class(isInC) = categorical("C");
T.class(isInD) = categorical("D");

%% Sort by ICAO / FAA Ids
T = sortrows(T,{'id_ICAO','id_FAA'},{'descend','descend'});

