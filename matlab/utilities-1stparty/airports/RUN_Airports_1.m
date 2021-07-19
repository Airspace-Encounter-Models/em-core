% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%% Inputs
% Input File
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-Airports' filesep 'Airports'];

% readAirspace parameters
classInclude = ["B","C","D"]; % Airspace classes to keep,

% Output directory and name
outDir = [getenv('AEM_DIR_CORE') filesep 'output'];
outName = ['airports-' sprintf('%c-',classInclude) date];

%% Run function
airports = readAirports('inFile',inFile,'classInclude',classInclude);

%% Save to MATLAB .mat file
% Save data twice, one with a filename with the date; the other with a
% default filename without a date to be called by other functions
save([outDir filesep outName '.mat'],'inFile','airports','classInclude');
save([outDir filesep 'airports' '.mat'],'inFile','airports','classInclude');

%% Display status to screen
l = airports.private_use == 0 & strcmpi(airports.miltary_code,"civil") & ~strcmpi(airports.id_FAA,"") & ~strcmpi(airports.id_ICAO,"");

fprintf('%i civil, not private airports with a valid FAA and ICAO identifier\n',sum(l));
