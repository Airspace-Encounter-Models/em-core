function [T] = readAirspace(filename,varargin)

%% Set up input parser
p = inputParser;
%validationFcn =  @(x) isnumeric(x) | iscell(x);
addRequired(p,'filename',@ischar); % Filename of ESRI shapefile of airspace classes
addOptional(p,'bbox_deg',[-Inf, -Inf; Inf, Inf],@isnumeric); % Bounding box, default is no limits
addOptional(p,'keepClasses',["B","C","D","E"],@isstring); % Airspace classes to keep, default is all
addOptional(p,'dem1','srtm30',@isstr); % First DEM to try with msgl2agl
addOptional(p,'dem2','globe',@isstr); % Second DEM to try with msgl2agl

parse(p,filename,varargin{:});

%% Load shapefile
% Convert bounding box to m_shaperead UBR format
% User-specified minimum bounding rectangle (UBR), in the format
% [minX  minY  maxX maxY]
UBR = [min(p.Results.bbox_deg(:,1)) min(p.Results.bbox_deg(:,2)) max(p.Results.bbox_deg(:,1)) max(p.Results.bbox_deg(:,2))];

% Load shapefile
S = m_shaperead(p.Results.filename,UBR);
fprintf('LOADED: %s\n',filename); % Display status to screen

%% Find column indicies

% Name / class
colName = find(strcmpi(S.fieldnames,'name')==true,1,'first');
colClass = find(strcmpi(S.fieldnames,'class')==true,1,'first');

% Altitude
colAltLower = find(strcmpi(S.fieldnames,'LOWER_VAL')==true,1,'first');
colAltUpper = find(strcmpi(S.fieldnames,'UPPER_VAL')==true,1,'first');

colUnitLower = find(strcmpi(S.fieldnames,'LOWER_UOM')==true,1,'first');
colUnitUpper = find(strcmpi(S.fieldnames,'UPPER_UOM')==true,1,'first');

%% Name / Airspace Class
% Find column indices

% Parse raw variables and convert from raw char
NAME = string(S.dbfdata(:,colName));
CLASS = categorical(S.dbfdata(:,colClass));

%% Latitude / Longitude
BOUNDINGBOX_deg = mat2cell(S.mbr(:,1:4),ones(size(S.mbr,1),1),size(S.mbr,2)-2);
LAT_deg = cellfun(@(x)(x(:,2)),S.ncst,'uni',false);
LON_deg = cellfun(@(x)(x(:,1)),S.ncst,'uni',false);

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
    try
        [ELEVATION_ft_msl{i},LOWALT_ft_agl{i}] = msl2agl(LAT_deg{i}, LON_deg{i}, p.Results.dem1,'alt_ft_msl',low_ft_msl);
        ELEVATION_src(i) = string(p.Results.dem1);
    catch
        [ELEVATION_ft_msl{i},LOWALT_ft_agl{i}] = msl2agl(LAT_deg{i}, LON_deg{i}, p.Results.dem2, 'alt_ft_msl',low_ft_msl);
        ELEVATION_src(i) =  string(p.Results.dem2);
    end
    
    % Correct for SFC lower altitudes
    isSFC = low_ft_msl == 0;
    LOWALT_ft_agl{i}(isSFC) = 0;
    
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
