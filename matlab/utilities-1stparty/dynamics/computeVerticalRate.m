function dh = computeVerticalRate(altitude,time_s,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Input parser
p = inputParser;

% Optional - Directories
addOptional(p,'altitude',@isnumeric); % altitude
addOptional(p,'time_s',@isnumeric); % Time

% Optional - Filtering
addOptional(p,'mode','gradient',@(x) ischar(x) && any(strcmpi(x,{'simple','gradient'})));

% Parse
parse(p,altitude,time_s,varargin{:});

%% Basic error checking
assert(all(size(altitude) == size(time_s)),'altitude and time_s are not the same size');
assert(all(time_s >= 0),'time_s cannot be negative');

%% Calculate
switch p.Results.mode
    case 'simple'
        dh = diff(altitude) ./ diff(time_s);
        dh = [dh; dh(end)];
    case 'gradient'
        dh = gradient(altitude,time_s);
end
