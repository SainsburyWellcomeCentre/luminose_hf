function luminose_hf_sleep
    %% clear & setup
    clc;

    global BpodSystem S luminose
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_sleep';

    %% Define luminose constants
    luminose = LuminoseConstants();
    [dataDir, dataBasename, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
    log_file = fullfile(dataDir, [regexprep(dataBasename, '_Session\d+$', '') '_log.txt']);
    diary(log_file);

    disp('Luminose experiment initialized:');
    disp("=====  Folders =====");
    disp(luminose.f);
    disp("=====  Bpod =====");
    disp(luminose.bpod);
    disp("=====  Olfactometer =====");
    disp(luminose.olfactometer);
    disp("=====  DMD =====");
    disp(luminose.dmd);
    disp("=====  Bonsai =====");
    disp(luminose.bonsai);

    %% Launch bonsai
    launchBonsai = false;
    if luminose.bonsai.launch_bonsai
        choice = questdlg('Launch Bonsai workflow?', 'Launch Bonsai', 'Yes', 'No', 'Yes');
        launchBonsai = strcmp(choice, 'Yes');
    end

    if launchBonsai
        currentDataFile = split(BpodSystem.Path.CurrentDataFile, '\');
        currentFilePrefix = currentDataFile{end};
        luminose.bonsai.currentFilePrefix = currentFilePrefix(1:end-4);
        luminose.bonsai.dataPath = fullfile(join(currentDataFile(1:end-2), '\'), 'Session Videos');
        launch_bonsai(luminose.bonsai.exePath, luminose.bonsai.workflowPath, luminose.bonsai.dataPath, luminose.bonsai.currentFilePrefix);
    end

    %% Configure trials
    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_luminose_hf_sleep();
    end
    LuminoseParameterGUI_hf_sleep('init', S);
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return
        end
    end
    S.GUI = BpodSystem.GUIData.ParameterGUI.LatestGUIParams;
    S = LuminoseParameterGUI_hf_sleep('sync', S);
    disp('START pressed — beginning experiment.');

    trialTypes = 1 + (rand(1, S.GUI.maxTrials) >= S.GUI.Typeprob);
    BpodSystem.Data.TrialTypes = [];
    if S.GUI.TestPulses
        if S.GUI.TestPulsesType == 1
            stimTime = S.GUI.SPduration;
            if S.GUI.SPvariable
                ITI = (1 / S.GUI.SPfrequency) * (1.01 .^ (0:S.GUI.maxTrials-1));
                ITI(ITI > (1 / S.GUI.MaxSPfrequency)) = 1 / S.GUI.MaxSPfrequency;
                ITI = ITI(randperm(length(ITI)))';
                ITI = round(ITI * 1000) / 1000;
            else
                ITI = (1 / S.GUI.SPfrequency) * ones(1, S.GUI.maxTrials);
            end
        elseif S.GUI.TestPulsesType == 2
            stimTime = S.GUI.PPduration;
            if S.GUI.PPvariable
                ITI = (1 / S.GUI.PPfrequency) * (1.01 .^ (0:S.GUI.maxTrials-1));
                ITI(ITI > (1 / S.GUI.MaxPPfrequency)) = 1 / S.GUI.MaxPPfrequency;
                ITI = ITI(randperm(length(ITI)))';
                ITI = round(ITI * 1000) / 1000;
            else
                ITI = (1 / S.GUI.PPfrequency) * ones(1, S.GUI.maxTrials);
            end
        end
    else
        stimTime = 0;
        % Poisson ITI within [ITImin, ITImax]
        lambda = (S.GUI.ITImax - S.GUI.ITImin) / 2; % Target mean for the exponential part
        ITI = zeros(1, S.GUI.maxTrials);
        for i = 1:S.GUI.maxTrials
            val = S.GUI.ITImax + 1;
            while val > (S.GUI.ITImax - S.GUI.ITImin)
                val = exprnd(lambda);
            end
            ITI(i) = round(val + S.GUI.ITImin, 3);
        end
    end

    %% Begin plotting
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
    BpodSystem.assertModule({'RotaryEncoder'}, [1]);
    R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1);

    if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
        error('Error: This protocol requires rotary encoder module v2 or newer');
    end

    %% Setup Rotary Encoder module
    R.useAdvancedThresholds = 'off';
    R.startUSBStream;
    BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [1400 1035 350 350], 'name', 'Encoder plot', ...
        'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    liveEncoderPlot_hf_sleep(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

    %% Prepare and start first trial
    trialManager = BpodTrialManager;
    sessionStartTic = tic;
    sma = PrepareStateMachine(S, trialTypes, 1, stimTime, ITI, sessionStartTic);
    sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
    trialManager.startTrial(sma);

    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        try
            t1 = tic;
            S = LuminoseParameterGUI_hf_sleep('sync', S);

            currentTrialType = trialTypes(currentTrial);
            disp(['calculated next trial: ', num2str(toc(t1))]);

            handle_pause_condition(R);

            if currentTrial < S.GUI.maxTrials
                [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial+1, stimTime, ITI, sessionStartTic);
                disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                SendStateMachine(sma, 'RunASAP');
            end

            RawEvents = trialManager.getTrialData;
            handle_pause_condition(R);

            if currentTrial < S.GUI.maxTrials
                trialManager.startTrial();
            end

            if ~isempty(fieldnames(RawEvents))
                BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
                BpodSystem.Data.TrialSettings(currentTrial) = S;
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data);

                % Save rotary encoder data
                if currentTrial == 1
                    eventData = R.readUSBStream(0);
                    if ~isempty(eventData.EventTimestamps)
                        TrialStartTime = eventData.EventTimestamps(1);
                    else
                        TrialStartTime = 0;
                    end
                end
                BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0);

                %% Update plots
                t3 = tic;
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
                liveEncoderPlot_hf_sleep(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);
                disp(['Updated rotary encoder plot: ', num2str(toc(t3))]);

                t4 = tic;
                SaveBpodSessionData;
                disp(['Saved data: ', num2str(toc(t4))]);
            end
        catch ME
            disp('=== CRASH ===');
            disp(ME.message);
            disp(ME.stack(1));
            break
        end
    end
    cleanup;
end

%% State machine
function [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial, stimTime, ITI, sessionStartTic)

    onsetDelay = max(0, 600 - toc(sessionStartTic));

    startAction = {'GlobalTimerTrig', 1, 'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1};
    sniffAction = {'RotaryEncoder1', '*Z'};
    stimAction = {'BNC1', 1};
    if S.GUI.TestPulses
        switch trialTypes(currentTrial)
            case 1
                startAction{end+1} = 'SoftCode'; startAction{end+1} = 9;
            case 2
                startAction{end+1} = 'SoftCode'; startAction{end+1} = 10;
        end
        stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
        chooseState1 = 'GetSniff';
    else
        chooseState1 = 'InterTrialInterval';
    end

    if currentTrial == 1
        sma = NewStateMachine();
        sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', 18000, ...
            'OnsetDelay', onsetDelay, 'Channel', 'PWM5', 'OnMessage', 255, ...
            'OffMessage', 0, 'Loop', 0, 'SendGlobalTimerEvents', 0, 'LoopInterval', 0);
        % unique barcode sent to identify protocol in first trial
        sma = AddState(sma, 'Name', 'Barcode1', ...
            'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur), ...
            'StateChangeConditions', {'Tup', 'Barcode2'}, ...
            'OutputActions', {'BNC1', 1, 'GlobalTimerTrig', 1});
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
            'OutputActions', {'BNC1', 1});
    else
        sma = NewStateMachine();
        sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', 18000, ...
            'OnsetDelay', onsetDelay, 'Channel', 'PWM5', 'OnMessage', 255, ...
            'OffMessage', 0, 'Loop', 0, 'SendGlobalTimerEvents', 0, 'LoopInterval', 0);
    end
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', ITI(currentTrial)/2, ...
        'StateChangeConditions', {'Tup', chooseState1}, ...
        'OutputActions', startAction);
    sma = AddState(sma, 'Name', 'GetSniff', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'}, ...
        'OutputActions', sniffAction);
    sma = AddState(sma, 'Name', 'DeliverStim', ...
        'Timer', stimTime, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', stimAction);
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI(currentTrial)/2, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {'BNC1', 1});
end

%% Handle pause condition
function handle_pause_condition(R)
    global BpodSystem
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
        R.stopUSBStream;
        return
    end
end

%% Cleanup
function cleanup()
    global BpodSystem luminose
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1);
    BpodSystem.Data.luminose = luminose;
    SaveBpodSessionData;
    diary off;
end
