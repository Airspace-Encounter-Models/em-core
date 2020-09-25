% Copyright 2018 - 2020, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
function [el_ft_msl,alt_ft_agl,Z_m,refvec] = msl2agl(lat_deg, lon_deg, dem, varargin)
% MSL2AGL converts from MSL to AGL ft for lat / lon coordinates

%% Set up input parser
p = inputParser;

% Required
addRequired(p,'lat_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'lon_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'dem',@(x) isstr(x) && any(strcmpi(x,{'dted1','dted2','globe','gtopo30','srtm1','srtm3','srtm30'})));

% Optional - If you already data
addOptional(p,'Z_m',{},@isnumeric);
addOptional(p,'refvec',{},@isnumeric);
addOptional(p,'alt_ft_msl',{},@(x) isnumeric(x) | iscell(x));

% Optional - Explicitly define DEM directory if not using defaults in em-core/data
addOptional(p,'demDir',{},@isstr);

% Optional - Loading
addOptional(p,'buff_deg',0.1,@(x) isnumeric(x) && numel(x) == 1); % Buffer to add around lat / lon lim
addOptional(p,'samplefactor',1,@(x) isnumeric(x) && numel(x) == 1); % When samplefactor is 1 (the default), reads the data at its full resolution. When samplefactor is an integer n greater than one, every nth point is read.

% Optional - ltln2val
addOptional(p,'interpMethod','bicubic',@(x) isstr(x) && any(strcmpi(x,{'bilinear','bicubic','nearest'})));% method specifies the type of interpolation used by ltln2val

% Optional - Control processing
addOptional(p,'inFileOcean',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Ocean' filesep 'ne_10m_ocean'],@ischar);
addOptional(p,'maxMissingPercent',0.8,@isnumeric); % Maximum allowable percent of missing (NaN) values in Z_m
addOptional(p,'isCheckOcean',true,@islogical); % If true, check which points are in the ocean as defined by inFileOcean
addOptional(p,'isFillAverage',true,@islogical); % If true, will attempt to replace NaN using a moving average

% Optional - Verbose
addOptional(p,'isVerbose',true,@islogical); % If true, will attempt to replace NaN using a moving average

% Parse
parse(p,lat_deg,lon_deg,dem,varargin{:});

%% Create lat / lon limits
% In experimenting with smaller bounding boxes is that below 0.05,
% you need to change the rounding level to 2 decimal places.
if p.Results.buff_deg > 0.05
    ndigits = 1;
else
    ndigits = 2;
end

% Calculate lat / lon limits
if iscell(lat_deg)
    latlim_deg = [round(min(cellfun(@min,lat_deg))-p.Results.buff_deg,ndigits), round(max(cellfun(@max,lat_deg))+p.Results.buff_deg,ndigits)];
    lonlim_deg = [round(min(cellfun(@min,lon_deg))-p.Results.buff_deg,ndigits), round(max(cellfun(@max,lon_deg))+p.Results.buff_deg,ndigits)];
else
    latlim_deg = [round(min(lat_deg)-p.Results.buff_deg,ndigits) round(max(lat_deg)+p.Results.buff_deg,ndigits)];
    lonlim_deg = [round(min(lon_deg)-p.Results.buff_deg,ndigits) round(max(lon_deg)+p.Results.buff_deg,ndigits)];
end

%% Preallocate
if iscell(lat_deg)
    el_ft_msl = cell(size(lat_deg));
    alt_ft_agl = cell(size(lat_deg));
else
    el_m_agl = nan(size(lat_deg));
    el_ft_msl = nan(size(lat_deg));
    alt_ft_agl = nan(size(lat_deg));
end

%% First check if all points are over the ocean
if ~iscell(lat_deg)
    if p.Results.isCheckOcean
        % Load ocean polygon
        % This will be used to determine which coordiantes are over the ocean
        % This is computationally efficient as we will interpolate the DEM for points over land
        ocean = shaperead(p.Results.inFileOcean,'UseGeoCoords',true);
        isOcean = InPolygon(lon_deg,lat_deg,ocean.Lon,ocean.Lat);
        el_m_agl(isOcean) = 0;
        
        % Check if all points are over the ocean
        if all(isOcean)
            % Convert to feet (ft) from meters (m)
            el_ft_msl = unitsratio('ft','m') * el_m_agl;
            
            % Calculate AGL from MSL and elevation
            if any(strcmpi(p.UsingDefaults,'alt_ft_msl'))
                alt_ft_agl = zeros(size(el_ft_msl));
            else
                alt_ft_agl = p.Results.alt_ft_msl - el_ft_msl;
            end
            
            % Set to empty
            Z_m = [];
            refvec = [];
            
            if p.Results.isVerbose; fprintf('All points over the ocean...RETURN\n'); end
            return;
        end
    end
end

%% Load DEM
if ~any(strcmpi(p.UsingDefaults,'Z_m')) & ~any(strcmpi(p.UsingDefaults,'refvec'))
    % Parse from input
    Z_m = p.Results.Z_m;
    refvec = p.Results.refvec;
else
    % Default directory to load from
    if any(strcmpi(p.UsingDefaults,'demDir'))
        switch dem
            case 'dted1'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-DTED1'];
            case 'dted2'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-DTED2'];
            case 'gtopo30'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GTOPO30'];
            case 'globe'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'];
            case 'srtm1'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM1'];
            case 'srtm3'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM3'];
            case 'srtm30'
                demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM30'];
        end
    else
        demDir = p.Results.demDir;
    end
    
    % Check to make sure DEM data exists
    % Return if it doesn't
    listing = dir([demDir filesep '**']);
    switch dem
        case 'dted1'
            % Elevations in meters
            fname = dteds(latlim_deg,lonlim_deg,1);
        case 'dted2'
            % Elevations in meters
            fname = dteds(latlim_deg,lonlim_deg,2);
        case 'gtopo30'
            fname = gtopo30s(latlim_deg,lonlim_deg);
        case 'globe'
            fname = globedems(latlim_deg,lonlim_deg);
        case 'srtm1'
            % https://dds.cr.usgs.gov/srtm/version2_1/Documentation/SRTM_Topo.pdf
            % SRTM1 (1 arc-second) is avaiable in DTED format by mail order
            fname = dteds(latlim_deg,lonlim_deg,2);
        case 'srtm3'
            % https://dds.cr.usgs.gov/srtm/version2_1/Documentation/SRTM_Topo.pdf
            % SRTM3 (3 arc-second) is avaiable in DTED format by mail order
            fname = dteds(latlim_deg,lonlim_deg,1);
        case 'srtm30'
            % https://dds.cr.usgs.gov/srtm/version2_1/SRTM30/srtm30_documentation.pdf
            % It is formatted and organized in a fashion that mimics the GTOPO30 convention so
            % software and GIS systems that work with GTOPO30 should also work with SRTM30
            fname = gtopo30s(latlim_deg,lonlim_deg);
        otherwise
            error('MSL2AGL:incorrectDEM','DEM = %s not recognized\n',dem);
    end
    
    % Check if you have any of the files
    isHasFile = cellfun(@(x)(isfile([demDir filesep x])),fname);
    if ~all(isHasFile)
        % if ~any(isHasFile)
        if p.Results.isVerbose
            warning('MSL2AGL:nodata','Missing %s for (%0.2f, %0.2f) to (%0.2f, %0.2f), only have %i/%i files...Setting output to [] and calling RETURN\n',dem,latlim_deg(1),lonlim_deg(1),latlim_deg(2),lonlim_deg(2),sum(isHasFile),numel(isHasFile));
        end
        el_ft_msl = [];
        alt_ft_agl = [];
        Z_m = [];
        refvec = [];
        return
        %end
    end
    
    % Load using built-in matlab fcns
    switch dem
        case 'dted1'
            % Elevations in meters
            [Z_m,refvec,~,~,~] = dted(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        case 'dted2'
            % Elevations in meters
            [Z_m,refvec,~,~,~] = dted(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        case 'gtopo30'
            [Z_m,refvec,~,~,~] = gtopo30(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        case 'globe'
            % Elevations are given in meters above mean sea level, using WGS 84 as a horizontal datum.
            % GLOBE tiles: https://www.ngdc.noaa.gov/mgg/topo/globeget.html
            % ESRI headers: https://www.ngdc.noaa.gov/mgg/topo/elev/esri/hdr/
            [Z_m,refvec] = globedem(demDir, p.Results.samplefactor, latlim_deg,lonlim_deg);
        case 'srtm1'
            % Elevations in meters
            [Z_m,refvec,~,~,~] = dted(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        case 'srtm3'
            % Elevations in meters
            [Z_m,refvec,~,~,~] = dted(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        case 'srtm30'
            [Z_m,refvec,~,~,~] = gtopo30(demDir, p.Results.samplefactor, latlim_deg, lonlim_deg );
        otherwise
            error('MSL2AGL:incorrectDEM','DEM = %s not recognized\n',dem);
    end
end

% Fill in grid points over the ocean (ocean shape file read-in earlier only for cell array input)
if ~iscell(lat_deg) && p.Results.isCheckOcean
    idxNaN = find(isnan(Z_m)==true);
    [lat_missing, lon_missing] = findm(isnan(Z_m),refvec);
    isOcean = InPolygon(lon_missing, lat_missing, ocean.Lon, ocean.Lat);
    Z_m(idxNaN(isOcean)) = 0;
end

%% Check we got all the needed data
% refvecToGeoRasterReference
rasterSize = size(Z_m);

% Convert to a geographic raster reference object
R = refvecToGeoRasterReference(refvec, rasterSize);

%% Check for missing elements
% Return empty arrays if there isn't enough data
% This check is useful when there is barely any data that it is better to
% just not use any of it. Users can effectively disable this behavior by
% setting maxMissingPercent = 1
idxNaN = find(isnan(Z_m)==true);
if (numel(idxNaN) / numel(Z_m)) >= p.Results.maxMissingPercent
    if p.Results.isVerbose
        warning('MSL2AGL:maxMissingPercent','%0.2f percent of Z_m has missing values\nSetting outputs to []...calling return\n',100*(numel(idxNaN) / numel(Z_m)));
    end
    el_ft_msl = [];
    alt_ft_agl = [];
    Z_m = [];
    refvec = [];
    return
end

%% Interpolate elevation and calculate AGL
if iscell(lat_deg)
    % Iterate
    parfor i=1:1:numel(lat_deg)
        % Preallocate to zero
        el_m_agl = zeros(size(lat_deg{i}));
        
        % Determine which coordinates are over the ocean
        %isOcean = InPolygon(lon_deg{i},lat_deg{i},ocean.Lon,ocean.Lat);
        
        % Interpolate to find the height at a point between grid points
        el_m_agl = ltln2val(Z_m,refvec,lat_deg{i},lon_deg{i},p.Results.interpMethod);
        
        % Convert to feet (ft) from meters (m)
        el_ft_msl{i} = unitsratio('ft','m') * el_m_agl;
        
        % Calculate AGL from MSL and elevation
        if any(strcmpi(p.UsingDefaults,'alt_ft_msl'))
            alt_ft_agl{i} = zeros(size(el_ft_msl{i}));
        else
            alt_ft_agl{i} = p.Results.alt_ft_msl - el_ft_msl{i};
        end
    end
else
    % Determine if geographic or map raster contains points
    tf = contains(R,lat_deg,lon_deg);
    if ~all(tf) & p.Results.isVerbose
        warning('MSL2AGL:tf', 'Not all points fall within the bounds of the geographic raster = %s\n', dem);
    end
    
    % Determine if any elevation is missing
    isMiss = ismissing(el_m_agl);
    
    % Interpolate to find the height at a point between grid points
    el_m_agl(isMiss) = ltln2val(Z_m,refvec,lat_deg(isMiss),lon_deg(isMiss),p.Results.interpMethod);
    
    % Determine if any elevation is missing again
    isMiss = ismissing(el_m_agl);
    
    if any(isMiss)
        % Fill remaining missing values with moving average
        if p.Results.isFillAverage
            el_m_agl = fillmissing(el_m_agl,'movmean',4);
        end
    end
    
    % Convert to feet (ft) from meters (m)
    el_ft_msl = unitsratio('ft','m') * el_m_agl;
    
    % Calculate AGL from MSL and elevation
    if any(strcmpi(p.UsingDefaults,'alt_ft_msl'))
        alt_ft_agl = zeros(size(el_ft_msl));
    else
        alt_ft_agl = p.Results.alt_ft_msl - el_ft_msl;
    end
end
