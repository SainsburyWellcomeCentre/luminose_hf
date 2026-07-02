function luminose_hf_playground
    %% clear & setup
    clc;
    warning('off', 'MATLAB:HandleGraphics:ObsoleteProperty:JavaFrame');

    global BpodSystem S luminose olfModel sniffDetector
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_playground';

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

    olfModel = OlfactometerModel(luminose.olfactometer, true);

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
    isNewSession = ~isstruct(S) || isempty(fieldnames(S));
    if isNewSession
        GUIparams_luminose_hf_playground();
        restorePatternParams({'cue', 'Left', 'Right', 'opto'}, luminose.dmd.patternsFolder);
    else
        % Refresh GUIMeta and GUIPanels from code, but merge S.GUI values from settings
        SavedGUI = S.GUI;
        GUIparams_luminose_hf_playground();
        fNames = fieldnames(SavedGUI);
        for i = 1:numel(fNames)
            if isfield(S.GUI, fNames{i})
                S.GUI.(fNames{i}) = SavedGUI.(fNames{i});
            end
        end
    end
    LuminoseParameterGUI_hf_playground('init', S);
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return
        end
    end
    S.GUI = BpodSystem.GUIData.ParameterGUI.LatestGUIParams;
    S = LuminoseParameterGUI_hf_playground('sync', S);
    disp('START pressed — beginning experiment.');

    BpodSystem.Data.TrialTypes = [];
    BpodSystem.Data.SniffInhalationOnset_s  = [];
    BpodSystem.Data.SniffInhalationOffset_s = [];
    if rand < S.GUI.Leftprob
        nextTrialType = 1;
    else
        nextTrialType = 2;
    end
    currentTrialType = nextTrialType;

    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    Left = S.GUIMeta.CueType.String{S.GUI.LeftType};
    Right = S.GUIMeta.CueType.String{S.GUI.RightType};

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
    liveOutcomePlot_hf_playground(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);

    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveAccuracyPlot_hf_playground(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);

    BpodSystem.ProtocolFigures.RewardPlot = figure('Position', [1040 645 350 350], ...
        'name', 'Reward Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.RewardAxes = axes('Position', [.15 .12 .8 .8]);
    liveRewardPlot_hf_playground(BpodSystem.GUIHandles.RewardAxes, 'init', []);

    BpodSystem.ProtocolFigures.ResponsePlot = figure('Position', [1400 645 350 350], ...
        'name', 'Response Time Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.ResponseAxes = axes('Position', [.15 .12 .8 .8]);
    liveResponseTimePlot_hf_playground(BpodSystem.GUIHandles.ResponseAxes, 'init', []);

    BpodNotebook('init');

    %% Configure Flex I/O Channels
    chanSniff = 1; chanPhotodetector = 2; chanFlowmeter = 3; chanNIDAQ = 4;
    channelTypes(1:4) = 4; % Disabled
    channelTypes(chanPhotodetector) = 2; % Analog Input
    channelTypes(chanFlowmeter) = 2; % Analog Input
    channelTypes(chanNIDAQ) = 2;
    BpodSystem.FlexIOConfig.channelTypes = channelTypes;
    BpodSystem.FlexIOConfig.analogSamplingRate = 500;

    % Thresholds come from the GUI (Trials → Sniff panel) so they can be tuned
    % per animal without touching code.  They are only used for FlexIO hardware
    % triggering; detectFromAnalog is fully adaptive and ignores them.
    sniffDetector = SniffDetector(chanSniff, 500);
    sniffDetector.risingEdge = logical(S.GUI.SniffRising);
    sniffDetector.configure(S.GUI.SniffOnsetThreshold, S.GUI.SniffOffsetThreshold);

    BpodSystem.startAnalogViewer;
    flexioPos = get(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position');
    flexioPos(1:2) = [30, 65];
    set(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position', flexioPos);

    %% Assert modules are USB-paired
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

    Envelope = 1/(sf*0.001):1/(sf*0.001):1;
    H.AMenvelope = Envelope;

    %% Setup Rotary Encoder module
    if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
        R.useAdvancedThresholds = 'on';
        R.setAdvancedThresholds([-35 35 10], [0 0 1], [0 0 0.2]);
        R.sendThresholdEvents = 'on';
    else
        R.useAdvancedThresholds = 'off';
    end
    R.startUSBStream;
    BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [1400 1035 350 350], 'name', 'Encoder plot', ...
        'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    liveEncoderPlot_hf_playground(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

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
            S = LuminoseParameterGUI_hf_playground('sync', S);
            currentTrialType = nextTrialType;

            nextTrialType = getNextTrialType_hf_playground(BpodSystem.Data, S.GUI);

            disp(['calculated next trial: ', num2str(toc(t1))]);

            if handle_pause_condition(H, R); break; end

            if currentTrial < S.GUI.maxTrials
                [sma, S, nextActions] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI);
                disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                SendStateMachine(sma, 'RunASAP');
            end

            RawEvents = trialManager.getTrialData;
            if handle_pause_condition(H, R); break; end

            t2 = tic;
            if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
                R.setAdvancedThresholds([-35 35 10], [0 0 1], [0 0 0.2]);
            end
            disp(['set RE: ', num2str(toc(t2))]);

            if currentTrial < S.GUI.maxTrials
                trialManager.startTrial();
            end

            if ~isempty(fieldnames(RawEvents))
                BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
                BpodSystem.Data.TrialSettings(currentTrial) = S;
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                BpodSystem.Data.RawEvents.Trial{currentTrial}.Actions = currentActions;

                processedEvents = BpodSystem.Data.RawEvents.Trial{currentTrial};
                BpodSystem.Data.SniffInhalationOnset_s(currentTrial)  = sniffDetector.getOnset(processedEvents);
                BpodSystem.Data.SniffInhalationOffset_s(currentTrial) = sniffDetector.getOffset(processedEvents);
                disp(['Sniff onset: ' num2str(BpodSystem.Data.SniffInhalationOnset_s(currentTrial), '%.3f') ...
                      ' s  offset: ' num2str(BpodSystem.Data.SniffInhalationOffset_s(currentTrial), '%.3f') ' s']);

                BpodSystem.Data = updateTrialData_hf_playground(BpodSystem.Data, currentTrial);

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
                liveOutcomePlot_hf_playground(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                disp(['Updated outcome plot: ', num2str(toc(t3))]);

                t4 = tic;
                liveAccuracyPlot_hf_playground(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                disp(['Updated bar plot: ', num2str(toc(t4))]);

                t5 = tic;
                liveRewardPlot_hf_playground(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                disp(['Updated reward plot: ', num2str(toc(t5))]);

                t6 = tic;
                liveResponseTimePlot_hf_playground(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
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
                liveEncoderPlot_hf_playground(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);
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
end

%% State machine
function [sma, S, actions] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI)
    global BpodSystem
    for tCell = {'cue', 'Left', 'Right', 'opto'}
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
    Left = S.GUIMeta.LeftType.String{S.GUI.LeftType};
    Right = S.GUIMeta.RightType.String{S.GUI.RightType};
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType};

    startAction = {'BNC1', 1, 'HiFi1', '*', 'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1};
    cueAction = {'RotaryEncoder1', '*Z'};
    switch cue
        case 'Odour'
            cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
            switch S.GUI.TrainingLevel
                case 1 % Habituation
                    % do nothing
                case 2 % Training
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 1;
            end
        case 'Pattern'
            cueAction{end+1} = 'SoftCode'; cueAction{end+1} = 8;
        case 'Light'
            cueAction{end+1} = 'PWM3'; cueAction{end+1} = S.GUI.Intensity_cue;
        case 'Sound'
            cueAction{end+1} = 'HiFi1'; cueAction{end+1} = ['P', 1];
    end
    stimAction = {'BNC1', 1}; rewardAction = {'BNC1', 1}; % sync
    switch currentTrialType
        case 1 % Left
            rewardAction{end+1} = 'Valve1'; rewardAction{end+1} = 1;
            switch Left
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    switch S.GUI.TrainingLevel
                        case 2, startAction{end+1} = 'SoftCode'; startAction{end+1} = 2;
                    end
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 9;
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'GetSniff';
                    end
                case 'Light'
                    stimAction{end+1} = 'PWM1'; stimAction{end+1} = S.GUI.Intensity_Left;
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 2];
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
            end
            switch S.GUI.TrainingLevel
                case 1, leftAction = 'Reward'; rightAction = 'Reward'; noAction = 'GetResponse';
                case 2, leftAction = 'Reward'; rightAction = 'Punishment'; noAction = 'Punishment';
            end
        case 2 % Right
            rewardAction{end+1} = 'Valve4'; rewardAction{end+1} = 1;
            switch Right
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    switch S.GUI.TrainingLevel
                        case 2, startAction{end+1} = 'SoftCode'; startAction{end+1} = 3;
                    end
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 10;
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'GetSniff';
                    end
                case 'Light'
                    stimAction{end+1} = 'PWM4'; stimAction{end+1} = S.GUI.Intensity_Right;
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 3];
                    switch S.GUI.TrainingLevel
                        case 1, chooseState2 = 'GetResponse';
                        case 2, chooseState2 = 'DeliverStim';
                    end
            end
            switch S.GUI.TrainingLevel
                case 1, leftAction = 'Reward'; rightAction = 'Reward'; noAction = 'GetResponse';
                case 2, leftAction = 'Punishment'; rightAction = 'Reward'; noAction = 'Punishment';
            end
    end
    responseDetect = {}; responseAction = {};
    switch response
        case 'Lick'
            responseDetect = {'BNC1High', leftAction, 'BNC2High', rightAction, 'Tup', noAction};
            chooseState1 = chooseState2;
        case 'Rotary Encoder'
            responseDetect = {'RotaryEncoder1_1', leftAction, 'RotaryEncoder1_2', rightAction, 'Tup', noAction};
            chooseState1 = 'InitRE';
            responseAction{end+1} = 'RotaryEncoder1'; responseAction{end+1} = ['Z;' 3];
    end
    responseAction{end+1} = 'SoftCode'; responseAction{end+1} = 11;
    valveTime = GetValveTimes(S.GUI.RewardAmount, 3);
    if S.GUI.Punishment
        errorDelay = S.GUI.ErrorDelay;
        noiseTime = S.GUI.NoiseTime;
        punishAction = {'HiFi1', ['P', 0], 'BNC1', 1};
    else
        errorDelay = 0;
        noiseTime = 0;
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
            'OutputActions', {'BNC1', 1});
    else
        sma = NewStateMachine();
    end
    if strcmp(S.GUIMeta.TestPulsesType.String{S.GUI.TestPulsesType}, 'PairedPulse')
        baseFreq = S.GUI.PPfrequency;
        if S.GUI.PPvariable && S.GUI.MaxPPfrequency > baseFreq
            optoFreq = baseFreq + rand() * (S.GUI.MaxPPfrequency - baseFreq);
        else
            optoFreq = baseFreq;
        end
    else
        baseFreq = S.GUI.SPfrequency;
        if S.GUI.SPvariable && S.GUI.MaxSPfrequency > baseFreq
            optoFreq = baseFreq + rand() * (S.GUI.MaxSPfrequency - baseFreq);
        else
            optoFreq = baseFreq;
        end
    end
    sma = SetGlobalTimer(sma, 'TimerID', 1, ...
        'Duration', 0.0001, 'OnsetDelay', 0, ...
        'Channel', 'SoftCode', 'OnMessage', 12, 'OffMessage', 0, ...
        'Loop', 1, 'LoopInterval', max(0.001, 1/optoFreq - 0.0001), 'SendEvents', 0);
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
        'OutputActions', {'BNC1', 1});
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
        'Timer', noiseTime, ...
        'StateChangeConditions', {'Tup', 'TimeOut'}, ...
        'OutputActions', punishAction);
    sma = AddState(sma, 'Name', 'TimeOut', ...
        'Timer', errorDelay - noiseTime, ...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'}, ...
        'OutputActions', {});
    if S.GUI.TestPulses
        iti_out = {'GlobalTimerTrig', 1};
    else
        iti_out = {};
    end
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI(currentTrial)/2, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', iti_out);

    actions = struct();
    actions.TrialStart   = startAction;
    actions.ShowCue      = cueAction;
    actions.DeliverStim  = stimAction;
    actions.GetResponse  = responseAction;
    actions.Reward       = rewardAction;
    actions.Punishment   = punishAction;
    actions.RewardValveTime = valveTime;
end

%% Handle pause condition
function shouldStop = handle_pause_condition(H, R)
    global BpodSystem
    HandlePauseCondition;
    shouldStop = (BpodSystem.Status.BeingUsed == 0);
    if shouldStop
        H.stop;
        R.stopUSBStream;
    end
end

%% Cleanup
function cleanup()
    global BpodSystem S luminose sniffDetector %#ok<NUSED>
    % Clearing the function releases the persistent dmd handle, allowing
    % the DMD destructor to free the ALP allocation before the next run.
    clear dmd_hf_playground;
    BpodSystem.Data.luminose = luminose;
    BpodSystem.ProtocolSettings = S;
    SaveBpodSessionData;
    SaveBpodProtocolSettings;
    diary off;
end

%% Save online plots
function SaveOnlinePlots()
    global BpodSystem
    dataFile = BpodSystem.Path.CurrentDataFile;
    savePath = fileparts(dataFile);
    [~, sessionName, ~] = fileparts(dataFile);
    figNames = {'OutcomePlot', 'AccuracyPlot', 'RewardPlot', 'ResponsePlot'};
    for i = 1:numel(figNames)
        try
            fig = BpodSystem.ProtocolFigures.(figNames{i});
            fname = fullfile(savePath, [sessionName '_' figNames{i} '.png']);
            saveas(fig, fname)
        catch
            warning('Could not save figure %s', figNames{i})
        end
    end
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
