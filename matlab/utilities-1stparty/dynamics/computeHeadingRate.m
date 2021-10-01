function [dpsi_rad_s,deltaHeading,dt] = computeHeadingRate(heading_rad,time_s)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Input parser
p = inputParser;

% Optional - Directories
addOptional(p,'heading_rad',@isnumeric); % heading in radians
addOptional(p,'time_s',@isnumeric); % Time

% Parse
parse(p,heading_rad,time_s);

%% Basic error checking
assert(all(size(heading_rad) == size(time_s)),'heading and time_s are not the same size');
assert(all(time_s >= 0),'time_s cannot be negative');

%% Calculate delta heading in radians (e.g. correct for unit circle)
% This code block was copied from the old MIT LL compute_delta_heading() function
h = heading_rad(1:(end-1));
hh = heading_rad(2:end);
deltaHeading = abs(h - hh);
i = deltaHeading > pi;
deltaHeading(i) = 2*pi - deltaHeading(i);
i = abs(wrapTo2Pi(h + deltaHeading) - wrapTo2Pi(hh)) > 1e-10;
deltaHeading(i) = -deltaHeading(i);

%% Calculate heading change w.r.t time
dt = diff(time_s(1 : end));
dpsi_rad_s = deltaHeading ./ dt;

%% Append
dpsi_rad_s = [dpsi_rad_s; dpsi_rad_s(end)];
