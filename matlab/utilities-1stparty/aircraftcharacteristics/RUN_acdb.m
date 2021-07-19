%% Inputs
%icaoCodes = {'A320','A321','A319','B737','B757','B717','B777','B767','CL60','DH8','CL30','E170','E145','E190','E135','MD88','PA44'};
icaoCodes = {'B747'};

%% Load data
data = readacdb();

%% Iterate over icao codes
% Preallocate
wingspan_ft = nan(numel(icaoCodes),1);
length_ft = nan(numel(icaoCodes),1);
height_ft = nan(numel(icaoCodes),1);
numEngines = nan(numel(icaoCodes),1);

% Iterate
for i=1:1:numel(icaoCodes)
    % Create logical index
    l = strfind(data.ICAOCode,icaoCodes{i});
    l = ~cellfun(@isempty,l);
    
    if any(l)
        % Filter
        d = data(l,:);
        
        % Assign
        % Convert to double, calculate average, round
        wingspan_ft(i) = round(mean(str2double(d.Wingspan_Ft)));
        length_ft(i) = round(mean(str2double(d.Length_Ft)));
        height_ft(i) = round(mean(str2double(d.TailHeight_Ft__OEW_)));
        
        % Assign engines
        numEngines(i) = str2double(d.x_Engines(1));
    end
end

%% Plot
figure;
scatter3(wingspan_ft,length_ft,height_ft,'.'); grid on; view([0 90]);
xlabel('Wingspan (ft)'); ylabel('Length (ft)'); zlabel('Height (ft)');
