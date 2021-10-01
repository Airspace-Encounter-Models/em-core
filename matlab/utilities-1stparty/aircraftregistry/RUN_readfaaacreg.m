% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
tic
% Inputs
inDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-AircraftRegistry'];
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'acregfaa-' date '.mat'];

% Execute
readfaaacreg('inDir',inDir,'outFile',outFile);
toc
