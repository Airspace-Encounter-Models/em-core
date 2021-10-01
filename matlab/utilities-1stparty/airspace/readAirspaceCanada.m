function [T] = readAirspaceCanada(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% Units assumed to be in feet
% Whenever it is AGL, the file indicates those. The rest is assumed to be MSL.
% Source: Email correspondance with who provided the data: Iryna Borshchova<Iryna.Borshchova@nrc-cnrc.gc.ca> 

%% Set up input parser
p = inputParser;

addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NRC-Airspace-FOUO' filesep 'March2020Airspace.mat']); % Filename of data
addOptional(p,'bbox_deg',[-Inf, -Inf; Inf, Inf],@isnumeric); % Bounding box, default is no limits
addOptional(p,'keepClasses',["B","C","D"],@isstring); % Airspace classes to keep, default is all

% Optional - Elevation related
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM3'],@isstr); % Directory containing DEM
addOptional(p,'dem','srtm3',@isstr); % Digital elevation model name
addOptional(p,'demDirBackup',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'],@isstr); % Directory containing DEM
addOptional(p,'demBackup','globe',@isstr); % Digital elevation model name

% Parse
parse(p,varargin{:});

%% Load data
data = load(p.Results.inFile,'airspace');
data = data.airspace;

%% Name / Airspace Class
NAME = string({data.name})';
CLASS = categorical({data.class})';

%% Latitude / Longitude
% Parse
LAT_deg = {data.pathLat}';
LON_deg = {data.pathLon}';

% Make sure they're column vectors
l = cellfun(@isrow,LAT_deg);
LAT_deg(l) = cellfun(@transpose,LAT_deg(l),'uni',false);
LON_deg(l) = cellfun(@transpose,LON_deg(l),'uni',false);

% Bounding box
BOUNDINGBOX_deg = cellfun(@(x,y)([min(x), min(y), max(x), max(y)]),LON_deg,LAT_deg,'uni',false);

%% Parse Altitude and Identify MSL
% Identify if altitude string has AGL in it
isAGLLow = cellfun(@any,strfind(lower({data.altLow}'),'agl'));
isAGLHigh = cellfun(@any,strfind(lower({data.altHigh}'),'agl'));

% Identify rows that are MSL for both low and high altitude
% If not AGL, assumed to be MSL
isMSL = ~isAGLLow & ~isAGLHigh;

% Preallocate
LOWER_CODE = strings(numel(data),1);
LOWALT_ft_msl = nan(numel(data),1);
HIGHALT_ft_msl = nan(numel(data),1);
LOWALT_ft_agl = cell(size(LOWALT_ft_msl));
HIGHALT_ft_agl = cell(size(HIGHALT_ft_msl));

% For rows with MSL, assign
LOWER_CODE(isMSL) = "MSL";
LOWALT_ft_msl(isMSL) = cellfun(@str2double,{data(isMSL).altLow});
HIGHALT_ft_msl(isMSL) = cellfun(@str2double,{data(isMSL).altHigh});
LOWALT_ft_msl(~isAGLLow) = cellfun(@str2double,{data(~isAGLLow).altLow});
HIGHALT_ft_msl(~isAGLHigh) = cellfun(@str2double,{data(~isAGLHigh).altHigh});

% For rows with AGL, assign
% This looks complicated, but it isn't so bad
% It removes the AGL from the altitude string and converts it to a numeric
% Then based on the # of lat / lon points, replicate the altitude into an array
LOWALT_ft_agl(isAGLLow) = arrayfun(@(x,n)(repmat(x,n,1)), cellfun(@str2double,strrep(lower({data(isAGLLow).altLow}),'agl',''))', cellfun(@numel,LAT_deg(isAGLLow)),'uni',false);
HIGHALT_ft_agl(isAGLHigh) = arrayfun(@(x,n)(repmat(x,n,1)), cellfun(@str2double,strrep(lower({data(isAGLHigh).altHigh}),'agl',''))', cellfun(@numel,LAT_deg(isAGLHigh)),'uni',false);

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
LOWALT_ft_agl = LOWALT_ft_agl(l);
HIGHALT_ft_agl = HIGHALT_ft_agl(l);
LOWER_CODE = LOWER_CODE(l);
isMSL = isMSL(l);
isAGLLow = isAGLLow(l);
isAGLHigh = isAGLHigh(l);

% Display status to screen
fprintf('Kept Airspace Class %s\n',p.Results.keepClasses)

%% Elevation

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
            [ELEVATION_ft_msl{i},~,~,~] = msl2agl(LAT_deg{i}, LON_deg{i},p.Results.dem,'demDir',p.Results.demDir,...
                'alt_ft_msl',low_ft_msl,...
                'maxMissingPercent',0.8,'isCheckOcean',true,'isFillAverage',true,'isVerbose',false);
            ELEVATION_src(i) = string(p.Results.dem);
        catch err
            warning('process:msl2agl:error','Got error when calling ms2agl, trying backup DEM\n');
            ELEVATION_ft_msl{i} = [];
        end
    end
    if isempty(ELEVATION_ft_msl{i})
        [ELEVATION_ft_msl{i},~,~,~] = msl2agl(LAT_deg{i}, LON_deg{i}, p.Results.demBackup,'demDir',p.Results.demDirBackup,...
            'alt_ft_msl',low_ft_msl,...
            'maxMissingPercent',0.8,'isCheckOcean',true,'isFillAverage',true,'isVerbose',false);
        ELEVATION_src(i) = string(p.Results.demBackup);
    end
    if isempty(ELEVATION_ft_msl{i})
        warning('el_ft_msl:empty','i = %i, el_ft_msl is empty, skipping track segement...CONTINUE\n',i);
        continue
    end
    
    % Round
    ELEVATION_ft_msl{i} = round(ELEVATION_ft_msl{i});
end
disp('CALCULATED elevation'); % Display status to screen

%% Calculate AGL and MSL altitude based on elevation
% Calculate AGL based on elevation and MSL
LOWALT_ft_agl(~isAGLLow) = cellfun(@(el,h)(h-el),ELEVATION_ft_msl(~isAGLLow), num2cell(LOWALT_ft_msl(~isAGLLow)), 'UniformOutput', false);
HIGHALT_ft_agl(~isAGLHigh) = cellfun(@(el,h)(h-el),ELEVATION_ft_msl(~isAGLHigh), num2cell(HIGHALT_ft_msl(~isAGLHigh)), 'UniformOutput', false);

% Calculate MSL based on elevation and AGL
% @TODO: This needs improvement due to the use of mean(). The FAA airspace
% file always reports in MSL and then we convert to AGL, so the output, T,
% was designed to have LOWALT_ft_msl to be double instead of a cell. The
% Canadian raw data has a different format where altitude is in either AGL or MSL, 
% so sometimes we need to estimate MSL for each lat / lon coordinate. To
% keep the formatting the same where LOWALT_ft_msl is a double, we
% calculate the mean here
LOWALT_ft_msl(isAGLLow) = cellfun(@(el,h)(mean(h+el)),ELEVATION_ft_msl(isAGLLow), LOWALT_ft_agl(isAGLLow), 'UniformOutput', true);
HIGHALT_ft_msl(isAGLHigh) = cellfun(@(el,h)(mean(h+el)),ELEVATION_ft_msl(isAGLHigh), HIGHALT_ft_agl(isAGLHigh), 'UniformOutput', true);

%% Round altitudes
% AGL
LOWALT_ft_agl = cellfun(@round,LOWALT_ft_agl,'uni',false);
HIGHALT_ft_agl = cellfun(@round,HIGHALT_ft_agl,'uni',false);

% MSL
LOWALT_ft_msl = round(LOWALT_ft_msl);
HIGHALT_ft_msl = round(HIGHALT_ft_msl);

%% Create table
T = table(NAME,CLASS,BOUNDINGBOX_deg,LAT_deg,LON_deg,LOWALT_ft_msl,HIGHALT_ft_msl,LOWALT_ft_agl,HIGHALT_ft_agl,ELEVATION_ft_msl,ELEVATION_src);
T = sortrows(T,{'CLASS','NAME'});
