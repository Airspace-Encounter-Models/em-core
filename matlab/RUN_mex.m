% Copyright 2008 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

% InPolygon
mexDir = [getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-3rdparty' filesep 'InPolygon-MEX'];
eval(sprintf('mex %s -outdir %s',[mexDir filesep 'InPolygon.c'],mexDir))

% mksqlite
run([getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-3rdparty' filesep 'mksqlite' filesep 'buildit'])

% run_dynamics_fast
mexDir = [getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-1stparty' filesep 'runDynamicsFast'];
eval(sprintf('mex %s -outdir %s',[mexDir filesep 'run_dynamics_fast.c'],mexDir))
%eval(sprintf('mex -g %s -outdir %s',[mexDir filesep 'run_dynamics_fast.c'],mexDir)) % Uncomment for debugging
