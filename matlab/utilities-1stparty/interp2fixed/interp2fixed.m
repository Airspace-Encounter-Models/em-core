function [LAT_interp_deg,LON_interp_deg] = interp2fixed(LAT_deg,LON_deg,spacing_nm,method)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% https://www.mathworks.com/matlabcentral/answers/142161-how-can-i-interpolate-x-y-coordinate-path-with-fixed-interval#answer_145402

%% Input handling
if nargin < 4; method = 'linear'; end

%% Some input handling because code below assumes cell containers
if ~iscell(LAT_deg)
    LAT_deg = {LAT_deg}; LON_deg = {LON_deg};
end

%% Interpolate vectors
% Determine the number of iterations
n = size(LAT_deg,1);

% Preallocate
LON_interp_deg = cell(n,1);
LAT_interp_deg = cell(n,1);

% Parse out to reduce parfor overhead
X = LON_deg;
Y = LAT_deg;

% Iterate
for i=1:1:n
    % Get ith coordinates and remove trailing NaN if needed
    x = X{i}; y = Y{i};
    if isnan(x(end)); x = x(1:end-1); y = y(1:end-1); end
    
    % Remove any other NaN, such as a NaN seperating two vectors
    % I think this is okay and this only happens in only very rare cases
    x(isnan(x)) = []; y(isnan(y)) = [];
    
    % Calculate the arclength
    total_length_deg = arclength(x,y,method);
    % total_length_nm = deg2nm(total_length_deg);
    
    % Interpolate points along a curve using a fixed interval
    pt = interparc(0:(nm2deg(spacing_nm)/total_length_deg):1,x,y,method);
    
    % Assign
    LON_interp_deg{i} = [pt(:,1); x(end)];
    LAT_interp_deg{i} = [pt(:,2); y(end)];
end
