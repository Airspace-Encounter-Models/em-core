function [S_dof, Tdof] = gridDOF(varargin)
% Copyright 2019 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

addParameter(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof.mat']);
addParameter(p,'spheroid_ft',wgs84Ellipsoid('ft'));
addParameter(p,'npts',50,@isnumeric);

% Filter criteria
addParameter(p,'obsTypes',{''}); % Obstacle types to keep, if empty will do no filter
addParameter(p,'BoundingBox_wgs84',[-178, 17, ; -52, 72],@isnumeric); % Bounding box
addParameter(p,'minHeight_ft',50,@isnumeric); % Minimum height of obstacles to keep
addParameter(p,'isVerified',true,@islogical); % If true, remove unverified obstacles

parse(p,varargin{:});

%% Load and filter dof
load(p.Results.inFile,'Tdof');

% minimum height
l = Tdof.alt_ft_agl >= p.Results.minHeight_ft;

% obstacle type
if ~isempty(p.Results.obsTypes); l = l & contains(Tdof.obs_type,p.Results.obsTypes); end

% verification status
if p.Results.isVerified; l = l & strcmpi(Tdof.verification_status,'verified'); end

% Initial filter and bounding box
Tdof = Tdof(l,:);
[~, ~, inBox] = filterboundingbox(Tdof.lat_deg,Tdof.lon_deg,p.Results.BoundingBox_wgs84);
Tdof = Tdof(inBox,:);

% Filter points without horizontal or vertical accuracy
% This always happens, the user can't control this behavior
Tdof(isnan(Tdof.acc_horz_ft),:) = [];
Tdof(isnan(Tdof.acc_vert_ft),:) = [];

% The best accuracy should be 20 feet (see readfaadof) and we can't create
% a circle with radius = 0
Tdof(Tdof.acc_horz_ft==0,:) = [];

%% Calculate radius and output
[latc_deg,lonc_deg] = scircle1(Tdof.lat_deg,Tdof.lon_deg,Tdof.acc_horz_ft,[],p.Results.spheroid_ft,'degrees',p.Results.npts);
z = Tdof.alt_ft_agl+Tdof.acc_vert_ft;
S_dof = table((1:1:size(latc_deg,2))', mat2cell(latc_deg,p.Results.npts,repmat(1,size(latc_deg,2),1))', mat2cell(lonc_deg,p.Results.npts,repmat(1,size(latc_deg,2),1))',z,'VariableNames',{'id','LAT_deg','LON_deg','height_ft_agl'}); % Create new streamlined table

Tdof.lat_acc_deg = S_dof.LAT_deg;
Tdof.lon_acc_deg = S_dof.LON_deg;

