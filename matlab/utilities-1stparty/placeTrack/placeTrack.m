function [Tout] = placeTrack(inData,lat0_deg,lon0_deg,varargin)
% Copyright 2019 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%
% SEE ALSO msl2agl ned2geodetic

%% Set up input parser
p = inputParser;

% Required
addRequired(p,'inData');
addRequired(p,'lat0_deg',@(x) isnumeric(x) && numel(x) == 1);
addRequired(p,'lon0_deg',@(x) isnumeric(x) && numel(x) == 1);

% Optional - inData parsing
addParameter(p,'labelTime','time_s');
addParameter(p,'labelX','x_ft');
addParameter(p,'labelY','y_ft');
addParameter(p,'labelZ','z_ft');
addParameter(p,'Delimiter',','); % Delimiter if inData is a file

% Optional
addParameter(p,'spheroid',wgs84Ellipsoid('ft'));
addParameter(p,'z_units','agl',@(x) ischar(x) && any(strcmpi(x,{'agl','msl'})));
addParameter(p,'z_agl_tol_ft',200,@isnumeric);
addParameter(p,'maxTries',3,@(x) isnumeric(x) && numel(x) == 1);
addParameter(p,'seed',nan,@isnumeric);

% Optional - DEM
addParameter(p,'dem','globe',@ischar);
addParameter(p,'Z_m',[],@isnumeric);
addParameter(p,'refvec',[],@isnumeric);
addParameter(p,'R',map.rasterref.GeographicCellsReference.empty(0,1), @(x)(isa(x,'map.rasterref.GeographicCellsReference') | isa(x,'map.rasterref.GeographicPostingsReference')));

% Optional - Obstacles
addParameter(p,'latObstacle',[],@isnumeric);
addParameter(p,'lonObstacle',[],@isnumeric);
addParameter(p,'altObstacle_ft_agl',[],@isnumeric);

% Optional Plot
addParameter(p,'isPlot',false,@islogical);

% Parse
parse(p,inData,lat0_deg,lon0_deg,varargin{:});
spheroid_ft = p.Results.spheroid;
z_agl_tol_ft = p.Results.z_agl_tol_ft;
seed = p.Results.seed;

%% Set random seed
if ~isnan(seed) && ~isempty(seed)
    oldSeed = rng;
    rng(seed,'twister');
end

%% Load trajectory
switch class(inData)
    case 'char'
        Tin = readtable(inData,'Delimiter',p.Results.Delimiter);
    case 'struct'
        Tin = inData;
    case 'table'
        Tin = inData;
    case 'timetable'
        Tin = inData;
    otherwise
        error('placeTrack:inData','First argument must be a char, struct, table, or timetable. It was a %s',class(inData));
end

% Preallocate output
Tout = Tin;

%% Parse track
time_s = Tin.(p.Results.labelTime);
x_ft = Tin.(p.Results.labelX);
y_ft = Tin.(p.Results.labelY);
z_ft = Tin.(p.Results.labelZ);

nPoints = numel(time_s);

%% Get DEM Z_m and refvec
if isempty(p.Results.Z_m) || any(strcmpi(p.UsingDefaults,'Z_m'))  || any(strcmpi(p.UsingDefaults,'R'))
    spanX_ft = abs(max(x_ft) - min(x_ft));
    spanY_ft = abs(max(y_ft) - min(y_ft));
    [latc, lonc] = scircle1(lat0_deg,lon0_deg,max([spanX_ft spanY_ft]), [],spheroid_ft);
    dem = p.Results.dem;
    [el0_ft_msl,~,Z_m,refvec,R] = msl2agl([lat0_deg; min(latc); max(latc)], [lon0_deg; min(lonc); max(lonc)],dem,'isCheckOcean',true);
    el0_ft_msl = el0_ft_msl(1);  % Get MSL elevation of (lat0_deg,lon0_deg)
else
    dem = p.Results.dem;
    Z_m = p.Results.Z_m;
    refvec = p.Results.refvec;
    R = p.Results.R;
    [el0_ft_msl,~,~,~] = msl2agl(lat0_deg, lon0_deg,dem,'Z_m',Z_m,'refvec',refvec,'R',R,'isCheckOcean',false);
end

%% Filter and parse out obstacles
l = p.Results.altObstacle_ft_agl >= min(z_ft);
latObstacle = p.Results.latObstacle(:,l);
lonObstacle = p.Results.lonObstacle(:,l);
altObstacle_ft_agl = p.Results.altObstacle_ft_agl(l);
numObstacle = size(latObstacle,2);

%% Translate and rotate trajectories
% Preallocate counters
c = 1;
nValidPoints = 0;
idx = 1:1:numel(time_s);

% Preallocate index and rotation
i0s = randi(numel(time_s),p.Results.maxTries,1);
rDegs = randi(360,p.Results.maxTries,1);

% Preallocate temporary results
best = struct('lat_deg',[],'lon_deg',[],'alt_ft_msl',[],'alt_ft_agl',[],'xNorth_ft',[],'yEast_ft',[],'zDown_ft',[],'idxKeep',[],'idxCensor',[]);

% Iterate
while c <= p.Results.maxTries
    % Parse
    i0 = i0s(c);
    rDeg = rDegs(c);
    
    % Select which index will be (0,0)
    % Whatever is (0,0) will pass directly through the (lat0_deg,lon0_deg)
    x_ft = x_ft - x_ft(i0);
    y_ft = y_ft - y_ft(i0);
    
    % Randomly rotate and assign
    % https://en.wikipedia.org/wiki/Rotation_matrix
    
    yEast_ft = x_ft * cosd(rDeg) - y_ft * sind(rDeg);
    xNorth_ft = x_ft * sind(rDeg) + y_ft * cosd(rDeg);
    
    % Convert from up to down z-axis
    zDown_ft = z_ft(i0) - z_ft;
    
    % Reference altitude is the assumed MSL altitude of the reference point
    % Bayes uncorrelated & nonconventional model use AGL units in the lowest
    % altitude bins, so this calculation perseves the AGL shape
    % However Bayes HAA uses MSL, so we're forcing a MSL = AGL assummption for HAA
    h0_ft_msl = el0_ft_msl + z_ft(i0);
    
    % Convert to lat / lon
    % Convert to MSL / AGL if needed
    switch p.Results.z_units
        case 'agl'
            % Convert to lat / lon
            [lat_deg,lon_deg,alt_ft_msl] = ned2geodetic(xNorth_ft,yEast_ft,zDown_ft,lat0_deg,lon0_deg,h0_ft_msl,spheroid_ft);
            
            % Get elevation and AGL lat / lon
            % Note if DEM is incomplete, alt_ft_agl may return NaN
            [el_ft_msl,alt_ft_agl,~,~] = msl2agl(lat_deg,lon_deg,p.Results.dem,'Z_m',Z_m,'refvec',refvec,'R',R,'alt_ft_msl',alt_ft_msl,'isCheckOcean',false);
            
        case 'msl'
            % Convert to lat / lon
            [lat_deg,lon_deg,~] = ned2geodetic(xNorth_ft,yEast_ft,zDown_ft,lat0_deg,lon0_deg,h0_ft_msl,spheroid_ft);
            
            % z_ft is already in MSL
            alt_ft_agl = z_ft;
            alt_ft_msl = z_ft;
    end
    
    % Check to make sure not hitting obstacles
    isObstacle = false(nnz(alt_ft_agl),numObstacle);
    for i=1:1:numObstacle
        isXY = InPolygon(lat_deg,lon_deg,latObstacle(:,i),lonObstacle(:,i));
        iZ = altObstacle_ft_agl(i) >= alt_ft_agl;
        isObstacle(:,i) = isXY & iZ;
    end
    
    % Determine which points are not near an obstacle, not NaN, not underground and satisfy z tolerance
    isGood = ~any(isObstacle,2) & ~isnan(alt_ft_agl) & alt_ft_agl >=0 & abs(alt_ft_agl-z_ft) <= z_agl_tol_ft;
    
    % Find longest sequence of consecutive non-zero values
    % This produces the longest track above ground
    % https://www.mathworks.com/matlabcentral/answers/404502-find-the-longest-sequence-of-consecutive-non-zero-values-in-a-vector#answer_323627
    zpos = find(~[0 isGood' 0]);
    [~, grpidx] = max(diff(zpos));
    idxKeep = zpos(grpidx):zpos(grpidx+1)-2;
    idxCensor = idx; idxCensor(idxKeep) = [];
    
    % Update if a better track was estimated
    if c == 1 || (nValidPoints < nnz(idxKeep))
        % Update
        nValidPoints = nnz(idxKeep);
        
        % Update struct
        best.lat_deg = lat_deg;
        best.lon_deg = lon_deg;
        best.alt_ft_msl = alt_ft_msl;
        best.alt_ft_agl = alt_ft_agl;
        best.xNorth_ft = xNorth_ft;
        best.yEast_ft = yEast_ft;
        best.zDown_ft = zDown_ft;
        best.idxKeep = idxKeep;
        best.idxCensor = idxCensor;
    end
    
    % Advance counter
    % If not points censored, set counter to Inf to break loop
    if  nValidPoints == nPoints
        c = inf;
    else
        c = c + 1;
    end
end

%% Plot
if p.Results.isPlot
    
    % Populate workspace with best estimated track
    lat_deg = best.lat_deg;
    lon_deg = best.lon_deg;
    alt_ft_msl = best.alt_ft_msl;
    alt_ft_agl = best.alt_ft_agl;
    %xNorth_ft = best.xNorth_ft;
    %yEast_ft = best.yEast_ft;
    %zDown_ft = best.zDown_ft;
    idxKeep = best.idxKeep;
    %idxCensor = best.idxCensor;
    
    figure; set(gcf,'name','placeTrack');
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
    nexttile(1:2);
    geoplot(lat0_deg,lon0_deg,'k*','DisplayName','Origin'); hold on;
    geoplot(lat_deg,lon_deg,'r--','DisplayName','Censored');
    geoplot(lat_deg(idxKeep),lon_deg(idxKeep),'b-','DisplayName','Final Track');
    grid on;
    
    % Try to make lat0_deg,lon0_deg the map center
    set(gca,'MapCenter',[lat0_deg,lon0_deg],'Basemap','topographic','TickLabelFormat','dd');
    [latlim,lonlim] = geolimits(gca); latlim = latlim'; lonlim = lonlim';
    latlim = [min([latlim;lat0_deg;lat_deg]) max([latlim;lat0_deg;lat_deg])];
    lonlim = [min([lonlim;lon0_deg;lon_deg]) max([lonlim;lon0_deg;lon_deg])];
    latlim = round(latlim,4) + [-.0001 .0001];
    lonlim = round(lonlim,4) + [-.0001 .0001];
    
    % Plot obstacles
    if ~isempty(latObstacle)
        latobs = [latObstacle; nan(1,size(latObstacle,2))];
        lonobs = [lonObstacle; nan(1,size(lonObstacle,2))];
        geoplot(latobs(:),lonobs(:),'k-','DisplayName','Obstacle Polygons');
    end
    hold off;
    geolimits(latlim,lonlim);
    legend('Location','best');
    
    nexttile(3);
    if strcmpi(p.Results.z_units,'agl')
        plot(time_s,z_ft,'k-',time_s,alt_ft_agl,'r--',time_s(idxKeep),alt_ft_agl(idxKeep),'b-');
        %hold on; xline(i0,'-.'); hold off;
        legend('Input','Censored','Final','Interpreter','none','Location','best');
    end
    grid on; xlabel('Time (s)'); ylabel('Feet (AGL)'); title('AGL Altitude');
    
    nexttile(4);
    switch p.Results.z_units
        case 'agl'
            plot(time_s,el_ft_msl,'k-',time_s,alt_ft_msl,'r--',time_s(idxKeep),alt_ft_msl(idxKeep),'b-');
            legend('Elevation','Censored','Final','none','Location','best');
        case 'msl'
            plot(time_s,z_ft,'k-',time_s,alt_ft_msl,'b--');
            legend('z_ft','alt_ft_msl','Interpreter','none','Location','best');
    end
    %hold on; xline(i0,'-.'); hold off;
    grid on; xlabel('Time (s)'); ylabel('Feet (MSL)'); title('MSL Altitude');
end

%% Update output timetable with best track
% Update X/Y
Tout.north_ft = best.xNorth_ft;
Tout.east_ft = best.yEast_ft;

% Add down
Tout.down_ft = best.zDown_ft;

% Add geodetic
Tout.lat_deg = best.lat_deg;
Tout.lon_deg = best.lon_deg;
Tout.alt_ft_msl = best.alt_ft_msl;
Tout.alt_ft_agl = best.alt_ft_agl;

% Filter
Tout = Tout(best.idxKeep,:);

% Make sure time starts at 1
switch class(Tout)
    case 'timetable'
        if Tout.Properties.StartTime ~= seconds(0)
            Tout.Properties.StartTime = seconds(0);
        end
    otherwise
        time_s = Tout.(p.Results.labelTime);
        if ~isempty(time_s) && time_s(1) ~=1
            time_s = (time_s - time_s(1))+1;
            Tout.(p.Results.labelTime) = time_s;
        end
end

% Issue warning
if isempty(idxKeep)
    warning('placeTracks:idxKeep','After %i tries, track not succesfully translated to geodetic coordinate system',p.Results.maxTries);
end

%% Change back to original seed
if ~isnan(seed) && ~isempty(seed)
    rng(oldSeed);
end
