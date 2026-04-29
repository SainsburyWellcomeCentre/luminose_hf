function luminose_hf_2AFC
    %% clear & setup
    clc;
    warning('off', 'MATLAB:HandleGraphics:ObsoleteProperty:JavaFrame');

    global BpodSystem S luminose
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_2AFC';
    [dataDir, dataBasename, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
    log_file = fullfile(dataDir, [regexprep(dataBasename, '_Session\d+$', '') '_log.txt']);
    diary(log_file);

    %% Configure trials
    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_luminose_hf_2AFC();
    end
    LuminoseParameterGUI_hf_2AFC('init', S);
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return
        end
    end
    S.GUI = BpodSystem.GUIData.ParameterGUI.LatestGUIParams;
    S = LuminoseParameterGUI_hf_2AFC('sync', S);
    disp('START pressed — beginning experiment.');

    BpodSystem.Data.Custom.TrialSide = [];
    BpodSystem.Data.Custom.TrialResponse = [];
    BpodSystem.Data.Custom.TrialOutcome = [];
    BpodSystem.Data.Custom.TrialType = [];

    nextTrialType = getNextTrialType_hf_2AFC(BpodSystem.Data, S);
    currentTrialType = nextTrialType;

    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    Left = S.GUIMeta.LeftType.String{S.GUI.LeftType};
    Right = S.GUIMeta.RightType.String{S.GUI.RightType};

    if S.GUI.VariableITI
        ITI = S.GUI.InterTrialInterval * (1.01 .^ (0:S.GUI.maxTrials-1));
        ITI(ITI > S.GUI.MaxITI) = S.GUI.MaxITI;
        ITI = ITI(randperm(length(ITI)))';
        ITI = round(ITI * 1000) / 1000;
    else
        ITI = S.GUI.InterTrialInterval * ones(1, S.GUI.maxTrials);
    end

    %% Begin plotting
    BpodSystem.ProtocolFigures.OutcomePlot = figure('Position', [30 1035 1000 350], ...
        'name', 'Outcome Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.OutcomeAxes = axes('Position', [.06 .15 .92 .8]);
    BpodSystem.GUIHandles.OutcomeAxes.LooseInset = BpodSystem.GUIHandles.OutcomeAxes.TightInset;
    liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);

    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveAccuracyPlot_hf_2AFC(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);

    BpodSystem.ProtocolFigures.RewardPlot = figure('Position', [1040 645 350 350], ...
        'name', 'Reward Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.RewardAxes = axes('Position', [.15 .12 .8 .8]);
    liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'init', []);

    BpodSystem.ProtocolFigures.ResponsePlot = figure('Position', [1400 645 350 350], ...
        'name', 'Response Time Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.ResponseAxes = axes('Position', [.15 .12 .8 .8]);
    liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'init', []);

    BpodSystem.ProtocolFigures.EncoderPlot = figure('Position', [1400 1035 350 350], ...
        'name', 'Encoder Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    liveEncoderPlot_hf_2AFC(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

    BpodNotebook('init');

    %% Configure Flex I/O Channels
    chanSniff = 1; chanPhotodetector = 2; chanFlowmeter = 3; chanNIDAQ = 4;
    channelTypes(1:4) = 4; % Disabled
    channelTypes(chanSniff) = 2; % Analog Input
    channelTypes(chanPhotodetector) = 2; % Analog Input
    channelTypes(chanFlowmeter) = 2; % Analog Input
    channelTypes(chanNIDAQ) = 2; % Digital Input
    BpodSystem.FlexIOConfig.channelTypes = channelTypes;

    BpodSystem.FlexIOConfig.threshold1(chanSniff) = 0.5;
    BpodSystem.FlexIOConfig.polarity1(chanSniff) = 1;
    BpodSystem.FlexIOConfig.thresholdMode(chanSniff) = 0;
    BpodSystem.FlexIOConfig.analogSamplingRate = 500;

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
    TimeSoundLeft = 0:1/sf:S.GUI.StimTime;
    LeftSound = chirp(TimeSoundLeft, S.GUI.LowFreq_Left, S.GUI.CueTime, S.GUI.HighFreq_Left);
    H.load(3, LeftSound);
    TimeSoundRight = 0:1/sf:S.GUI.StimTime;
    RightSound = chirp(TimeSoundRight, S.GUI.LowFreq_Right, S.GUI.CueTime, S.GUI.HighFreq_Right);
    H.load(4, RightSound);

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
    sma = PrepareStateMachine(S, currentTrialType, 1, ITI);
    sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
    trialManager.startTrial(sma);

    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        try
            t1 = tic;
            S = LuminoseParameterGUI_hf_2AFC('sync', S);

            currentTrialType = nextTrialType;
            BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
            BpodSystem.Data.Custom.TrialSide(currentTrial) = currentTrialType;
            BpodSystem.Data.Custom.TrialType(currentTrial) = currentTrialType;

            handle_pause_condition(H, R);

            if currentTrial < S.GUI.maxTrials
                nextTrialType = getNextTrialType_hf_2AFC(BpodSystem.Data, S);
                [sma, S] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI);
                disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                SendStateMachine(sma, 'RunASAP');
            end

            RawEvents = trialManager.getTrialData;
            handle_pause_condition(H, R);

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

                outcome = getTrialOutcome_hf_2AFC(BpodSystem.Data, currentTrial);
                BpodSystem.Data.Custom.TrialOutcome(currentTrial) = outcome;
                events = BpodSystem.Data.RawEvents.Trial{currentTrial}.Events;
                if isfield(events, 'BNC1High') && isfield(events, 'BNC2High')
                    if events.BNC1High(1) < events.BNC2High(1), BpodSystem.Data.Custom.TrialResponse(currentTrial) = 1;
                    else, BpodSystem.Data.Custom.TrialResponse(currentTrial) = 2; end
                elseif isfield(events, 'BNC1High'), BpodSystem.Data.Custom.TrialResponse(currentTrial) = 1;
                elseif isfield(events, 'BNC2High'), BpodSystem.Data.Custom.TrialResponse(currentTrial) = 2;
                else, BpodSystem.Data.Custom.TrialResponse(currentTrial) = NaN; end

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
                liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                disp(['Updated outcome plot: ', num2str(toc(t3))]);

                t4 = tic;
                liveAccuracyPlot_hf_2AFC(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                disp(['Updated accuracy plot: ', num2str(toc(t4))]);

                t5 = tic;
                liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                disp(['Updated reward plot: ', num2str(toc(t5))]);

                t6 = tic;
                liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
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
                liveEncoderPlot_hf_2AFC(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);
                disp(['Updated rotary encoder plot: ', num2str(toc(t7))]);

                t8 = tic;
                SaveBpodSessionData;
                SaveOnlinePlots;
                disp(['Saved data: ', num2str(toc(t8))]);
            end
        catch ME
            disp('=== CRASH ===');
            disp(ME.message);
            break
        end
    end
    cleanup;
end

%% State machine
function [sma, S] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI)
    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    Left = S.GUIMeta.LeftType.String{S.GUI.LeftType};
    Right = S.GUIMeta.RightType.String{S.GUI.RightType};
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType};

    startAction = {'BNC1', 1, 'HiFi1', '*', 'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1};
    cueAction = {'RotaryEncoder1', '*Z'};
    switch cue
        case 'Odour'
            cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
            startAction{end+1} = 'SoftCode'; startAction{end+1} = 1;
        case 'Pattern'
            cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
            startAction{end+1} = 'SoftCode'; startAction{end+1} = 8;
        case 'Light'
            cueAction{end+1} = 'PWM3'; cueAction{end+1} = S.GUI.Intensity_cue;
        case 'Sound'
            cueAction{end+1} = 'HiFi1'; cueAction{end+1} = ['P', 1];
    end
    stimAction = {'BNC1', 1}; % sync
    switch currentTrialType
        case 1 % Left
            switch Left
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 2;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 9;
                    chooseState2 = 'GetSniff';
                case 'Light'
                    stimAction{end+1} = 'PWM1'; stimAction{end+1} = S.GUI.Intensity_Left;
                    chooseState2 = 'DeliverStim';
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 2];
                    chooseState2 = 'DeliverStim';
            end
            leftAction = 'Reward'; rightAction = 'Punishment';
        case 2 % Right
            switch Right
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 3;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 10;
                    chooseState2 = 'GetSniff';
                case 'Light'
                    stimAction{end+1} = 'PWM2'; stimAction{end+1} = S.GUI.Intensity_Right;
                    chooseState2 = 'DeliverStim';
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 3];
                    chooseState2 = 'DeliverStim';
            end
            rightAction = 'Reward'; leftAction = 'Punishment';
    end
    responseDetect = {};
    responseAction = {};
    switch response
        case 'Lick'
            responseDetect = {'Port1In', leftAction, 'Port2In', rightAction, 'Tup', 'InterTrialInterval'};
            chooseState1 = chooseState2;
        case 'Rotary Encoder'
            responseDetect = {'RotaryEncoder1_1', leftAction, 'RotaryEncoder1_2', rightAction, 'Tup', 'InterTrialInterval'};
            chooseState1 = 'InitRE';
            responseAction{end+1} = 'RotaryEncoder1'; responseAction{end+1} = ['Z;' 3];
    end
    valveTimeLeft = GetValveTimes(S.GUI.RewardAmount, 1);
    valveTimeRight = GetValveTimes(S.GUI.RewardAmount, 2);
    if currentTrialType == 1, valveTime = valveTimeLeft; rewardAction = {'Valve1', 1, 'BNC1', 1};
    else, valveTime = valveTimeRight; rewardAction = {'Valve2', 1, 'BNC1', 1}; end

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
        'Timer', S.GUI.CueTime, ...
        'StateChangeConditions', {'Tup', chooseState1}, ...
        'OutputActions', cueAction);
    sma = AddState(sma, 'Name', 'InitRE', ...
        'Timer', 0.2, ...
        'StateChangeConditions', {'RotaryEncoder1_3', chooseState2, 'RotaryEncoder1_4', chooseState2}, ...
        'OutputActions', {'RotaryEncoder1', [';' 4]});
    sma = AddState(sma, 'Name', 'GetSniff', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStim', ...
        'Timer', S.GUI.StimTime, ...
        'StateChangeConditions', {'Tup', 'GetResponse'}, ...
        'OutputActions', stimAction);
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
end

function handle_pause_condition(H, R)
    global BpodSystem
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
        H.stop;
        R.stopUSBStream;
        return
    end
end

function cleanup()
    global BpodSystem luminose
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1);
    BpodSystem.Data.luminose = luminose;
    SaveBpodSessionData;
    diary off;
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
