classdef OlfactometerModel < handle
    properties
        sampleRate
        backValves
        frontValves
        syncTTL
        triggered
        inputTrigger
        DigitalTriggerTimeout
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
            self.DigitalTriggerTimeout = constants.DigitalTriggerTimeout;

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
            self.valveSession.DigitalTriggerTimeout = 30;
            self.valveSession.addoutput(self.frontValves.deviceID, self.frontValves.channelID, self.frontValves.measurementType);
            self.valveSession.addoutput(self.backValves.deviceID, self.backValves.channelID, self.backValves.measurementType);
            self.valveSession.addoutput(self.syncTTL.deviceID, self.syncTTL.channelID, self.syncTTL.measurementType);
            % there must be at least one analog input channel to access the internal clock on the NI board.
            self.valveSession.addinput("analogInput", "ai0", "Voltage");
            % Configure digital start trigger
            if self.triggered
                self.valveSession.addtrigger("Digital", "StartTrigger", "External", self.inputTrigger);
            end
            self.valveSession.Rate = self.sampleRate;
        end

        function cleanAirValve = determine_clean_air_valve(~, odourValve)
            valveMap = containers.Map('KeyType','int32','ValueType','int32');
            for k = [3:8, 11:16]
                if k > 9
                    valveMap(k) = 9 + mod(k, 2);
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
            slotDuration = (self.preSequenceTime + self.pulseTime + self.postSequenceTime);
            slotSamples = round(slotDuration * self.sampleRate);
            
            self.acquisitionTime = slotDuration * length(odourValves);
            self.acquisitionSamples = round(self.acquisitionTime * self.sampleRate);
            
            valveStates = false(self.frontValves.channelCount+self.backValves.channelCount+self.syncTTL.channelCount, self.acquisitionSamples);
            cleanAirValves = arrayfun(@(v) self.determine_clean_air_valve(v), odourValves);
            valveStates(self.allCleanAirValves, :) = true;

            for k = 1:length(odourValves)
                onSamples = round(self.cycleSamples * dutyCycles(k));
                starts = 0:self.cycleSamples:(self.pulseSamples - self.cycleSamples);
                pulsePattern = reshape(starts' + (0:onSamples-1), [], 1);
                
                % Start of this odor's slot in samples
                slotStartSamples = (k-1) * slotSamples;
                % Pulse start within the slot
                pulseStartSamples = slotStartSamples + self.preSequenceSamples;
                
                idx = pulsePattern + pulseStartSamples;
                % Boundary check
                idx = idx(idx > 0 & idx <= self.acquisitionSamples);
                
                valveStates(odourValves(k), idx) = true;
                
                % Back valve (final valve) logic
                if ~ismember(odourValves(k), [1, 2, 9, 10])
                    bvStart = pulseStartSamples + self.backValveDelaySamples;
                    bvEnd = pulseStartSamples + self.pulseSamples - self.backValveDelaySamples;
                    valveStates(odourValves(k) + 16, bvStart:bvEnd) = true;
                end
                
                % Turn off clean air during pulses
                valveStates(cleanAirValves(k), idx) = false;
                
                % TTL sync
                valveStates(end-3:end, idx) = true;
            end
        end

        function play_valve_sequence(self, odourValves, dutyCycles)
            try
                if isempty(odourValves)
                    return;
                end
                pattern = self.generate_valve_pattern(odourValves, dutyCycles);
                self.valveSession.preload(double(pattern)');
                self.valveSession.start("Finite");
                tic;
                while self.valveSession.WaitingForDigitalTrigger
                    if toc > self.DigitalTriggerTimeout
                        self.valveSession.stop();
                        self.valveSession.flush();
                        fprintf('Trigger timeout: no trigger received within %d seconds', self.DigitalTriggerTimeout);
                    end
                    pause(0.1);
                end
        
                pause(self.acquisitionTime);
                self.valveSession.stop();
                self.valveSession.flush();
            catch ME
                % Always release hardware on error
                try
                    self.valveSession.stop();
                catch
                end
                try
                    self.valveSession.flush();
                catch
                end
                delete(self.valveSession);
                self.initTask();  % reinitialise fresh session
                rethrow(ME);
            end
        end

        function checkStatus(status)
            if status ~= 0
                errBuf = repmat(' ', 1, 2048);
                calllib('nicaiu', 'DAQmxGetErrorString', status, errBuf, 2048);
                error('DAQmx Error %d: %s', status, strtrim(errBuf));
            end
        end

        function dutycycles = get_odour_dutycycles(self, valve_num)

            % Load tables
            bottleTable = readtable('odour_bottles.tsv', 'FileType', 'text', 'Delimiter', '\t');
            chemTable   = readtable('odour_chemicals.tsv', 'FileType', 'text', 'Delimiter', '\t');
        
            n = height(bottleTable);
        
            self.bottles = struct( ...
                'Name', [], ...
                'Chemicals', [], ...
                'Ratios', [], ...
                'Saturated_ppm', [], ...
                'DutyCycle', [] ...
            );
        
            target_ppm = 20;
        
            for i = 1:n
                % --- Name ---
                self.bottles(i).Name = string(bottleTable.Name{i});
        
                % --- Chemicals ---
                chems = strtrim(strsplit(bottleTable.Chemicals{i}, ','));
                self.bottles(i).Chemicals = chems;
        
                % --- Ratios ---
                ratios = str2double(strsplit(bottleTable.Ratios{i}, ','));
                ratios = ratios / sum(ratios); % normalize
                self.bottles(i).Ratios = ratios;
        
                % --- Lookup saturated ppm for each chemical ---
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
        
                % --- Compute effective saturation (mixture-aware) ---
                if all(isnan(sat_vals))
                    duty = NaN;
                else
                    mean_sat = sum(sat_vals .* ratios, 'omitnan'); % weighted
                    duty = min(max(target_ppm / mean_sat, 0.05), 1);
                end
        
                self.bottles(i).DutyCycle = duty;
            end
            
            if isempty(valve_num)
                dutycycles = [];
            else
                dutycycles = [self.bottles(valve_num).DutyCycle];
            end
        
        end
    end
end