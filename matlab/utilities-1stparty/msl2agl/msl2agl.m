function [el_ft_msl,alt_ft_agl,Z_m,refvec, R] = msl2agl(lat_deg, lon_deg, dem, varargin)
% MSL2AGL converts from MSL to AGL ft for lat / lon coordinates
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Set up input parser
p = inputParser;

% Required
addRequired(p,'lat_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'lon_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'dem',@(x) ischar(x) && any(strcmpi(x,{'dted1','dted2','globe','gtopo30','srtm1','srtm3','srtm30'})));

% Optional - If you already data
addParameter(p,'Z_m',{},@isnumeric);
addParameter(p,'refvec',{},@isnumeric);
addParameter(p,'R',map.rasterref.GeographicCellsReference.empty(0,1), @(x)(isa(x,'map.rasterref.GeographicCellsReference') | isa(x,'map.rasterref.GeographicPostingsReference')));

addParameter(p,'alt_ft_msl',{},@(x) isnumeric(x) | iscell(x));
addParameter(p,'ocean',struct,@isstruct);

% Optional - Explicitly define DEM directory if not using defaults in em-core/data
addParameter(p,'demDir',char.empty(0,0),@ischar);

% Optional - Loading
addParameter(p,'buff_deg',0.1,@(x) isnumeric(x) && numel(x) == 1); % Buffer to add around lat / lon lim
addParameter(p,'samplefactor',1,@(x) isnumeric(x) && numel(x) == 1); % When samplefactor is 1 (the default), reads the data at its full resolution. When samplefactor is an integer n greater than one, every nth point is read.

% Optional - geointerp
addParameter(p,'interpMethod','linear',@(x) ischar(x) && any(strcmpi(x,{'nearest','linear','cubic','spline'})));% method specifies the type of interpolation used by geointerp

% Optional - Control processing
addParameter(p,'inFileOcean',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Ocean' filesep 'ne_10m_ocean'],@ischar);
addParameter(p,'maxMissingPercent',0.8,@isnumeric); % Maximum allowable percent of missing (NaN) values in Z_m
addParameter(p,'isCheckOcean',true,@islogical); % If true, check which points are in the ocean as defined by inFileOcean
addParameter(p,'isFillAverage',true,@islogical); % If true, will attempt to replace NaN using a moving average

% Optional - Verbose
addParameter(p,'isVerbose',true,@islogical); % If true, will attempt to replace NaN using a moving average

% Parse
parse(p,lat_deg,lon_deg,dem,varargin{:});
R = p.Results.R;
interpMethod = p.Results.interpMethod;

%% Inputs hardcode
m2ft =  3.28083989501312;

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
        if ~any(strcmpi(p.UsingDefaults,'ocean'))
            ocean = p.Results.ocean;
        else
            ocean = shaperead(p.Results.inFileOcean,'UseGeoCoords',true);
        end
        
        % This will be used to determine which coordiantes are over the ocean
        % This is computationally efficient as we will interpolate the DEM for points over land
        isOcean = InPolygon(lon_deg,lat_deg,ocean.Lon,ocean.Lat);
        el_m_agl(isOcean) = 0;
        
        % Check if all points are over the ocean
        if all(isOcean)
            % Convert to feet (ft) from meters (m)
            el_ft_msl = m2ft * el_m_agl;
            
            % Calculate AGL from MSL and elevation
            if any(strcmpi(p.UsingDefaults,'alt_ft_msl'))
                alt_ft_agl = zeros(size(el_ft_msl));
            else
                alt_ft_agl = p.Results.alt_ft_msl - el_ft_msl;
            end
            
            % Set to empty
            Z_m = double.empty(0,0);
            refvec = double.empty(0,3);
            R = map.rasterref.GeographicCellsReference.empty(0,1);
            
            if p.Results.isVerbose; fprintf('All points over the ocean...RETURN\n'); end
            return;
        end
    end
end

%% Load DEM
if ~any(strcmpi(p.UsingDefaults,'Z_m'))
    % Parse from input
    Z_m = p.Results.Z_m;
    refvec = p.Results.refvec;
    R = p.Results.R;
else
    % Default directory to load from
    if isempty(p.Results.demDir)
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
            % SRTM1 (1 arc-second) is avaiable in DTED format by mail order
            fname = dteds(latlim_deg,lonlim_deg,2);
        case 'srtm3'
            % SRTM3 (3 arc-second) is avaiable in DTED format by mail order
            fname = dteds(latlim_deg,lonlim_deg,1);
        case 'srtm30'
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
            warning('MSL2AGL:nodata','Missing %s for (%0.2f, %0.2f) to (%0.2f, %0.2f), only have %i/%i files...Setting output to [] and calling RETURN',dem,latlim_deg(1),lonlim_deg(1),latlim_deg(2),lonlim_deg(2),sum(isHasFile),numel(isHasFile));
        end
        el_ft_msl = double.empty(0,0);
        alt_ft_agl = double.empty(0,0);
        Z_m = double.empty(0,0);
        refvec = double.empty(0,3);
        R = map.rasterref.GeographicCellsReference.empty(0,1);
        return
    end
    
    % Load using built-in matlab fcns
    if numel(fname) == 1
        inFile = [demDir filesep fname{1}];
        info = georasterinfo(inFile);
        scalefactor = p.Results.samplefactor;
        samplefactor = p.Results.samplefactor;
        refvec = double.empty(0,3);
        
        switch dem
            case 'dted1'
                % Elevations in meters
                [Z_m,R] = readgeoraster(inFile);
                [Z_m,R] = geocrop(Z_m,R,latlim_deg,lonlim_deg);
                [Z_m,R] = georesize(Z_m,R,1/samplefactor);
                
            case 'dted2'
                % Elevations in meters
                [Z_m,R] = readgeoraster(inFile);
                [Z_m,R] = geocrop(Z_m,R,latlim_deg,lonlim_deg);
                [Z_m,R] = georesize(Z_m,R,1/samplefactor);
                
            case 'globe'
                % Elevations are given in meters above mean sea level, using WGS 84 as a horizontal datum.
                % GLOBE tiles: https://www.ngdc.noaa.gov/mgg/topo/globeget.html
                % ESRI headers: https://www.ngdc.noaa.gov/mgg/topo/elev/esri/hdr/
                [Z_m,R] = readgeoraster(inFile,'CoordinateSystemType','geographic');
                [Z_m,R] = geocrop(Z_m,R,latlim_deg,lonlim_deg);
                [Z_m,R] = georesize(Z_m,R,1/scalefactor);
                
            case 'srtm1'
                [Z_m,R] = readgeoraster(inFile);
                [Z_m,R] = geocrop(Z_m,R,latlim_deg,lonlim_deg);
                [Z_m,R] = georesize(Z_m,R,1/samplefactor);
            case 'srtm3'
                [Z_m,R] = readgeoraster(inFile);
                [Z_m,R] = geocrop(Z_m,R,latlim_deg,lonlim_deg);
                [Z_m,R] = georesize(Z_m,R,1/samplefactor);
        end
        
        % Cast to double for backwards compability
        Z_m = double(Z_m);
        
        % Replace the missing data with NaN values using the standardizeMissing function.
        m = info.MissingDataIndicator;
        if ismember(m,Z_m); Z_m = standardizeMissing(Z_m,m); end
        
    else
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
end

%% Convert to a geographic raster reference object
if isempty(R)
    % refvecToGeoRasterReference
    rasterSize = size(Z_m);
    
    % Convert to a geographic raster reference object
    R = refvecToGeoRasterReference(refvec, rasterSize);
end

%% Fill in grid points over the ocean (ocean shape file read-in earlier only for cell array input)
if ~iscell(lat_deg) && p.Results.isCheckOcean
    idxNaN = find(isnan(Z_m)==true);
    [lat_missing, lon_missing] = findm(isnan(Z_m),R);
    if ~isempty(lat_missing)
        isOcean = InPolygon(lon_missing, lat_missing, ocean.Lon, ocean.Lat);
        Z_m(idxNaN(isOcean)) = 0;
    end
end

%% Check for missing elements
% Return empty arrays if there isn't enough data
% This check is useful when there is barely any data that it is better to
% just not use any of it. Users can effectively disable this behavior by
% setting maxMissingPercent = 1
isMiss = ismissing(Z_m,nan);

if any(isMiss,'all')
    
    % Fill remaining missing values with moving average
    if p.Results.isFillAverage
        c = 0;
        while any(ismissing(Z_m,nan),'all') && c<10
            Z_m = fillmissing(Z_m,'movmean',4,'EndValues','nearest');
            c = c + 1;
        end
    end
    
    idxNaN = find(ismissing(Z_m,nan));
    if (nnz(idxNaN) / numel(Z_m)) >= p.Results.maxMissingPercent
        if p.Results.isVerbose
            warning('MSL2AGL:maxMissingPercent','%0.2f percent of Z_m has missing values\nSetting outputs to []...calling return\n',100*(numel(idxNaN) / numel(Z_m)));
        end
        el_ft_msl = [];
        alt_ft_agl = [];
        Z_m = double.empty(0,0);
        refvec = double.empty(0,3);
        R = map.rasterref.GeographicCellsReference.empty(0,1);
        return
    end
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
        el_m_agl = geointerp(Z_m,R,lat_deg{i},lon_deg{i},interpMethod);
        
        % Convert to feet (ft) from meters (m)
        el_ft_msl{i} = m2ft * el_m_agl;
        
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
    if ~all(tf) && p.Results.isVerbose
        warning('MSL2AGL:tf', 'Not all points fall within the bounds of the geographic raster = %s\n', dem);
    end
    
    % Interpolate to find the height at a point between grid points
    % Previously used ltln2val() but MATLAB will be removing ltln2val() in the future
    % el_m_agl(isMiss) = ltln2val(Z_m,refvec,lat_deg(isMiss),lon_deg(isMiss),interpMethod);
    el_m_agl= geointerp(Z_m,R,lat_deg,lon_deg,interpMethod);
    
    % Convert to feet (ft) from meters (m)
    el_ft_msl = m2ft * el_m_agl;
    
    % Calculate AGL from MSL and elevation
    if any(strcmpi(p.UsingDefaults,'alt_ft_msl'))
        alt_ft_agl = zeros(size(el_ft_msl));
    else
        alt_ft_agl = p.Results.alt_ft_msl - el_ft_msl;
    end
end
