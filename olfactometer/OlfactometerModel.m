classdef OlfactometerModel < handle
    properties
        sampleRate
        acquisitionTime
        backValves
        frontValves
        syncTTL
        inputTrigger
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
    end

    methods
        function self = OlfactometerModel(constants)
            self.sampleRate = constants.sampleRate;
            self.acquisitionTime = constants.acquisitionTime;
            self.backValves = constants.backValves;
            self.frontValves = constants.frontValves;
            self.syncTTL = constants.syncTTL;

            self.acquisitionSamples = round(self.acquisitionTime * self.sampleRate);
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
            totalSamples = self.acquisitionSamples;
            valveStates = false(self.frontValves.channelCount+self.backValves.channelCount+self.syncTTL.channelCount, totalSamples);
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
    end
end