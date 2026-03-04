classdef OlfactometerModel < handle
    properties
        sampleRate
        backValves
        frontValves
        syncTTL
        triggered
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
        function self = OlfactometerModel(constants, triggered)
            self.sampleRate = constants.sampleRate;
            self.backValves = constants.backValves;
            self.frontValves = constants.frontValves;
            self.syncTTL = constants.syncTTL;

            self.triggered = triggered;
            self.inputTrigger = constants.inputTrigger;

            self.preSequenceTime = constants.preSequenceTime;
            self.postSequenceTime = constants.postSequenceTime;
            self.pulseTime = constants.pulseTime;

            self.backValveDelaySamples = round(constants.backValveDelay * self.sampleRate);
            self.preSequenceSamples = round(constants.preSequenceTime * self.sampleRate);
            self.postSequenceSamples = round(constants.postSequenceTime * self.sampleRate);
            self.pulseSamples = round(constants.pulseTime * self.sampleRate);
            self.cycleSamples = round(0.004 * self.sampleRate);
            self.ttlBitSamples = round(0.004 * self.sampleRate);

            self.allOdourValves = [3:8, 11:16];
            self.allCleanAirValves = [1, 2, 9, 10];
            self.initTask();
        end

        function initTask(self)
            
            self.valveSession = daq("ni");

            self.valveSession.addoutput(self.frontValves.deviceID, self.frontValves.channelID, self.frontValves.measurementType);
            self.valveSession.addoutput(self.backValves.deviceID, self.backValves.channelID, self.backValves.measurementType);
            self.valveSession.addoutput(self.syncTTL.deviceID, self.syncTTL.channelID, self.syncTTL.measurementType);
            % there must be at least one analog input channel to access the internal clock on the NI board.
            self.valveSession.addinput("analogInput", "ai0", "Voltage");
            % Configure digital start trigger
            if self.triggered
                self.valveSession.addtrigger("Digital", "StartTrigger", "External", self.inputTrigger);
                self.valveSession.DigitalTriggerTimeout = 30;
            end
            self.valveSession.Rate = self.sampleRate;
        end

        function cleanAirValve = determine_clean_air_valve(~, odourValve)
            valveMap = containers.Map('KeyType','int32','ValueType','int32');
            for k = [3:8, 11:16]
                if k > 9
                    valveMap(k) = floor(k/8)*8 + 1 + mod(k, 2);
                else
                    valveMap(k) = mod(k, 2) + 1;
                end
            end
            if isKey(valveMap, odourValve)
                cleanAirValve = valveMap(odourValve);
            else
                cleanAirValve = -1;
            end
        end

        function valveStates = generate_valve_pattern(self, odourValves, dutyCycles)
            self.acquisitionTime = (self.preSequenceTime + self.pulseTime + self.postSequenceTime) * length(odourValves);
            self.acquisitionSamples = round(self.acquisitionTime * self.sampleRate);
            
            valveStates = false(self.frontValves.channelCount+self.backValves.channelCount+self.syncTTL.channelCount, self.acquisitionSamples);
            cleanAirValves = arrayfun(@(v) self.determine_clean_air_valve(v), odourValves);
            valveStates(self.allCleanAirValves, :) = true;

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
                valveStates(end-4:end, idx) = true;
            end
        end

        function play_valve_sequence(self, odourValves, dutyCycles)
            pattern = self.generate_valve_pattern(odourValves, dutyCycles);
            self.valveSession.preload(double(pattern)');
            self.valveSession.start();
            pause(self.acquisitionTime);
            self.valveSession.stop();
            self.valveSession.flush();
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