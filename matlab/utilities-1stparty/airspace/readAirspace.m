function [T] = readAirspace(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Set up input parser
p = inputParser;

addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-NASR' filesep 'Class_Airspace']); % Filename of ESRI shapefile of airspace classes
addOptional(p,'bbox_deg',[-Inf, -Inf; Inf, Inf],@isnumeric); % Bounding box, default is no limits
addOptional(p,'keepClasses',["B","C","D"],@isstring); % Airspace classes to keep, default is all

% Optional - Elevation related
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM3'],@isstr); % Directory containing DEM
addOptional(p,'dem','srtm3',@isstr); % Digital elevation model name
addOptional(p,'demDirBackup',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'],@isstr); % Directory containing DEM
addOptional(p,'demBackup','globe',@isstr); % Digital elevation model name

parse(p,varargin{:});

%% Load shapefile
% Convert bounding box to m_shaperead UBR format
% User-specified minimum bounding rectangle (UBR), in the format
% [minX  minY  maxX maxY]
UBR = [min(p.Results.bbox_deg(:,1)) min(p.Results.bbox_deg(:,2)) max(p.Results.bbox_deg(:,1)) max(p.Results.bbox_deg(:,2))];

% Load shapefile
S = m_shaperead(p.Results.inFile,UBR);
fprintf('LOADED: %s\n',p.Results.inFile); % Display status to screen

%% Find column indicies
% Name / class
colName = find(strcmpi(S.fieldnames,'name'),1,'first');
colClass = find(strcmpi(S.fieldnames,'class'),1,'first');

% Altitude
colAltLower = find(strcmpi(S.fieldnames,'LOWER_VAL'),1,'first');
colAltUpper = find(strcmpi(S.fieldnames,'UPPER_VAL'),1,'first');

colUnitLower = find(strcmpi(S.fieldnames,'LOWER_UOM'),1,'first');
colUnitUpper = find(strcmpi(S.fieldnames,'UPPER_UOM'),1,'first');

% Find index to lower code that determines if msl or sfc
colLowerCode = find(strcmpi(S.fieldnames,'LOWER_CODE'),1,'first');

%% Name / Airspace Class
% Find column indices
% Parse raw variables and convert from raw char
NAME = string(S.dbfdata(:,colName));
CLASS = categorical(S.dbfdata(:,colClass));

%% Latitude / Longitude
BOUNDINGBOX_deg = mat2cell(S.mbr(:,1:4),ones(size(S.mbr,1),1),size(S.mbr,2)-2);
LAT_deg = cellfun(@(x)(x(:,2)),S.ncst,'uni',false);
LON_deg = cellfun(@(x)(x(:,1)),S.ncst,'uni',false);

% Make sure they're column vectors
l = cellfun(@isrow,LAT_deg);
LAT_deg(l) = cellfun(@transpose,LAT_deg(l),'uni',false);
LON_deg(l) = cellfun(@transpose,LON_deg(l),'uni',false);

%% Altitude
% Convert altitude strings to doubles
LOWALT_ft_msl = cellfun(@str2double,S.dbfdata(:,colAltLower));
HIGHALT_ft_msl = cellfun(@str2double,S.dbfdata(:,colAltUpper));

% Correct for high alitude
HIGHALT_ft_msl(HIGHALT_ft_msl < 0) = 6e4;

% Ensure altitude is in feet
% The units should already be feet, so unitConvert should be 1
% Included to help future proof code
unitConvert = cellfun(@(x)(unitsratio('ft',x)),S.dbfdata(:,colUnitLower));
LOWALT_ft_msl = LOWALT_ft_msl .* unitConvert;
HIGHALT_ft_msl = HIGHALT_ft_msl .* unitConvert;

% Lower altitude code (MSL, SFC)
LOWER_CODE = string(S.dbfdata(:,colLowerCode));

%% Filter airspaces using keepClasses parameter
% Note default behavior will filter nothing out

% Create logical index of airspace classes we want to keep
expression = sprintf('CLASS == ''%s'' |',p.Results.keepClasses);
expression = expression(1:end-1); % Remove trailing |
l = eval(expression);

% Filter
NAME = NAME(l);
CLASS = CLASS(l);
BOUNDINGBOX_deg = BOUNDINGBOX_deg(l);
LAT_deg = LAT_deg(l);
LON_deg = LON_deg(l);
LOWALT_ft_msl = LOWALT_ft_msl(l);
HIGHALT_ft_msl = HIGHALT_ft_msl(l);
LOWER_CODE = LOWER_CODE(l);

% Display status to screen
fprintf('Kept Airspace Class %s\n',p.Results.keepClasses)

%% Elevation and AGL ft
% Preallocate
LOWALT_ft_agl = cell(size(LOWALT_ft_msl));
HIGHALT_ft_agl = cell(size(HIGHALT_ft_msl));
ELEVATION_ft_msl = cell(size(HIGHALT_ft_msl));
ELEVATION_src = strings(size(HIGHALT_ft_msl));

% Iterate
parfor i=1:1:numel(LAT_deg)
    % Parse floor
    low_ft_msl = repmat(LOWALT_ft_msl(i), size(LAT_deg{i}));
    
    % Get floor ft AGL and elevation
    % In dted():
    % If a directory name is supplied instead of a file name and LATLIM
    % spans either 50 degrees North or 50 degrees South, an error results.
    if contains(p.Results.dem,{'srtm','dted'}) & (min(LAT_deg{i}) < -50 && max(LAT_deg{i}) > -50) || (min(LAT_deg{i}) < 50 && max(LAT_deg{i}) > 50)
        warning('process:dted:latlimSpans50','DEMs in the DTED format will throw an error if the latitude limit spans either 50 degrees North or 50 degrees South, trying backup DEM\n');
        el_ft_msl = [];
    else
        try
            [ELEVATION_ft_msl{i},LOWALT_ft_agl{i},~,~] = msl2agl(LAT_deg{i}, LON_deg{i},p.Results.dem,'demDir',p.Results.demDir,...
                'alt_ft_msl',low_ft_msl,...
                'maxMissingPercent',0.8,'isCheckOcean',true,'isFillAverage',true,'isVerbose',false);
            ELEVATION_src(i) = string(p.Results.dem);
        catch err
            warning('process:msl2agl:error','Got error when calling ms2agl, trying backup DEM\n');
            ELEVATION_ft_msl{i} = [];
        end
    end
    if isempty(ELEVATION_ft_msl{i})
        [ELEVATION_ft_msl{i},LOWALT_ft_agl{i},~,~] = msl2agl(LAT_deg{i}, LON_deg{i}, p.Results.demBackup,'demDir',p.Results.demDirBackup,...
            'alt_ft_msl',low_ft_msl,...
            'maxMissingPercent',0.8,'isCheckOcean',true,'isFillAverage',true,'isVerbose',false);
        ELEVATION_src(i) = string(p.Results.demBackup);
    end
    if isempty(ELEVATION_ft_msl{i})
        warning('el_ft_msl:empty','i = %i, el_ft_msl is empty, skipping track segement...CONTINUE\n',i);
        continue
    end
    
    % Correct for SFC lower altitudes
    if strcmpi(LOWER_CODE{i},'SFC')
        LOWALT_ft_agl{i} = low_ft_msl;
    else
        isGround = low_ft_msl == 0;
        LOWALT_ft_agl{i}(isGround) = 0;
    end
    
    % Round
    ELEVATION_ft_msl{i} = round(ELEVATION_ft_msl{i});
    LOWALT_ft_agl{i} = round(LOWALT_ft_agl{i});
    
    % Calculate airspace ceil
    HIGHALT_ft_agl{i} = repmat(HIGHALT_ft_msl(i), size(LAT_deg{i}))- ELEVATION_ft_msl{i};
    %disp(i);
end
disp('CALCULATED elevation'); % Display status to screen

%% Create table
T = table(NAME,CLASS,BOUNDINGBOX_deg,LAT_deg,LON_deg,LOWALT_ft_msl,HIGHALT_ft_msl,LOWALT_ft_agl,HIGHALT_ft_agl,ELEVATION_ft_msl,ELEVATION_src);
T = sortrows(T,{'CLASS','NAME'});
