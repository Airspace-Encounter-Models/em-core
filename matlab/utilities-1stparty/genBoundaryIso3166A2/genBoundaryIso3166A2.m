function [latOut_deg,lonOut_deg] = genBoundaryIso3166A2(varargin);
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Input parser
% Create input parser
p = inputParser;

% Optional - Location of data
addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);

% Optional - Level 0 administrative boundaries to consider
% https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
% Default is roughly North America + Central America + Caribbean + Hawaii
addOptional(p,'iso_a2',{'US','CA','MX','AW','AG','BB','BS','BM','CU','CW','JM','KY','PA','PR','TC','TT'});

% Optional - Boundary Generation
addOptional(p,'mode','convhull'); % Create boundaries using convhull() or boundary() functions
addOptional(p,'shrink',0.5); % Shrink parameter for matlab boundary() function (not used by convhull)

% Optional - Hemisphere Filter
addOptional(p,'isFilterHemiN',true,@islogical); % If true, filter to have only points in the northern hemisphere
addOptional(p,'isFilterHemiW',true,@islogical); % If true, filter to have only points in the western hemisphere

% Optional - Bounds
addOptional(p,'boundsLat_deg',[-90 90]); % If true, filter to have only points in the northern hemisphere
addOptional(p,'boundsLon_deg',[-178 -30]); % If true, filter to have only points in the western hemisphere...%-178 covers Adak, the westernmost muni in the USA, but avoids issues when transitioning to eastern hemi

% Optional - Buffer
addOptional(p,'isBuffer', true); % If true, create buffer around polygons using bufferm
addOptional(p,'bufwidth_deg', nm2deg(60)); % bufdwith parameter for bufferm()

% Optional - Plot
addOptional(p,'isPlot',false,@islogical); % If true, plot boundary

% Parse
parse(p,varargin{:});

%% Load Natural Earth Adminstrative Boundaries
ne_admin = shaperead(p.Results.inFile,'UseGeoCoords',true);

%% Create filter based on ISO 3166-1 alpha-2 codes
l = contains({ne_admin.iso_a2},p.Results.iso_a2);

%% Aggregate lat / lon and compute convex hull
% Aggregate
[latMerged, lonMerged] = polymerge({ne_admin(l).Lat}',{ne_admin(l).Lon}');
[latJoin, lonJoin] = polyjoin(latMerged,lonMerged);

% Remove NaN
latJoin = latJoin(~isnan(latJoin));
lonJoin = lonJoin(~isnan(lonJoin));

%% Filter based on hemisphere
% Create filter
if p.Results.isFilterHemiN; isHemiN = latJoin >= 0; else isHemiN = true(size(lat_deg)); end
if p.Results.isFilterHemiW; isHemiW = lonJoin <= 0; else isHemiW = true(size(lon_deg)); end
isHemi = isHemiN & isHemiW;

% Filter
lat_deg = latJoin(isHemi);
lon_deg = lonJoin(isHemi);

%% Filter Bounds
isBLat = lat_deg >= p.Results.boundsLat_deg(1) & lat_deg <= p.Results.boundsLat_deg(2);
isBLon = lon_deg >= p.Results.boundsLon_deg(1) & lon_deg <= p.Results.boundsLon_deg(2);
isInBound = isBLat & isBLon;

% Filter
lat_deg = lat_deg(isInBound);
lon_deg = lon_deg(isInBound);

%% Buffer (if desired)
if p.Results.isBuffer
    kb = boundary(lat_deg,lon_deg,p.Results.shrink);
    [latb,lonb] = bufferm(lat_deg(kb),lon_deg(kb),p.Results.bufwidth_deg,'out');
    lat_deg = latb;
    lon_deg = lonb;
end

%% Remove NaN
lat_deg = lat_deg(~isnan(lat_deg));
lon_deg = lon_deg(~isnan(lon_deg));

%% Calculate Boundary
switch p.Results.mode
    case 'boundary'
        k = boundary(lon_deg,lat_deg,p.Results.shrink);
    case 'convhull'
        k = convhull(lon_deg,lat_deg);
end

%% Finish output
latOut_deg = lat_deg(k);
lonOut_deg = lon_deg(k);

% Close polygon and add trailing nan
latOut_deg = [latOut_deg; latOut_deg(1); nan];
lonOut_deg = [lonOut_deg; lonOut_deg(1); nan];

%% Plot
if p.Results.isPlot
    figure; set(gcf,'name','Iso3166-1 A2 Polygon');
    geoplot(latOut_deg,lonOut_deg,'.');
end
