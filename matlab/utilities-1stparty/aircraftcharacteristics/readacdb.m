function data = readacdb(varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Name of input file
addOptional(p,'inFile',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-AircraftCharacteristicsDB' filesep 'faa_acdb_current.xlsx']);

% Parse
parse(p,varargin{:});

%% Load raw data
data = readtable(p.Results.inFile,'Sheet','Aircraft Database','FileType','spreadsheet','ReadVariableNames',true,'PreserveVariableNames',false);

% Remove lines with "tbd" entries
istbd = any(strcmp([data.x_Engines, data.Wingspan_Ft, data.Length_Ft, data.TailHeight_Ft__OEW_],'tbd'),2);
data = data(~istbd,:);

% Number of lines
numLines = size(data,1);

%% Allocate or Preallocate
wingspan_ft = str2double(data.Wingspan_Ft);
length_ft = str2double(data.Length_Ft);
height_ft = str2double(data.TailHeight_Ft__OEW_);
numEngines = str2double(data.x_Engines);

