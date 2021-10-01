function [codeAir, codeOpt] = parseCert(cert)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%
% SEE ALSO readfaaacreg

codeAir = '';
codeOpt = '';

if isempty(cert)
    codeAir = 'Blank';
    codeOpt = 'Blank';
else
    switch cert(1)
        case '1'
            codeAir = 'Standard';
            if numel(cert) > 1
                switch cert(2)
                    case 'N'
                        codeOpt = 'Normal';
                    case 'U'
                        codeOpt = 'Utility';
                    case 'A'
                        codeOpt = 'Acrobatic';
                    case 'T'
                        codeOpt = 'Transport';
                    case 'G'
                        codeOpt = 'Glider';
                    case 'B'
                        codeOpt = 'Balloon';
                    case 'C'
                        codeOpt = 'Commuter';
                    case 'O'
                        codeOpt = 'Other';
                    otherwise
                        codeOpt = 'ERROR';
                end
            else
                codeOpt = 'Blank';
            end
            
        case '2'
            codeAir = 'Limited';
            codeOpt = 'Blank';
            
        case '3'
            codeAir = 'Restricted';
            
            % Iterate through operational code
            opt = cert(2:end);
            for j=1:1:numel(opt)
                % Parse operational code
                switch opt(j)
                    case '0'
                        optAdd = 'Other';
                    case '1'
                        optAdd = 'AgricultureAndPestControl';
                    case '2'
                        optAdd = 'AerialSurveying';
                    case '3'
                        optAdd = 'AerialAdvertising';
                    case '4'
                        optAdd = 'Forest';
                    case '5'
                        optAdd = 'Patrolling';
                    case '6'
                        optAdd = 'Weather Control';
                    case '7'
                        optAdd = 'CarriageofCargo';
                    otherwise
                        codeOpt = 'ERROR';
                end
                % Append operational codes
                if j==1
                    codeOpt = optAdd;
                else
                    codeOpt = sprintf('%s,%s',codeOpt,optAdd);
                end
            end % End j for() loop
            
        case '4'
            codeAir = 'Experimental';
            
            % Iterate through operational code
            opt = cert(2:end);
            for j=1:1:numel(opt)
                % Parse operational code
                switch opt(j)
                    case '0'
                        optAdd = 'ComplianceFAR';
                    case '1'
                        optAdd = 'R&D';
                    case '2'
                        optAdd = 'AmateurBuilt';
                    case '3'
                        optAdd = 'Exhibition';
                    case '4'
                        optAdd = 'Racing';
                    case '5'
                        optAdd = 'CrewTraining';
                    case '6'
                        optAdd = 'MarketSurvey';
                    case '7'
                        optAdd = 'OperatingKitBuiltAircraft';
                    case '8'
                        optAdd = 'LightSport';
                    case '9'
                        optAdd = 'UAS';
                    otherwise
                        codeOpt = 'ERROR';
                end
                % Append operational codes
                if j==1
                    codeOpt = optAdd;
                else
                    codeOpt = sprintf('%s,%s',codeOpt,optAdd);
                end
            end % End j for() loop
            
        case '5'
            codeAir = 'Provisional';
            if numel(cert) > 1
                switch cert(2)
                    case '1'
                        codeOpt = 'ClassI';
                    case '2'
                        codeOpt = 'ClassII';
                    otherwise
                        codeOpt = 'ERROR';
                end
            else
                codeOpt = 'Blank';
            end
        case '6'
            codeAir = 'Multiple';
            % Iterate through operational code
            opt = cert(2:end);
            for j=1:1:numel(opt)
                % Parse operational code
                if j <2
                    switch opt(j)
                        case '1'
                            optAdd = 'Standard';
                        case '2'
                            optAdd = 'Limited';
                        case '3'
                            optAdd = 'Restricted';
                        otherwise
                            codeOpt = 'ERROR';
                    end
                else
                    switch opt(j)
                        case '0'
                            optAdd = 'Other';
                        case '1'
                            optAdd = 'AgricultureAndPestControl';
                        case '2'
                            optAdd = 'AerialSurveying';
                        case '3'
                            optAdd = 'AerialAdvertising';
                        case '4'
                            optAdd = 'Forest';
                        case '5'
                            optAdd = 'Patrolling';
                        case '6'
                            optAdd = 'Weather Control';
                        case '7'
                            optAdd = 'CarriageofCargo';
                        otherwise
                            codeOpt = 'ERROR';
                    end
                end
                % Append operational codes
                if j==1
                    codeOpt = optAdd;
                else
                    codeOpt = sprintf('%s,%s',codeOpt,optAdd);
                end
            end % End j for() loop
            
        case '7'
            codeAir = 'Primary';
            codeOpt = 'Blank';
        case '8'
            codeAir = 'SpecialFlightPermit';
            % Iterate through operational code
            opt = cert(2:end);
            for j=1:1:numel(opt)
                % Parse operational code
                switch opt(j)
                    case '1'
                        optAdd = 'FerryFlight';
                    case '2'
                        optAdd = 'EvacuateDanger';
                    case '3'
                        optAdd = 'OperateExcess';
                    case '4'
                        optAdd = 'DeliveryOrExport';
                    case '5'
                        optAdd = 'ProductionFlightTesting';
                    case '6'
                        optAdd = 'CustomerDemo';
                    otherwise
                        codeOpt = 'ERROR';
                end
                % Append operational codes
                if j==1
                    codeOpt = optAdd;
                else
                    codeOpt = sprintf('%s,%s',codeOpt,optAdd);
                end
            end % End j for() loop
        case '9'
            codeAir = 'LightSport';
            if numel(cert) > 1
                switch cert(2)
                    case 'A'
                        codeOpt = 'Airplane';
                    case 'G'
                        codeOpt = 'Glider';
                    case 'L'
                        codeOpt = 'LighterthanAir';
                    case 'P'
                        codeOpt = 'PowerParachute';
                    case 'W'
                        codeOpt = 'WeightShiftControl';
                    otherwise
                        codeOpt = 'ERROR';
                end
            else
                codeOpt = 'Blank';
            end
        otherwise
            codeAir = 'ERROR';
            codeOpt = 'ERROR';
    end
end