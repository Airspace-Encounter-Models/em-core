function a = computeAcceleration(speed,time_s,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%COMPUTEACCELERATION  Computes acceleration of the given 1-D time series
%array of speeds and associated time array using the Matlab gradient 
%function (default) or with simple forward differencing. Time array must be
%strictly increasing but can have non-uniform spacing.
%
%  a = computeAcceleration(speed,time_s)
%  a = computeAcceleration(speed,time_s, 'mode', 'gradient')
%  a = computeAcceleration(speed,time_s, 'mode', 'simple')

%% Input parser
p = inputParser;

% Optional - Directories
addOptional(p,'speed',@isnumeric); % Speed
addOptional(p,'time_s',@isnumeric); % Time

% Optional - Filtering
addOptional(p,'mode','gradient',@(x) ischar(x) && any(strcmpi(x,{'simple','gradient'})));

% Parse
parse(p,speed,time_s,varargin{:});

%% Basic error checking
assert(numel(speed) == length(speed), 'input must be a 1-D array');
assert(all(size(speed) == size(time_s)),'speed and time_s are not the same size');
assert(all(diff(time_s) > 0),'time_s must be strictly increasing');

%% Calculate
switch p.Results.mode
    case 'simple'
        a = diff(speed) ./ diff(time_s);
        a(end+1) = a(end);
    case 'gradient'
        a = gradient(speed,time_s);
end
