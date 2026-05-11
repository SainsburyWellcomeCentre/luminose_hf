classdef SniffDetector < handle
    % SniffDetector  Online inhalation onset detection via Bpod FlexIO.
    %
    % Two separate concerns are cleanly separated:
    %
    %   1. Hardware (FlexIO) — fixed-voltage thresholds are required by the
    %      state machine.  Pass them explicitly via configure() so they come
    %      from the parameter GUI and are never baked into the algorithm.
    %
    %   2. Algorithm (detectFromAnalog) — purely signal-relative.  Matches the
    %      offline Python _all_inhalations pipeline: cubic spline detrending,
    %      low-pass filtering, prominence-based peak detection, zero-crossing
    %      onset/offset.  No voltage threshold is used.
    %
    % Usage
    % -----
    %   sniff = SniffDetector(channel, sampleRate);
    %   sniff.configure(S.GUI.SniffOnsetThreshold, S.GUI.SniffOffsetThreshold);
    %
    %   % In state machine, sniff.onsetEvent is 'Flex1Trig1' (for channel 1):
    %   sma = AddState(sma, 'Name', 'WaitForSniff', ...
    %       'Timer', 2, ...
    %       'StateChangeConditions', {sniff.onsetEvent, 'DeliverStim', 'Tup', 'exit'}, ...
    %       'OutputActions', {});
    %
    %   % After getTrialData — timestamp of hardware threshold crossing:
    %   onset_s  = sniff.getOnset(RawEvents);
    %   offset_s = sniff.getOffset(RawEvents);
    %
    %   % Per-trial post-hoc from saved analog data — adaptive algorithm:
    %   [onset_s, peak_s, offset_s] = sniff.detectFromAnalog(signal, odourOnset_s);
    %
    % FlexIO threshold polarity convention
    % -------------------------------------
    %   polarity 0 : fires when signal rises ABOVE threshold  (ascending)
    %   polarity 1 : fires when signal falls BELOW threshold  (descending)
    %
    % Paired threshold mode (thresholdMode = 1)
    % -----------------------------------------
    %   Trig1 fires on descent below threshold1 → inhalation onset.
    %   Crossing Trig1 enables Trig2.
    %   Trig2 fires on ascent above threshold2 → inhalation offset.
    %   Crossing Trig2 re-enables Trig1 for the next breath.

    properties
        channel    (1,1) double {mustBeInteger, mustBePositive} = 1
        sampleRate (1,1) double {mustBePositive} = 500  % Hz
        % Parameters for the adaptive detectFromAnalog algorithm
        prominence          (1,1) double = 0.15  % minimum trough depth as fraction of detrended signal range
        minWidth_s          (1,1) double = 0.05  % minimum inhalation duration (s)
        splineKnotSpacing_s (1,1) double = 2.0   % knot spacing for spline baseline removal (s); removes drift slower than ~knot_spacing/2
        lowpassHz           (1,1) double = 20.0  % low-pass cutoff applied to detrended residual (Hz)
    end

    properties (Dependent)
        onsetEvent   % 'Flex<ch>Trig1' — use directly in state machine conditions
        offsetEvent  % 'Flex<ch>Trig2'
    end

    methods

        function obj = SniffDetector(channel, sampleRate)
            if nargin >= 1, obj.channel    = channel;    end
            if nargin >= 2, obj.sampleRate = sampleRate; end
        end

        % --- Dependent property getters ----------------------------------

        function name = get.onsetEvent(obj)
            name = sprintf('Flex%dTrig1', obj.channel);
        end

        function name = get.offsetEvent(obj)
            name = sprintf('Flex%dTrig2', obj.channel);
        end

        % --- FlexIO configuration ----------------------------------------

        function configure(obj, onsetThreshold, offsetThreshold)
            % Write threshold settings to BpodSystem.FlexIOConfig.
            % Call once after the parameter GUI is synced, before the first trial.
            %
            %   onsetThreshold  (V) : signal must DROP BELOW to fire Trig1.
            %                         Set between baseline and sniff trough.
            %   offsetThreshold (V) : signal must RISE ABOVE to fire Trig2.
            %                         Should be >= onsetThreshold (adds hysteresis).
            %
            % These are purely for hardware triggering.  detectFromAnalog does
            % not use them — it derives onset/offset from the signal itself.
            global BpodSystem
            ch = obj.channel;
            BpodSystem.FlexIOConfig.channelTypes(ch)   = 2;  % Analog Input
            BpodSystem.FlexIOConfig.threshold1(ch)     = onsetThreshold;
            BpodSystem.FlexIOConfig.polarity1(ch)      = 1;  % fire when signal < threshold1
            BpodSystem.FlexIOConfig.threshold2(ch)     = offsetThreshold;
            BpodSystem.FlexIOConfig.polarity2(ch)      = 0;  % fire when signal > threshold2
            BpodSystem.FlexIOConfig.thresholdMode(ch)  = 1;  % paired: Trig1 enables Trig2
            BpodSystem.FlexIOConfig.analogSamplingRate = obj.sampleRate;
        end

        % --- Per-trial timestamp extraction from RawEvents ---------------

        function onset_s = getOnset(obj, RawEvents)
            % Timestamp of the first Flex<ch>Trig1 event (seconds from trial start).
            % Returns NaN if no threshold crossing occurred.
            onset_s = obj.firstEventTime(RawEvents, obj.onsetEvent);
        end

        function offset_s = getOffset(obj, RawEvents)
            % Timestamp of the first Flex<ch>Trig2 event (seconds from trial start).
            % Returns NaN if no return-to-baseline crossing occurred.
            offset_s = obj.firstEventTime(RawEvents, obj.offsetEvent);
        end

        % --- Adaptive post-hoc detection from acquired analog data -------

        function [onset_s, peak_s, offset_s] = detectFromAnalog(obj, signal, searchFrom_s)
            % Find the first inhalation after searchFrom_s.
            %
            % Algorithm (matches offline Python _all_inhalations):
            %   1. Fit a cubic spline to the raw signal and subtract it —
            %      removes slow baseline drift without edge effects.
            %      Knot spacing (splineKnotSpacing_s) sets the drift timescale.
            %   2. Low-pass filter the residual to remove high-frequency noise.
            %   3. Find troughs on the detrended signal using prominence and
            %      minimum width.  Dynamic range is from the detrended signal so
            %      baseline wander no longer inflates the threshold.
            %   4. Take the first trough at or after searchFrom_s.
            %   5. Onset  = last zero crossing going negative before the peak.
            %   6. Offset = first zero crossing going positive after the peak.
            %
            % Inputs
            %   signal       : numeric vector, raw sniff samples for one trial (V)
            %   searchFrom_s : start search at this time (s from trial start, default 0)
            %
            % Outputs (seconds from trial start; NaN if not found)
            %   onset_s  : inhalation onset
            %   peak_s   : signal minimum (trough)
            %   offset_s : inhalation offset

            onset_s = NaN; peak_s = NaN; offset_s = NaN;
            if nargin < 3 || isempty(searchFrom_s), searchFrom_s = 0; end

            sig = double(signal(:));
            n   = numel(sig);
            if n < 10 || all(isnan(sig)), return; end

            % 1. Cubic spline baseline removal.
            t_s         = (0:n-1)' / obj.sampleRate;
            knotSpacing = round(obj.splineKnotSpacing_s * obj.sampleRate);
            interior    = (knotSpacing : knotSpacing : n - knotSpacing)' / obj.sampleRate;
            if numel(interior) >= 1
                sp       = spap2(augknt([t_s(1); interior; t_s(end)], 4), 4, t_s, sig);
                baseline = fnval(sp, t_s);
            else
                baseline = linspace(sig(1), sig(end), n)';
            end
            detrended = sig - baseline;

            % 2. Low-pass filter the residual.
            nyq = obj.sampleRate / 2;
            if obj.lowpassHz < nyq
                [b, a]    = butter(4, obj.lowpassHz / nyq, 'low');
                filtered  = filtfilt(b, a, detrended);
            else
                filtered = detrended;
            end

            dyn = max(filtered) - min(filtered);
            if dyn < 1e-6, return; end

            % 3. Find troughs on the detrended filtered signal.
            minWidthSamples = max(5, round(obj.minWidth_s * obj.sampleRate));
            [~, locs] = findpeaks(-filtered, ...
                'MinPeakProminence', obj.prominence * dyn, ...
                'MinPeakWidth',      minWidthSamples);
            if isempty(locs), return; end

            % 4. First trough at or after searchFrom_s.
            startSample = max(1, round(searchFrom_s * obj.sampleRate) + 1);
            mask        = locs >= startSample;
            if ~any(mask), return; end
            peakSample = locs(find(mask, 1));
            peak_s     = (peakSample - 1) / obj.sampleRate;

            % 5. Onset: last zero crossing going negative before the peak.
            leftSeg   = filtered(1:peakSample);
            crossings = find(diff(leftSeg < 0) > 0);  % False→True in (filtered < 0)
            if ~isempty(crossings)
                onset_s = crossings(end) / obj.sampleRate;
            else
                onset_s = 0;
            end

            % 6. Offset: first zero crossing going positive after the peak.
            rightSeg   = filtered(peakSample:end);
            crossings2 = find(diff(rightSeg < 0) < 0);  % True→False in (filtered < 0)
            if ~isempty(crossings2)
                offset_s = (peakSample + crossings2(1) - 1) / obj.sampleRate;
            end
        end

    end

    % --- Private helpers -------------------------------------------------

    methods (Access = private)

        function t = firstEventTime(~, RawEvents, evtName)
            t = NaN;
            if isempty(RawEvents) || ~isstruct(RawEvents) || ~isfield(RawEvents, 'Events')
                return
            end
            idx = find(strcmp(RawEvents.Events, evtName), 1);
            if ~isempty(idx)
                t = RawEvents.EventTimestamps(idx);
            end
        end

    end

end
