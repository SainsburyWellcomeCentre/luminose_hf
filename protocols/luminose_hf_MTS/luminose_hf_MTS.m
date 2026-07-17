    %% clear & setup
    clc;
    warning('off', 'MATLAB:HandleGraphics:ObsoleteProperty:JavaFrame');

    global BpodSystem S luminose olfModel sniffDetector
    luminose = LuminoseConstants();
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_MTS';
    [dataDir, dataBasename, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
    log_file = fullfile(dataDir, [regexprep(dataBasename, '_Session\d+$', '') '_log.txt']);
    diary(log_file);

    %% Configure trials
    S = BpodSystem.ProtocolSettings;
    isNewSession = ~isstruct(S) || isempty(fieldnames(S));
    if isNewSession
        GUIparams_luminose_hf_MTS();
        restorePatternParams({'cue', 'Template', 'Sample', 'opto'}, luminose.dmd.patternsFolder);
    else
        SavedGUI = S.GUI;
        GUIparams_luminose_hf_MTS();
        fNames = fieldnames(SavedGUI);
        for i = 1:numel(fNames)
            if isfield(S.GUI, fNames{i})
                S.GUI.(fNames{i}) = SavedGUI.(fNames{i});
            end
        end
    end
    LuminoseParameterGUI_hf_MTS('init', S);
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return
        end
    end
    S.GUI = BpodSystem.GUIData.ParameterGUI.LatestGUIParams;
    S = LuminoseParameterGUI_hf_MTS('sync', S);
    disp('START pressed — beginning experiment.');

    BpodSystem.Data.TrialResponse = [];
    BpodSystem.Data.SniffInhalationOnset_s  = [];
    BpodSystem.Data.SniffInhalationOffset_s = [];
    BpodSystem.Data.TrialOutcome = [];

    nextTrialType = getNextTrialType_hf_MTS(BpodSystem.Data, S);
    currentTrialType = nextTrialType;

    isHabituation = isfield(S.GUI, 'TrainingLevel') && (S.GUI.TrainingLevel == 1);
    if isHabituation
        ITI = repelem(0, S.GUI.maxTrials);
    else
        if S.GUI.VariableITI
            ITI = S.GUI.InterTrialInterval * (1.01 .^ (0:S.GUI.maxTrials-1));
            ITI(ITI > S.GUI.MaxITI) = S.GUI.MaxITI;
            ITI = ITI(randperm(length(ITI)))';
            ITI = round(ITI * 1000) / 1000;
        else
            ITI = S.GUI.InterTrialInterval * ones(1, S.GUI.maxTrials);
        end
    end

    %% Begin plotting
    BpodSystem.ProtocolFigures.OutcomePlot = figure('Position', [30 1035 1000 350], ...
        'name', 'Outcome Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.OutcomeAxes = axes('Position', [.06 .15 .92 .8]);
    BpodSystem.GUIHandles.OutcomeAxes.LooseInset = BpodSystem.GUIHandles.OutcomeAxes.TightInset;
    liveOutcomePlot_hf_MTS(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);

    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveAccuracyPlot_hf_MTS(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);

    BpodSystem.ProtocolFigures.RewardPlot = figure('Position', [1040 645 350 350], ...
        'name', 'Reward Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.RewardAxes = axes('Position', [.15 .12 .8 .8]);
    liveRewardPlot_hf_MTS(BpodSystem.GUIHandles.RewardAxes, 'init', []);

    BpodSystem.ProtocolFigures.ResponsePlot = figure('Position', [1400 645 350 350], ...
        'name', 'Response Time Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.ResponseAxes = axes('Position', [.15 .12 .8 .8]);
    liveResponseTimePlot_hf_MTS(BpodSystem.GUIHandles.ResponseAxes, 'init', []);

    BpodSystem.ProtocolFigures.EncoderPlot = figure('Position', [1400 1035 350 350], ...
        'name', 'Encoder Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    liveEncoderPlot_hf_MTS(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

    BpodNotebook('init');

    %% Configure Flex I/O Channels
    chanSniff = 1; chanPhotodetector = 2; chanFlowmeter = 3; chanNIDAQ = 4;
    channelTypes(1:4) = 4; % Disabled
    channelTypes(chanSniff) = 2; % Analog Input
    channelTypes(chanPhotodetector) = 2; % Analog Input
    channelTypes(chanFlowmeter) = 2; % Analog Input
    channelTypes(chanNIDAQ) = 2; % Digital Input
    BpodSystem.FlexIOConfig.channelTypes = channelTypes;

    sniffDetector = SniffDetector(chanSniff, 500);
    sniffDetector.risingEdge = logical(S.GUI.SniffRising);
    sniffDetector.configure(S.GUI.SniffOnsetThreshold, S.GUI.SniffOffsetThreshold);

    BpodSystem.startAnalogViewer;
    flexioPos = get(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position');
    flexioPos(1:2) = [30, 65];
    set(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position', flexioPos);

    %% Assert modules are USB-paired
    BpodSystem.assertModule({'HiFi','RotaryEncoder'}, [1 1]);

    H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
    R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1);

    if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
        error('Error: This protocol requires rotary encoder module v2 or newer');
    end

    %% Setup sound
    sf = 192000;
    H.SamplingRate = sf;
    errorSound = GenerateWhiteNoise(sf, S.GUI.NoiseTime, 1, 2);
    H.load(1, errorSound);
    cueSound = GenerateSineWave(sf, S.GUI.Freq_cue, S.GUI.CueTime);
    H.load(2, cueSound);
    TimeSoundTemplate = 0:1/sf:S.GUI.StimTime;
    TemplateSound = chirp(TimeSoundTemplate, S.GUI.LowFreq_Template, S.GUI.CueTime, S.GUI.HighFreq_Template);
    H.load(3, TemplateSound);
    TimeSoundSample = 0:1/sf:S.GUI.StimTime;
    SampleSound = chirp(TimeSoundSample, S.GUI.LowFreq_Sample, S.GUI.CueTime, S.GUI.HighFreq_Sample);
    H.load(4, SampleSound);

    H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 63;
    H.DigitalAttenuation_dB = -60;
    H.push;

    Envelope = 1/(H.SamplingRate*0.001):1/(H.SamplingRate*0.001):1;
    H.AMenvelope = Envelope;

    %% Setup Rotary Encoder module
    if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
        R.useAdvancedThresholds = 'on';
        R.setAdvancedThresholds([-35 10 10], [0 1 1], [0 S.GUI.ResponseTime 0.2]);
        R.sendThresholdEvents = 'on';
    else
        R.useAdvancedThresholds = 'off';
    end
    R.startUSBStream;

    %% Prepare and start first trial
    trialManager = BpodTrialManager;
    [sma, ~, currentActions] = PrepareStateMachine(S, currentTrialType, 1, ITI);
    sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
    repoDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    [~, gitHash] = system(['git -C "' repoDir '" rev-parse HEAD']);
    BpodSystem.Data.GitHash = strtrim(gitHash);
    trialManager.startTrial(sma);

    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        try
            t1 = tic;
            S = LuminoseParameterGUI_hf_MTS('sync', S);

            currentTrialType = nextTrialType;

            if handle_pause_condition(H, R); break; end

            if currentTrial < S.GUI.maxTrials
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                nextTrialType = getNextTrialType_hf_MTS(BpodSystem.Data, S);
                [sma, S, nextActions] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI);
                disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                SendStateMachine(sma, 'RunASAP');
            end

            RawEvents = trialManager.getTrialData;
            if handle_pause_condition(H, R); break; end

            t2 = tic;
            if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
                R.setAdvancedThresholds([-35 10 10], [0 1 1], [0 S.GUI.ResponseTime 0.2]);
            end
            disp(['set RE: ', num2str(toc(t2))]);

            if currentTrial < S.GUI.maxTrials
                trialManager.startTrial();
            end

            if ~isempty(fieldnames(RawEvents))
                BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
                BpodSystem.Data.TrialSettings(currentTrial) = S;
                BpodSystem.Data.RawEvents.Trial{currentTrial}.Actions = currentActions;
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;

                processedEvents = BpodSystem.Data.RawEvents.Trial{currentTrial};
                BpodSystem.Data.SniffInhalationOnset_s(currentTrial)  = sniffDetector.getOnset(processedEvents);
                BpodSystem.Data.SniffInhalationOffset_s(currentTrial) = sniffDetector.getOffset(processedEvents);
                disp(['Sniff onset: ' num2str(BpodSystem.Data.SniffInhalationOnset_s(currentTrial), '%.3f') ...
                      ' s  offset: ' num2str(BpodSystem.Data.SniffInhalationOffset_s(currentTrial), '%.3f') ' s']);

                outcome = getTrialOutcome_hf_MTS(BpodSystem.Data, currentTrial);
                BpodSystem.Data.TrialOutcome(currentTrial) = outcome;
                events = BpodSystem.Data.RawEvents.Trial{currentTrial}.Events;
                if isfield(events, 'BNC1High') && isfield(events, 'BNC2High')
                    if events.BNC1High(1) < events.BNC2High(1), BpodSystem.Data.TrialResponse(currentTrial) = 1;
                    else, BpodSystem.Data.TrialResponse(currentTrial) = 2; end
                elseif isfield(events, 'BNC1High'), BpodSystem.Data.TrialResponse(currentTrial) = 1;
                elseif isfield(events, 'BNC2High'), BpodSystem.Data.TrialResponse(currentTrial) = 2;
                else, BpodSystem.Data.TrialResponse(currentTrial) = NaN; end

                BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data);

                if currentTrial == 1
                    eventData = R.readUSBStream(0);
                    if ~isempty(eventData.EventTimestamps)
                        TrialStartTime = eventData.EventTimestamps(1);
                    else
                        TrialStartTime = 0;
                    end
                end
                BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0);

                t3 = tic;
                liveOutcomePlot_hf_MTS(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                disp(['Updated outcome plot: ', num2str(toc(t3))]);

                t4 = tic;
                liveAccuracyPlot_hf_MTS(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                disp(['Updated accuracy plot: ', num2str(toc(t4))]);

                t5 = tic;
                liveRewardPlot_hf_MTS(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                disp(['Updated reward plot: ', num2str(toc(t5))]);

                t6 = tic;
                liveResponseTimePlot_hf_MTS(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                disp(['Updated response time plot: ', num2str(toc(t6))]);

                t7 = tic;
                if currentTrial == 1
                    if ~isempty(BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps)
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    else
                        NextTrialStartTime = TrialStartTime;
                    end
                else
                    TrialStartTime = NextTrialStartTime;
                    if ~isempty(BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps)
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    end
                end
                BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime;
                BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                    BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime;

                TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial);
                liveEncoderPlot_hf_MTS(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);
                disp(['Updated rotary encoder plot: ', num2str(toc(t7))]);

                t8 = tic;
                SaveBpodSessionData;
                SaveOnlinePlots;
                disp(['Saved data: ', num2str(toc(t8))]);
            end
            if currentTrial < S.GUI.maxTrials
                currentActions = nextActions;
            end
        catch ME
            disp('=== CRASH ===');
            disp(ME.message);
            for iStack = 1:length(ME.stack)
                disp(['  ', ME.stack(iStack).name, ' line ', num2str(ME.stack(iStack).line)]);
            end
            break
        end
    end
    cleanup;


%% State machine
function [sma, S, actions] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI)
    global BpodSystem
    for tCell = {'cue', 'Template', 'Sample', 'opto'}
        t = tCell{1};
        probField = sprintf('patternProbs_%s', t);
        if isfield(S.GUI, probField)
            probs = S.GUI.(probField);
            probs = max(probs, 0);
            if sum(probs) > 0
                rowIdx = find(rand() <= cumsum(probs/sum(probs)), 1);
            else
                rowIdx = 1;
            end
            if ~isfield(BpodSystem.PluginObjects, 'SelectedPatternRow')
                BpodSystem.PluginObjects.SelectedPatternRow = struct();
            end
            BpodSystem.PluginObjects.SelectedPatternRow.(t) = rowIdx;
        end
    end
    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType};

    startAction = {'BNC1', 1, 'HiFi1', '*', 'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1};
    cueAction = {'RotaryEncoder1', '*Z'};
    stimTemplateAction = {'BNC1', 1}; % sync
    stimMatchAction = {'BNC1', 1}; % sync
    delayAction = {};
    isPatternResponse = false;
    isHabituation = isfield(S.GUI, 'TrainingLevel') && (S.GUI.TrainingLevel == 1);
    if isHabituation
        CueTime = 0;
        chooseState2 = 'GetResponse';
        chooseStateMatch = 'GetResponse';
        tupAction = 'GetResponse';
        switch currentTrialType
            case 1 % Match
                leftAction = 'Reward'; rightAction = 'GetResponse';
            case 2 % Non-match
                rightAction = 'Reward'; leftAction = 'GetResponse';
        end
    else
        CueTime = S.GUI.CueTime;
        switch cue
            case 'Odour'
                cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
                startAction{end+1} = 'SoftCode'; startAction{end+1} = 1;
            case 'Pattern'
                cueAction{end+1} = 'PWM3'; cueAction{end+1} = S.GUI.Intensity_cue; % mask
                cueAction{end+1} = 'SoftCode'; cueAction{end+1} = 8;
            case 'Light'
                cueAction{end+1} = 'PWM3'; cueAction{end+1} = S.GUI.Intensity_cue;
            case 'Sound'
                cueAction{end+1} = 'HiFi1'; cueAction{end+1} = ['P', 1];
        end

        % Template row/action is drawn fresh each trial (Odour: weighted
        % row draw; Pattern: precomputed above; Light/Sound: single
        % configured value). On Match, the sample is a verbatim replay of
        % the template's own action/code. On Non-match, the sample is
        % drawn via buildSampleAction (for Odour, restricted to the Sample
        % rows checked for this trial's template row).
        [templateAction, templateCode, templateNeedsSniff, templateRowIdx] = buildTemplateAction(S);
        stimTemplateAction = [stimTemplateAction, templateAction];
        if templateCode == 9
            % Pattern: SoftCode displays immediately (MASTER mode) —
            % fire it in the same state as the pattern itself.
            stimTemplateAction{end+1} = 'SoftCode'; stimTemplateAction{end+1} = templateCode;
        elseif templateCode > 0
            % Odour: dispatch ahead of time so the async valve sequence
            % (parfeval) has lead time before DeliverStimTemplate.
            startAction{end+1} = 'SoftCode'; startAction{end+1} = templateCode;
        end
        if templateNeedsSniff, chooseState2 = 'GetSniffTemplate'; else, chooseState2 = 'DeliverStimTemplate'; end

        switch currentTrialType
            case 1 % Match
                sampleAction = templateAction;
                sampleCode = templateCode;
                sampleNeedsSniff = templateNeedsSniff;
            case 2 % Non-match
                [sampleAction, sampleCode, sampleNeedsSniff] = buildSampleAction(S, templateRowIdx);
        end
        stimMatchAction = [stimMatchAction, sampleAction];
        if sampleCode == 9 || sampleCode == 10
            % Pattern (replayed Template code 9 on Match, or Sample code 10
            % on Non-match): SoftCode displays immediately (MASTER mode) —
            % fire it in the same state as the pattern itself.
            stimMatchAction{end+1} = 'SoftCode'; stimMatchAction{end+1} = sampleCode;
            isPatternResponse = true;
        elseif sampleCode > 0
            % Odour: dispatch ahead of time so the async valve sequence
            % (parfeval) has lead time before DeliverStimMatch.
            delayAction = {'SoftCode', sampleCode};
        end
        if sampleNeedsSniff, chooseStateMatch = 'GetSniffMatch'; else, chooseStateMatch = 'DeliverStimMatch'; end

        switch currentTrialType
            case 1 % Match
                leftAction = 'Reward';
                if S.GUI.Punishment
                    rightAction = 'Punishment'; tupAction = 'Punishment';
                else
                    rightAction = 'GetResponse'; tupAction = 'InterTrialInterval';
                end
            case 2 % Non-match
                rightAction = 'Reward';
                if S.GUI.Punishment
                    leftAction = 'Punishment'; tupAction = 'Punishment';
                else
                    leftAction = 'GetResponse'; tupAction = 'InterTrialInterval';
                end
        end
    end
    responseDetect = {};
    responseAction = {};
    switch response
        case 'Lick'
            responseDetect = {'BNC1High', leftAction, 'BNC2High', rightAction, 'Tup', tupAction};
            chooseState1 = chooseState2;
        case 'Rotary Encoder'
            responseDetect = {'RotaryEncoder1_1', leftAction, 'RotaryEncoder1_2', rightAction, 'Tup', tupAction};
            chooseState1 = 'InitRE';
            responseAction{end+1} = 'RotaryEncoder1'; responseAction{end+1} = ['Z;' 3];
    end
    if isPatternResponse
        responseAction{end+1} = 'PWM3'; responseAction{end+1} = S.GUI.Intensity_cue;
    end
    responseAction{end+1} = 'SoftCode'; responseAction{end+1} = 11;
    valveTimeLeft = GetValveTimes(S.GUI.RewardAmount, 1);
    valveTimeRight = GetValveTimes(S.GUI.RewardAmount, 2);
    if currentTrialType == 1, valveTime = valveTimeLeft; rewardAction = {'Valve1', 1, 'BNC1', 1};
    else, valveTime = valveTimeRight; rewardAction = {'Valve4', 1, 'BNC1', 1}; end

    if S.GUI.NoiseTime ~= 0
        punishAction = {'HiFi1', ['P', 0], 'BNC1', 1};
    else
        punishAction = {'BNC1', 1};
    end

    if currentTrial == 1
        sma = NewStateMachine();
        sma = AddState(sma, 'Name', 'Barcode1', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'Barcode2'}, ...
            'OutputActions', {'BNC1', 1});
        sma = AddState(sma, 'Name', 'Barcode2', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'Barcode3'}, ...
            'OutputActions', {'BNC1', 0});
        sma = AddState(sma, 'Name', 'Barcode3', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'Barcode4'}, ...
            'OutputActions', {'BNC1', 1});
        sma = AddState(sma, 'Name', 'Barcode4', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'Barcode5'}, ...
            'OutputActions', {'BNC1', 0});
        sma = AddState(sma, 'Name', 'Barcode5', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'TrialStart'}, ...
            'OutputActions', {'BNC1', 0});
    else
        sma = NewStateMachine();
    end
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', ITI(currentTrial)/2, ...
        'StateChangeConditions', {'Tup', 'ShowCue'}, ...
        'OutputActions', startAction);
    sma = AddState(sma, 'Name', 'ShowCue', ...
        'Timer', CueTime, ...
        'StateChangeConditions', {'Tup', chooseState1}, ...
        'OutputActions', cueAction);
    sma = AddState(sma, 'Name', 'InitRE', ...
        'Timer', 0.2, ...
        'StateChangeConditions', {'RotaryEncoder1_3', chooseState2, 'RotaryEncoder1_4', chooseState2}, ...
        'OutputActions', {'RotaryEncoder1', [';' 4]});
    sma = AddState(sma, 'Name', 'GetSniffTemplate', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Flex1Trig1', 'DeliverStimTemplate'}, ...
        'OutputActions', {'PWM3', S.GUI.Intensity_cue});
    sma = AddState(sma, 'Name', 'DeliverStimTemplate', ...
        'Timer', S.GUI.StimTime, ...
        'StateChangeConditions', {'Tup', 'Delay'}, ...
        'OutputActions', stimTemplateAction);
    sma = AddState(sma, 'Name', 'Delay', ...
        'Timer', S.GUI.Delay, ...
        'StateChangeConditions', {'Tup', chooseStateMatch}, ...
        'OutputActions', delayAction);
    sma = AddState(sma, 'Name', 'GetSniffMatch', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Flex1Trig1', 'DeliverStimMatch'}, ...
        'OutputActions', {'PWM3', S.GUI.Intensity_cue});
    sma = AddState(sma, 'Name', 'DeliverStimMatch', ...
        'Timer', S.GUI.StimTime, ...
        'StateChangeConditions', {'Tup', 'GetResponse'}, ...
        'OutputActions', stimMatchAction);
    sma = AddState(sma, 'Name', 'GetResponse', ...
        'Timer', S.GUI.ResponseTime, ...
        'StateChangeConditions', responseDetect, ...
        'OutputActions', responseAction);
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', valveTime, ...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'}, ...
        'OutputActions', rewardAction);
    sma = AddState(sma, 'Name', 'Punishment', ...
        'Timer', S.GUI.NoiseTime, ...
        'StateChangeConditions', {'Tup', 'TimeOut'}, ...
        'OutputActions', punishAction);
    sma = AddState(sma, 'Name', 'TimeOut', ...
        'Timer', S.GUI.ErrorDelay - S.GUI.NoiseTime, ...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI(currentTrial)/2, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {});

    actions = struct();
    actions.TrialStart         = startAction;
    actions.ShowCue            = cueAction;
    actions.DeliverStimTemplate = stimTemplateAction;
    actions.DeliverStimMatch   = stimMatchAction;
    actions.GetResponse        = responseAction;
    actions.Reward             = rewardAction;
    actions.Punishment         = punishAction;
    actions.RewardValveTime    = valveTime;
end

function [action, code, needsSniff, rowIdx] = buildTemplateAction(S)
% buildTemplateAction returns the OutputActions cell, SoftCode (0 if
% none), whether a sniff-onset wait is required, and the selected row
% index (meaningful for Odour/Pattern; 1 otherwise) for delivering the
% Template stimulus per its configured modality. SoftCode 2 = Template
% Odour, SoftCode 9 = Template Pattern (see SoftCodeHandler_luminose_hf_MTS.m
% / dmd_hf_MTS.m / olfactometer_hf_MTS.m). rowIdx is reused by
% buildSampleAction's per-template checkbox lookup, and the action/code
% are replayed verbatim by PrepareStateMachine on Match trials.
    global BpodSystem
    Type = S.GUIMeta.TemplateType.String{S.GUI.TemplateType};
    action = {};
    code = 0;
    needsSniff = false;
    rowIdx = 1;
    switch Type
        case 'Odour'
            action = {'BNC2', 1};
            code = 2;
            rowIdx = drawWeightedRow(S.GUI.probs_Template);
            if ~isfield(BpodSystem.PluginObjects, 'SelectedOdourRow')
                BpodSystem.PluginObjects.SelectedOdourRow = struct();
            end
            BpodSystem.PluginObjects.SelectedOdourRow.Template = rowIdx;
        case 'Pattern'
            action = {'PWM3', S.GUI.Intensity_cue}; % mask
            code = 9;
            needsSniff = true;
            if isfield(BpodSystem.PluginObjects, 'SelectedPatternRow') && ...
               isfield(BpodSystem.PluginObjects.SelectedPatternRow, 'Template')
                rowIdx = BpodSystem.PluginObjects.SelectedPatternRow.Template;
            end
        case 'Light'
            action = {'PWM1', S.GUI.Intensity_Template};
        case 'Sound'
            action = {'HiFi1', ['P', 2]};
    end
end

function [action, code, needsSniff] = buildSampleAction(S, templateRowIdx)
% buildSampleAction returns the OutputActions cell, SoftCode (0 if none),
% and whether a sniff-onset wait is required, for delivering the Sample
% stimulus on a Non-match trial. SoftCode 3 = Sample Odour, SoftCode 10 =
% Sample Pattern. For Odour, the delivered row is drawn uniformly from
% the Sample rows checked for templateRowIdx in 'templateMask_Sample'
% (falling back to all rows if none are checked for that column).
    global BpodSystem
    Type = S.GUIMeta.SampleType.String{S.GUI.SampleType};
    action = {};
    code = 0;
    needsSniff = false;
    switch Type
        case 'Odour'
            action = {'BNC2', 1};
            code = 3;
            nRows = size(S.GUI.valves_Sample, 1);
            mask = S.GUI.templateMask_Sample;
            col = min(max(templateRowIdx, 1), size(mask, 2));
            candidates = find(mask(1:nRows, col));
            if isempty(candidates)
                candidates = 1:nRows;
            end
            rowIdx = candidates(randi(numel(candidates)));
            if ~isfield(BpodSystem.PluginObjects, 'SelectedOdourRow')
                BpodSystem.PluginObjects.SelectedOdourRow = struct();
            end
            BpodSystem.PluginObjects.SelectedOdourRow.Sample = rowIdx;
        case 'Pattern'
            action = {'PWM3', S.GUI.Intensity_cue}; % mask
            code = 10;
            needsSniff = true;
        case 'Light'
            action = {'PWM4', S.GUI.Intensity_Sample};
        case 'Sound'
            action = {'HiFi1', ['P', 3]};
    end
end

function rowIdx = drawWeightedRow(weights)
    weights = max(weights, 0);
    if sum(weights) > 0
        rowIdx = find(rand() <= cumsum(weights/sum(weights)), 1);
    else
        rowIdx = 1;
    end
end

function shouldStop = handle_pause_condition(H, R)
    global BpodSystem
    HandlePauseCondition;
    shouldStop = (BpodSystem.Status.BeingUsed == 0);
    if shouldStop
        H.stop;
        R.stopUSBStream;
    end
end

function cleanup()
    global BpodSystem S luminose sniffDetector %#ok<NUSED>
    clear dmd_hf_MTS;
    BpodSystem.Data.luminose = luminose;
    BpodSystem.ProtocolSettings = S;
    SaveBpodSessionData;
    SaveBpodProtocolSettings;
    diary off;
end

function restorePatternParams(typeNames, patternsFolder)
    global S BpodSystem
    patternsFolder = char(patternsFolder);
    for i = 1:numel(typeNames)
        t = typeNames{i};
        allMetas = dir(fullfile(patternsFolder, sprintf('designed_%s_*_meta.mat', t)));
        if isempty(allMetas), continue; end

        isRowFile = arrayfun(@(m) ~isempty(regexp(m.name, ...
            sprintf('designed_%s_r\\d+_', t), 'once')), allMetas);
        rowMetas    = allMetas(isRowFile);
        legacyMetas = allMetas(~isRowFile);

        rowIndices = [];
        for j = 1:numel(rowMetas)
            tok = regexp(rowMetas(j).name, sprintf('designed_%s_r(\\d+)_', t), 'tokens', 'once');
            if ~isempty(tok), rowIndices(end+1) = str2double(tok{1}); end %#ok<AGROW>
        end
        rowIndices = unique(rowIndices);
        if ~ismember(1, rowIndices) && ~isempty(legacyMetas)
            rowIndices = [1, rowIndices];
        end
        if isempty(rowIndices), continue; end

        maxRow = max(rowIndices);
        nFVec   = S.GUI.(sprintf('patternNFrames_%s',  t));
        expVec  = S.GUI.(sprintf('patternExposure_%s', t));
        probVec = S.GUI.(sprintf('patternProbs_%s',    t));
        while numel(nFVec)   < maxRow, nFVec(end+1)   = 1;   end
        while numel(expVec)  < maxRow, expVec(end+1)  = 1e6; end
        while numel(probVec) < maxRow, probVec(end+1) = 0;   end

        if ~isfield(BpodSystem.PluginObjects, 'PatternDesigns')
            BpodSystem.PluginObjects.PatternDesigns = struct();
        end
        if ~isfield(BpodSystem.PluginObjects.PatternDesigns, t)
            BpodSystem.PluginObjects.PatternDesigns.(t) = {};
        end

        for rowIdx = rowIndices
            rMetas = rowMetas(arrayfun(@(m) ~isempty(regexp(m.name, ...
                sprintf('designed_%s_r%d_', t, rowIdx), 'once')), rowMetas));
            if isempty(rMetas) && rowIdx == 1
                rMetas = legacyMetas;
            end
            if isempty(rMetas), continue; end
            [~, newest] = max([rMetas.datenum]);
            try
                m = load(fullfile(patternsFolder, rMetas(newest).name));
                if ~isfield(m, 'tickMs'), continue; end
                if isfield(m, 'nF')
                    nF = m.nF;
                else
                    totalDur = max([m.spots.onset_ms] + [m.spots.dur_ms]);
                    nF = ceil(totalDur / m.tickMs);
                end
                nFVec(rowIdx)  = nF;
                expVec(rowIdx) = m.tickMs * 1000;
                BpodSystem.PluginObjects.PatternDesigns.(t){rowIdx} = ...
                    struct('spots', m.spots, 'tickMs', m.tickMs, 'r_px', m.r_px, 'nF', nF);
                fprintf('Restored %s row %d: %d frames, tick=%.1fms\n', t, rowIdx, nF, m.tickMs);
            catch
            end
        end

        probVec(:) = 1 / numel(probVec);
        S.GUI.(sprintf('patternNFrames_%s',  t)) = nFVec;
        S.GUI.(sprintf('patternExposure_%s', t)) = expVec;
        S.GUI.(sprintf('patternProbs_%s',    t)) = probVec;
    end
end

function SaveOnlinePlots()
    global BpodSystem
    dataFile = BpodSystem.Path.CurrentDataFile;
    savePath = fileparts(dataFile);
    [~, sessionName] = fileparts(dataFile);
    figNames = {'OutcomePlot', 'AccuracyPlot', 'RewardPlot', 'ResponsePlot', 'EncoderPlotFig'};
    for i = 1:length(figNames)
        try
            fig = BpodSystem.ProtocolFigures.(figNames{i});
            fname = fullfile(savePath, [sessionName '_' figNames{i} '.png']);
            saveas(fig, fname)
        catch
        end
    end
end
