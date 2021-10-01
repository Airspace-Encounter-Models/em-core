function [isInAirspace, airspaceNames] = identifyairspace(airspace, LAT_deg,LON_deg,ALT_ft,ALT_unit)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% CALCINAIRSPACE returns true if coordinates are within airspace
%   airspace = table generated using RUN_AIRSPACE_1
%   LAT_deg = latitude in decimal degrees
%   LON_deg = longitude in decimal degrees
%   ALT_ft = altitude in feet
%   ALT_unit = altitude reference, either agl or msl
%
%   NOTE: Make sure InPolygon has been mexed
%
%   See also RUN_AIRSPACE_1, m_shapereadAirspace.

%% Get ready
% Number of coordinates to evaluate
N = size(LON_deg,1);

% Preallocate output
isInAirspace = false(N,1);
airspaceNames = strings(N,1);

% Things that should be input parsers
isDisplay = false; % If true, display status to screen

%% Catch if airspace is empty
if isempty(airspace)
   if isDisplay
       fprintf('Airspace is empty, exiting identifyairspace() via RETURN\n');
   end
   return;
end

%% Calculate limits and filter airspaces
%Limits of input LAT_deg, LON_deg
if iscell(LON_deg)
    lonmin = min(cellfun(@min,LON_deg));
    lonmax = max(cellfun(@max,LON_deg));
    latmin = min(cellfun(@min,LAT_deg));
    latmax = max(cellfun(@max,LAT_deg));
else
    lonmin = min(LON_deg);
    lonmax = max(LON_deg);
    latmin = min(LAT_deg);
    latmax = max(LAT_deg);
end

BoundingBox = [lonmin,latmin;lonmax,latmax];
[~, ~, inAirspace] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,BoundingBox);

% % Filter airspace
airspace = airspace(inAirspace,:);

% Return if airspace is empty after filtering
if isempty(airspace)
    return;
end

%% Check altitude
if nargin > 3
    switch lower(ALT_unit)
        case 'agl'
            zlv = cellfun(@min,airspace.LOWALT_ft_agl);
            zhv = cellfun(@max,airspace.HIGHALT_ft_agl);
        case 'msl'
            zlv = airspace.LOWALT_ft_msl;
            zhv = airspace.HIGHALT_ft_msl;
        otherwise
            error('CalcInAirspace:ALT_unit', 'ALT_unit must either be ''agl'' or ''msl''');
    end
    
    % For the rare case when altitude is negative
    % RUN_AIRSPACE_1 sets SFC to 0, so we need to set SFC also to 0
    isSFC = ALT_ft <= 0;
    ALT_ft(isSFC) = 0;
    
    isInAlt = arrayfun(@(z)( z >= zlv & z <= zhv ), ALT_ft,'uni',false);
else
    % If altitude not specify, set altitude valid for all airspaces
    l = true(size(airspace,1),1);
    isInAlt = repmat({l},N,1);
end

%% Parse out airspace latitude and longitude for efficiency 
airLat_deg = airspace.LAT_deg;
airLon_deg = airspace.LON_deg;
airName = airspace.NAME;

%% Check horizontally
% Iterate over coordinates
for i=1:1:N
    % Parse ith coordinates
    x = LON_deg(i);
    y = LAT_deg(i);
    
    jIn = false(size(airLat_deg,1),1);
    
    % Iterate over airspaces
    for j=1:1:size(airLat_deg,1)
        % Check if within altitude bounds
        if isInAlt{i}(j)
            % Parse jth airspace
            xv = airLon_deg{j}; yv = airLat_deg{j};
            
            % if InPolygon, set true and break j for loop
            jIn(j) = InPolygon(x,y,xv,yv);
            if any(jIn(j))
                airspaceNames(i) = airName{j};
                isInAirspace(i) = true;
                break;
            end % End if
        end % End if
    end % End j loop
    isInAirspace(i) = any(jIn);
    % Display status
    if isDisplay
        if (mod(i,1e3)==0); fprintf('%i / %i\n',i, N); end
    end
end % End i loop

