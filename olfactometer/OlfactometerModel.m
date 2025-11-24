classdef OlfactometerModel < handle
    properties
        sampleRate
        backValves
        frontValves
        syncTTL
        inputTrigger
        preSequenceTime
        postSequenceTime
        pulseTime
        acquisitionTime
        acquisitionSamples
        backValveDelaySamples
        preSequenceSamples
        postSequenceSamples
        pulseSamples
        cycleSamples
        ttlBitSamples
        allOdourValves
        allCleanAirValves
        valveSession
        bottles
    end

    methods
        function self = OlfactometerModel(constants)
            self.sampleRate = constants.sampleRate;
            self.backValves = constants.backValves;
            self.frontValves = constants.frontValves;
            self.syncTTL = constants.syncTTL;
            
            self.preSequenceTime = constants.preSequenceTime;
            self.postSequenceTime = constants.postSequenceTime;
            self.pulseTime = constants.pulseTime;

            self.backValveDelaySamples = round(constants.backValveDelay * self.sampleRate);
            self.preSequenceSamples = round(constants.preSequenceTime * self.sampleRate);
            self.postSequenceSamples = round(constants.postSequenceTime * self.sampleRate);
            self.pulseSamples = round(constants.pulseTime * self.sampleRate);
            self.cycleSamples = round(0.004 * self.sampleRate);
            self.ttlBitSamples = round(0.004 * self.sampleRate);

            self.allOdourValves = [2:7, 10:16];
            self.allCleanAirValves = [0, 1, 8, 9];

            self.initTask();
        end

        function initTask(self)
            
            self.valveSession = daq("ni");
            
            addoutput(self.valveSession, self.frontValves.deviceID, self.frontValves.channelID, self.frontValves.measurementType);
            addoutput(self.valveSession, self.backValves.deviceID, self.backValves.channelID, self.backValves.measurementType);
            addoutput(self.valveSession, self.syncTTL.deviceID, self.syncTTL.channelID, self.syncTTL.measurementType);
            % there must be at least one analog input channel to access the
            % internal clock on the NI board.
            addinput(self.valveSession, "analogInput", "ai0", "Voltage");

            self.valveSession.Rate = self.sampleRate;
        end

        function cleanAirValve = determine_clean_air_valve(~, odourValve)
            valveMap = containers.Map('KeyType','int32','ValueType','int32');
            for k = [3:8, 11:16]
                if k > 9
                    valveMap(k) = floor(k/8)*8 + 1 + mod(k, 2);
                else
                    valveMap(k) = 1 + mod(k, 2);
                end
            end
            if isKey(valveMap, odourValve)
                cleanAirValve = valveMap(odourValve);
            else
                cleanAirValve = -1;
            end
        end

        function valveStates = generate_valve_pattern(self, odourValves, dutyCycles, label)
            self.acquisitionTime = (self.preSequenceTime + self.pulseTime + self.postSequenceTime) * length(odourValves);
            self.acquisitionSamples = round(self.acquisitionTime * self.sampleRate);
            
            valveStates = false(self.frontValves.channelCount+self.backValves.channelCount+self.syncTTL.channelCount, self.acquisitionSamples);
            cleanAirValves = arrayfun(@(v) self.determine_clean_air_valve(v), odourValves);
            valveStates(self.allCleanAirValves + 1, :) = true;

            for k = 1:length(odourValves)
                onSamples = round(self.cycleSamples * dutyCycles(k));
                starts = 0:self.cycleSamples:(self.pulseSamples - self.cycleSamples);
                pulsePattern = reshape(starts' + (0:onSamples-1), [], 1);
                idx = pulsePattern + self.preSequenceSamples + self.pulseSamples * (k - 1);
                valveStates(odourValves(k), idx) = true;
                if ~ismember(odourValves(k), [1, 2, 9, 10])
                    valveStates(odourValves(k) + 16, (self.preSequenceSamples + self.pulseSamples * (k - 1) + self.backValveDelaySamples):(self.preSequenceSamples + self.pulseSamples * k - self.backValveDelaySamples)) = true;
                end
                valveStates(cleanAirValves(k), idx) = false;
            end

            bytes = uint8(char(label));
            bits = dec2bin(bytes, 8)';
            bits = bits(:);
            bits = bits(1:(length(label) * 7));
            trueIdx = find(bits) + 2;
            trueIdx = [0; trueIdx];
            ttlIdx = reshape((trueIdx' .* self.ttlBitSamples) + (0:(self.ttlBitSamples-1))', [], 1) + self.preSequenceSamples;
            valveStates(33, ttlIdx) = true;
        end

        function play_valve_sequence(self, odourValves, dutyCycles, label)
            pattern = self.generate_valve_pattern(odourValves, dutyCycles, label);
            preload(self.valveSession, double(pattern)');
            start(self.valveSession);
            pause(self.acquisitionTime);
            stop(self.valveSession);
            flush(self.valveSession);
        end

        function checkStatus(status)
            if status ~= 0
                errBuf = repmat(' ', 1, 2048);
                calllib('nicaiu', 'DAQmxGetErrorString', status, errBuf, 2048);
                error('DAQmx Error %d: %s', status, strtrim(errBuf));
            end
        end

        function dutycycles = get_odour_dutycycles(self, valve_num)

            chemTable = readtable('odour_chemicals.tsv', 'FileType', 'text', 'Delimiter', '\t');
            self.bottles = struct( ...
                'Name',   {'BL1','BL2','C3cA','C4cA','C3cB','C4cB','C3f','O','BL9','BL10','MeA','MwB','MeB','BL14','MwA','C4f'}, ...
                'Chemicals', { ...
                    {'AIR'}, ...
                    {'AIR'}, ...
                    {'MES'}, ...
                    {'CIL'}, ...
                    {'DMB'}, ...
                    {'GER'}, ...
                    {'MBZ'}, ...
                    {'HAP'}, ...
                    {'AIR'}, ...
                    {'AIR'}, ...
                    {'ATR','ECP'}, ...
                    {'AIR'}, ...
                    {'MTR','FCH'}, ...
                    {'ACP','GUA'}, ...
                    {'MAP','CYH'}, ...
                    {'CEN'} ...
                } ...
            );
            
            for i = 1:numel(self.bottles)
                chems = self.bottles(i).Chemicals;
                sat_vals = zeros(1, numel(chems));
                for j = 1:numel(chems)
                    idx = strcmpi(chemTable.Code, chems{j});
                    if any(idx)
                        sat_vals(j) = chemTable.Saturated_ppm(idx);
                    else
                        sat_vals(j) = NaN;
                    end
                end
                self.bottles(i).Saturated_ppm = sat_vals;
            end
        
            target_ppm = 20;
            
            for i = 1:numel(self.bottles)
                sat_ppms = self.bottles(i).Saturated_ppm;
            
                if isempty(sat_ppms) || all(isnan(sat_ppms))
                    duty = NaN;  % skip missing data
                else
                    mean_sat = mean(sat_ppms, 'omitnan');
                    duty = min(max(target_ppm / mean_sat, 0.05), 1);
                end
            
                self.bottles(i).DutyCycle = duty;
            end
            dutycycles = [self.bottles(valve_num).DutyCycle];
        end
    end
end