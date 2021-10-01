function [encounters, num_ac, num_encounters] = load_encounters(filename, initial_dim, update_dim, num_update_type, varargin)
% Copyright 2019 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% This function is intended as a helper to load_scripts and load_waypoints
% Currently vararg takes 'limit', which is the maximum number of encounters
% to load from this file.  We'll load that many, or all of them in the
% file, whichever is less.

% open file and get basic parameters so we can preallocate memory later
fid = fopen(filename, 'r');
num_encounters = fread(fid, 1, 'uint32'); % number of encounters
num_ac = fread(fid, 1, 'uint32'); % number of aircraft

% parse the inputs for the encounter limit before preallocating
opts = inputParser;
opts.KeepUnmatched = false;
opts.addParamValue('limit', num_encounters);
opts.parse(varargin{:});
assert(isnumeric(opts.Results.limit) && opts.Results.limit > 0, 'limit must be a positive number.')

% verify that we're getting the smaller of the two
num_encounters = min([num_encounters opts.Results.limit]);

% preallocate memory
encounters(num_ac, num_encounters).initial = zeros(initial_dim, 1);
encounters(num_ac, num_encounters).update = zeros(update_dim, 0);

% load encounters
for i = 1:num_encounters
    for j = 1:num_ac
        encounters(j, i).initial = fread(fid, initial_dim, 'double');
    end
    for j = 1:num_ac
        num_update = fread(fid, 1, num_update_type);
        encounters(j, i).update = reshape(fread(fid, update_dim * num_update, 'double'), update_dim, num_update);
    end
end
fclose(fid);
