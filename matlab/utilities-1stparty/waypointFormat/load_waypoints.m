% Copyright 2019 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%LOAD_WAYPOINTS   Loads waypoints from file.
%   LOAD_WAYPOINTS(FILENAME) returns a structure holding the waypoints
%   stored in the specified file.
%
%   WAYPOINTS FILE:
%   The waypoints file contains a set of encounters. Each encounter is
%   defined by a set of waypoints associated with a fixed number of
%   aircraft. The waypoints are positions in space according to a fixed,
%   global coordinate system. All distances are in feet. Time is specified
%   in seconds since the beginning of the encounter. The file is organized
%   as follows:
%
%   [Header]
%   uint32 (number of encounters)
%   uint32 (number of aircraft)
%       [Encounter 1]
%           [Initial positions]
%               [Aircraft 1]
%               double (north position in feet)
%               double (east position in feet)
%               double (altitude in feet)
%               ...
%               [Aircraft n]
%               double (north position in feet)
%               double (east position in feet)
%               double (altitude in feet)
%           [Updates]
%               [Aircraft 1]
%               uint16 (number of updates)
%                   [Update 1]
%                   double (time in seconds)
%                   double (north position in feet)
%                   double (east position in feet)
%                   double (altitude in feet)
%                   ...
%                   [Update m]
%                   double (time in seconds)
%                   double (north position in feet)
%                   double (east position in feet)
%                   double (altitude in feet)
%               ...
%               [Aircraft n]
%                   ...
%       ...
%       [Encounter k]
%           ...
%
%   WAYPOINTS STRUCTURE:
%   The waypoints structure is an m x n structure matrix, where m is the
%   number of aircraft and n is the number of encounters. This structure
%   matrix has two fields: initial and update. The initial field is a 3
%   element array specifying the north, east, and altitude. The update
%   field is a 4 x n matrix, where n is the number of updates. The rows
%   correspond to the time, north, east, and altitude position of the
%   waypoints.
function waypoints = load_waypoints(filename,varargin)
waypoints = load_encounters(filename, 3, 4, 'uint16',varargin{:});
