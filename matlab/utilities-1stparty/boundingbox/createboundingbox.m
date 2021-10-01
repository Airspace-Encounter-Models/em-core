function [BoundingBox_wgs84, BoundingBox_map] = createboundingbox(lat0_deg,lon0_deg,rad_nm,mstruct)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

% A small circle is the locus of all points an equal surface distance from a given center.
% Using an empty azimuth entry to indicate a full circle
[latc,lonc] = scircle1(lat0_deg,lon0_deg,rad_nm,[],wgs84Ellipsoid('nm'));

% Calculate limits
latmin = min(latc);
latmax = max(latc);
lonmin = min(lonc);
lonmax = max(lonc);

% Aggregate limits into WGS84 Bounding Box
BoundingBox_wgs84 = [lonmin,latmin;lonmax,latmax];

% Transform to Bounding Box in map coordinates, such as NAD83
% mfwdtran Project geographic features to map coordinates
if nargin > 3
    [x,y] = mfwdtran(mstruct,BoundingBox_wgs84(:,2),BoundingBox_wgs84(:,1));
    BoundingBox_map = [x,y];
else
    BoundingBox_map = [];
end

% https://gis.stackexchange.com/a/142327/45077 
% DEPCRATED
% Distance between latitudes are effectively constant
% latlen_nm = mean([68.703, 69.407 ]); % 1 degree
% latRadius_deg = centerRadius_nm / latlen_nm;
% latmin = centerLat_deg - latRadius_deg;
% latmax = centerLat_deg + latRadius_deg;
% 
% % Scale longitude 
% lonlen_nm = cosd(centerLat_deg) * latlen_nm;
% lonRadius_deg = latRadius_deg * latlen_nm / lonlen_nm;
% lonmin = centerLon_deg - lonRadius_deg;
% lonmax = centerLon_deg + lonRadius_deg;
