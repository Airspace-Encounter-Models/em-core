% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
tic
% Inputs
inFile = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'FAA-DOF' filesep 'DOF.DAT'];
isSave = true;
outFile = [getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof-' date '.mat'];

% Execute
Tdof = readfaadof('inFile',inFile,'isSave',isSave,'outFile',outFile);

% Save with default filename without date
save([getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof.mat'],'Tdof');

% Create some logicals
isTower = strcmpi(Tdof.obs_type,'tower');
isVerified = strcmpi(Tdof.verification_status,'verified');

% Display to screen
utype = unique(Tdof.obs_type);
fprintf('%s has %i unique obstacle types\n',inFile,numel(utype));
fprintf('%s has %i verified towers\n',inFile,sum(isTower & isVerified));

% Plot
figure(100); set(gcf,'name',inFile);
worldmap('USA');
states = shaperead('usastatehi', 'UseGeoCoords', true);
geoshow(states,'FaceColor',[0 0 0]);
geoshow(Tdof.lat_deg(~isVerified),Tdof.lon_deg(~isVerified),'DisplayType','point','MarkerEdgeColor',[230 159 0]/255,'Marker','.','MarkerSize',2);
geoshow(Tdof.lat_deg(isVerified),Tdof.lon_deg(isVerified),'DisplayType','point','MarkerEdgeColor',[0 114 178]/ 255,'Marker','.','MarkerSize',2);
legend('USA Landmass','Unverified Obstacle','Verified Obstacle');
toc
