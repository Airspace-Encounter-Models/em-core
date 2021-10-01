function [outLat_deg, outLon_deg, inBox] = filterboundingbox(inLat_deg,inLon_deg,BoundingBox)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%
% Bounding box, specified as the comma-separated pair consisting of 'BoundingBox' and a 2-by-2 matrix. BoundingBox has the form [xmin,ymin;xmax,ymax], for map coordinates, or [lonmin,latmin;lonmax,latmax] for geographic coordinates. 

% Create complete bounding box polygon
latlim = BoundingBox(:,2);
lonlim = BoundingBox(:,1);

bboxlat = [latlim(1) latlim(1) latlim(2) latlim(2) latlim(1)];
bboxlon = [lonlim(1) lonlim(2) lonlim(2) lonlim(1) lonlim(1)];

% Determine if any points are within bounding box
if iscell(inLon_deg)
    inBox = cellfun(@(x,y)(any(InPolygon(x,y,bboxlon,bboxlat))),inLon_deg,inLat_deg);
else
    inBox = InPolygon(inLon_deg,inLat_deg,bboxlon,bboxlat);
end

% Only do something in some points are in the bounding box
if any(inBox)     
    % Filter input coordiantes to those only in bbox
    inLat_deg = inLat_deg(inBox);
    inLon_deg = inLon_deg(inBox);
    
    % Filter within cell
    if iscell(inLon_deg)
        % Determine which filtered points are within bounding box
        l = cellfun(@(x,y)(InPolygon(x,y,bboxlon,bboxlat)),inLon_deg,inLat_deg,'uni',false);
        
        % Filter coordinates using logical indices
        outLat_deg = cellfun(@(x,l)(x(l)),inLat_deg,l,'uni',false);
        outLon_deg = cellfun(@(x,l)(x(l)),inLon_deg,l,'uni',false);
    else
        % Not cell, so the inBox filter is all we need
        outLat_deg = inLat_deg;
        outLon_deg = inLon_deg;
    end
else
    outLat_deg = [];
    outLon_deg = [];
end

% Plotting for debugging
%[latjoin,lonjoin] = polyjoin(outLat_deg,outLon_deg);
%geoshow(latjoin,lonjoin,'Marker','*');

% There are rare edge cases where a vector is connected and the "middle"
% portion of the vector is outside the bounding box but the first & last
% are within the bounding  box. This bug was discovered with DHS HIFLD
% electric power lines near Reno, NV and prompt a switch to logical
% indexing
% Calculate first and last indicies within bounding box
%idxFirst = cellfun(@(l)(find(l==true,1,'first')),l,'uni',false);
%idxLast = cellfun(@(l)(find(l==true,1,'last')),l,'uni',false);

% Filter coordinates using indices
%outLat_deg= cellfun(@(x,s,e)(x(s:e)),inLat_deg,idxFirst,idxLast,'uni',false);
%outLon_deg = cellfun(@(x,s,e)(x(s:e)),inLon_deg,idxFirst,idxLast,'uni',false);
