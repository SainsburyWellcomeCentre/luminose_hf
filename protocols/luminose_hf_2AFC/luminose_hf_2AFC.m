function luminose_hf_2AFC
    %% clear & setup
    clc;

    global BpodSystem S luminose dmdModel olfModel
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_2AFC';
    ManualOverride('OP', 5);

    %% Define luminose constants
    % Add folders and save path
    luminose = LuminoseConstants();
    
    % Display confirmation
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
    
    dmdModel = DMDmodel(luminose.dmd);
    olfModel = OlfactometerModel(luminose.olfactometer, true);

    %% Launch bonsai
    % Ask user whether to launch Bonsai
    choice = questdlg('Launch Bonsai workflow?', ...
        'Launch Bonsai', ...
        'Yes', 'No', 'Yes');   % default = Yes
    launchBonsai = strcmp(choice, 'Yes');

    if luminose.bonsai.launch_bonsai && launchBonsai
        currentDataFile = split(BpodSystem.Path.CurrentDataFile, '\');
        currentFilePrefix = currentDataFile{end}; 
        luminose.bonsai.currentFilePrefix = currentFilePrefix(1:end-4);
        luminose.bonsai.dataPath = fullfile(join(currentDataFile(1:end-2), '\'), 'Session Videos');
        launch_bonsai(luminose.bonsai.exePath, luminose.bonsai.workflowPath, luminose.bonsai.dataPath, luminose.bonsai.currentFilePrefix);
    end

    %% Configure trials
    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_luminose_hf_2AFC();
    end
    % Initialize parameter GUI plugin
    LuminoseParameterGUI_hf_2AFC('init', S);
    % Wait for Start button press
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return  % GUI was closed
        end
    end
    S = LuminoseParameterGUI_hf_2AFC('sync', S);
    disp('START pressed — beginning experiment.');

    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
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
        ITI = S.GUI.InterTrialInterval * (1.01 .^ (0:S.GUI.maxTrials-1)); % Generate incremental ITI values using a geometric progression
        ITI(ITI > S.GUI.MaxITI) = S.GUI.MaxITI; % Enforce maximum ITI duration for all trials
        ITI = ITI(randperm(length(ITI)))';
        ITI = round(ITI * 1000) / 1000;
    else
        % Constant CueDelay for all trials
        ITI = S.GUI.InterTrialInterval * ones(1, S.GUI.maxTrials);
    end

    %% Begin plotting
    % Live outcome plot
    BpodSystem.ProtocolFigures.OutcomePlot = figure('Position', [30 1035 1000 350], ...
        'name', 'Outcome Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.OutcomeAxes = axes('Position', [.06 .15 .92 .8]); 
    BpodSystem.GUIHandles.OutcomeAxes.LooseInset = BpodSystem.GUIHandles.OutcomeAxes.TightInset;
    liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);

    % Live accuracy bar plot
    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveBarPlot_hf_2AFC(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);
    
    % % Live psychometric curve
    % BpodSystem.ProtocolFigures.PsychometricPlot = figure('Position', [1400 645 450 350], ...
    %     'name', 'Psychometric Curve', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
    % BpodSystem.GUIHandles.PsychometricAxes = axes('Position', [.15 .15 .8 .75]);
    % livePsychometricPlot_hf_2AFC(BpodSystem.GUIHandles.PsychometricAxes, 'init', [], [1]);

    % Live reward monitor
    BpodSystem.ProtocolFigures.RewardPlot = figure('Position', [1040 645 350 350], ...
        'name', 'Reward Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.RewardAxes = axes('Position', [.15 .12 .8 .8]);
    liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'init', []);
    
    % Live response time plot
    BpodSystem.ProtocolFigures.ResponsePlot = figure('Position', [1400 645 350 350], ...
        'name', 'Response Time Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.ResponseAxes = axes('Position', [.15 .12 .8 .8]);
    liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'init', []);

    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 

    %% Configure bpod
    emulator = BpodSystem.EmulatorMode == 1;
    if ~emulator
        %% Configure Flex I/O Channels
        chanSniff = 1; chanPhotodetector = 2; chanFlowmeter = 3; chanNIDAQ = 4;
        channelTypes(1:4) = 4; % Disabled
        channelTypes(chanSniff) = 2; % Analog Input
        channelTypes(chanPhotodetector) = 2; % Analog Input
        channelTypes(chanFlowmeter) = 2; % Analog Input
        channelTypes(chanNIDAQ) = 2; 
        BpodSystem.FlexIOConfig.channelTypes = channelTypes;
        
        % Set sniff threshold for inhalation triggered stimulus
        BpodSystem.FlexIOConfig.threshold1(chanSniff) = 0.5;
        BpodSystem.FlexIOConfig.polarity1(chanSniff) = 1;
        BpodSystem.FlexIOConfig.thresholdMode(chanSniff) = 0;

        % Set sampling rate 
        BpodSystem.FlexIOConfig.analogSamplingRate = 100; % Sampling rate
        
        % Initialize analog viewer GUI (online monitor of FlexIO analog inputs, not necessary for data logging)
        BpodSystem.startAnalogViewer; 
        flexioPos = get(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position');
        flexioPos(1:2) = [30, 65];
        set(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position', flexioPos);

        %% Assert modules are USB-paired
        % BpodSystem.assertModule({'HiFi','RotaryEncoder', 'AnalogIn'}, [1 1 1]); 
        % BpodSystem.assertModule({'HiFi','RotaryEncoder'}, [1 1]); 
    
        H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
        R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1); 
        % A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
    
        if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
            error('Error: This protocol requires rotary encoder module v2 or newer');
        end

        %% Setup sound
        % Configure HiFi module
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

        H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 63; % Ignored if using HD version of the HiFi module
        H.DigitalAttenuation_dB = -60; % Set a negative value here if necessary for digital volume control.

        H.push; % Add any recently loaded sounds to the current sound set

        % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
        Envelope = 1/(sf*0.001):1/(sf*0.001):1; 
        H.AMenvelope = Envelope;
    
        %% Setup Rotary Encoder module
        if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
            R.useAdvancedThresholds = 'on'; % Advanced thresholds are available on rotary encoder module r2.0 or newer.
                                % See notes in setAdvancedThresholds() function in /Modules/RotaryEncoderModule.m for parameters and usage
            R.setAdvancedThresholds([-35 35 10],... 
                [0 0 1], [0 0 0.2]); % Syntax: setAdvancedThresholds(thresholds, thresholdTypes, thresholdTimes)
            R.sendThresholdEvents = 'on'; % Enable sending threshold crossing events to state machine
        else
            R.useAdvancedThresholds = 'off';
        end
        R.startUSBStream; % Begin streaming position data to PC via USB
        BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [1400 1035 350 350],'name','Encoder plot',...
                                                   'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
        BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
        liveEncoderPlot_hf_2AFC(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

        %% Setup analog input modulegetNext
        % A.InputRange(1:3) = {'-5V:5V', '-5V:5V', '-2.5V:2.5V'}; % set range to -5V:5V
        % A.SamplingRate = 1000; % Hz
        % A.nActiveChannels = 0; 
        % A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
        % A.DIOconfig(1:2) = 1;
        % A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
        % A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
        % A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
        % A.startReportingEvents; % Enable threshold event signaling
        % behaviorDataFile = BpodSystem.Path.CurrentDataFile;
        % A.USBStreamFile = [behaviorDataFile(1:end-4) '_StimFeedback.mat']; % Set datafile for analog data captured in this session
        % A.scope; % Launch Scope GUI
        % A.scope_StartStop; % Start USB streaming + data logging
        
        
        %% Prepare and start first trial
        ManualOverride('OP', 5);
        if strcmp(cue, 'Odour') % currently coded such that cue and stim cannot both be odours at the same trial 
            SoftCodeHandler_luminose_hf_2AFC(1);
        elseif any([strcmp(Left, 'Odour'), strcmp(Right, 'Odour')])
            SoftCodeHandler_luminose_hf_2AFC(currentTrialType + 1);
        end
        trialManager = BpodTrialManager;
        sma = PrepareStateMachine(S, currentTrialType, 1, ITI, emulator); % Prepare state machine for trial 1 with empty "current events" variable
        sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS'); disp(['Session: ', sessionStart, ' | Trial: ', num2str(1)]);
        trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                                  % console UI, while code below proceeds in parallel.
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                t1 = tic;
                S = LuminoseParameterGUI_hf_2AFC('sync', S); % Sync parameters with LuminoseParameterGUI_hf_2AFC plugin
                currentTrialType = nextTrialType;
                if currentTrial >= 20
                    nextTrialType = getNextTrialType_hf_2AFC(BpodSystem.Data, 50, S.GUI.BiasCorrection, 0.2, S.GUI.Leftprob);
                else
                    nextTrialType = (rand < S.GUI.Leftprob) + 1;
                end
                disp(['calculated next trial: ', num2str(toc(t1))]);

                handle_pause_condition(H, R); % Handle pause/stop by user
                
                if currentTrial < S.GUI.maxTrials
                    [sma, S] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI, emulator);
                    disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial+1)]);
                    SendStateMachine(sma, 'RunASAP');
                end
                
                RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
                handle_pause_condition(H, R); % Handle pause/stop by user
                
                t2 = tic;
                if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
                    R.setAdvancedThresholds([-35 35 10], [0 0 1],... 
                        [0 0 0.2]);
                end
                disp(['set RE: ', num2str(toc(t2))]);

                if currentTrial < S.GUI.maxTrials
                    trialManager.startTrial(); % Start processing the next trial's events (call with no argument since SM was already sent)
                end
                
                if ~isempty(fieldnames(RawEvents))
                    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
                    BpodSystem.Data.TrialSettings(currentTrial) = S;
                    BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                    BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        
                    % Save rotary encoder data
                    if currentTrial == 1
                        eventData = R.readUSBStream(0); % Read and dump any REM data captured before first trial start. Subsequent REM data will be saved. 
                        TrialStartTime = eventData.EventTimestamps(1); % First trial start time on REM clock is taken from this initial read
                    end
                    BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0); % Returns REM data up to event '0'
                                                                                    % see {'RotaryEncoder1', ['#' 0]} in output actions of first state 
                    BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                        BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - BpodSystem.Data.TrialStartTimestamp(currentTrial) ;
        
                    %% Update plots  
                    t3 = tic;
                    liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                    disp(['Updated outcome plot: ', num2str(toc(t3))]);

                    t4 = tic;
                    liveBarPlot_hf_2AFC(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                    disp(['Updated bar plot: ', num2str(toc(t4))]);

                    % livePsychometricPlot_hf_2AFC(BpodSystem.GUIHandles.PsychometricAxes, 'update', ...
                    %     BpodSystem.Data, [1]);
                    t5 = tic;
                    liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                    disp(['Updated reward plot: ', num2str(toc(t5))]);

                    t6 = tic;
                    liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                    disp(['Updated response time plot: ', num2str(toc(t6))]);

                    t7 = tic;
                    % Update rotary encoder plot
                    if currentTrial == 1 % Only on the first trial, the first and second trial's trial-start timestamps will be retrieved in the rotary encoder data
                                         % On all subsequent trials, only the next trial's start timestamp will be returned (because data is retrieved mid-trial)
                        % For first trial, TrialStartTime is computed above
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    else
                        TrialStartTime = NextTrialStartTime;
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    end
                    BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime; % Align timestamps to state machine's trial time 0
                    BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                        BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime; % Align event timestamps to state machine's trial time 0
                    
                    TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    
                    liveEncoderPlot_hf_2AFC(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial},TrialDuration);
                    disp(['Updated rotary encoder plot: ', num2str(toc(t7))]);
                    
                    t8 = tic;
                    SaveBpodSessionData;
                    SaveOnlinePlots;
                    disp(['Saved data: ', num2str(toc(t8))]);
                end
            catch
                cleanup; % Save FlexI/O analog input data
                ManualOverride('OP', 5);
                break
            end
        end
    else % emulator mode
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                S = LuminoseParameterGUI_hf_2AFC('sync', S); % Sync parameters with LuminoseParameterGUI_hf_2AFC plugin
                
                currentTrialType = nextTrialType;
                nextTrialType = getNextTrialType_hf_2AFC(BpodSystem.Data, 50, S.GUI.BiasCorrection, 0.2, S.GUI.Leftprob);
    
                sma = PrepareStateMachine(S, currentTrialType, currentTrial+1, ITI, [], emulator);
                SendStateMachine(sma);
                RawEvents = RunStateMachine; % Run the trial and return events
    
                if ~isempty(fieldnames(RawEvents))
                    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
                    BpodSystem.Data.TrialSettings(currentTrial) = S;
                    BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                    BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
    
                    % Update plots
                    TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    
                    liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
    
                    liveBarPlot_hf_2AFC(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                    
                    % livePsychometricPlot_hf_2AFC(BpodSystem.GUIHandles.PsychometricAxes, 'update', ...
                    %     BpodSystem.Data, [1]);
    
                    liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                    
                    liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                end
                HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
                if BpodSystem.Status.BeingUsed == 0 % If protocol was stopped, exit the loop
                    return
                end
            catch
                cleanup; % Save FlexI/O analog input data
                ManualOverride('OP', 5);
                break
            end
        end
    end
end

%% State machine 
function [sma, S] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI, emulator)
    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    Left = S.GUIMeta.LeftType.String{S.GUI.LeftType};
    Right = S.GUIMeta.RightType.String{S.GUI.RightType};   
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType}; 
    
    % analog input module: 'Serial3', ['=' 1 'High'], 'Serial3', ['=' 0 'High']
    startAction = {'BNC1', 1}; % sync
    if ~emulator
        startAction{end+1} = 'HiFi1'; startAction{end+1} = '*';
        startAction{end+1} = 'RotaryEncoder1'; startAction{end+1} = ['#' 0];
        startAction{end+1} = 'AnalogThreshEnable'; startAction{end+1} = 1;
        % startAction{end+1} = 'Serial3'; startAction{end+1} = ['#' 1]; % analog input module sync
    end
    cueAction = {'RotaryEncoder1', '*Z'};
    startAction = {}; % send odour info to olfactometer and wait for BNC2 trigger
    switch cue
        case 'Odour'
            cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
            switch S.GUI.TrainingLevel
                case 1 % Habituation
                    startAction = {}; 
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
                        case 1 % Habituation
                            startAction = {}; 
                        case 2 % Training
                            startAction{end+1} = 'SoftCode'; startAction{end+1} = 2;
                    end
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 9;
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Light'
                    stimAction{end+1} = 'PWM1'; stimAction{end+1} = S.GUI.Intensity_Left;
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 2];
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
            end
            switch S.GUI.TrainingLevel
                case 1
                    leftAction = 'Reward'; rightAction = 'Reward'; noAction = 'GetResponse';
                case 2
                    leftAction = 'Reward'; rightAction = 'Punishment'; noAction = 'Punishment';
            end
        case 2 % Right
            rewardAction{end+1} = 'Valve4'; rewardAction{end+1} = 1;
            switch Right
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            startAction = {}; 
                        case 2 % Training
                            startAction{end+1} = 'SoftCode'; startAction{end+1} = 3;
                    end
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 10;
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Light'
                    stimAction{end+1} = 'PWM4'; stimAction{end+1} = S.GUI.Intensity_Right;
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 3];
                    switch S.GUI.TrainingLevel
                        case 1 % Habituation
                            chooseState2 = 'GetResponse';
                        case 2 % Training
                            chooseState2 = 'DeliverStim';
                    end
            end
            switch S.GUI.TrainingLevel
                case 1
                    leftAction = 'Reward'; rightAction = 'Reward'; noAction = 'GetResponse';
                case 2
                    leftAction = 'Punishment'; rightAction = 'Reward'; noAction = 'Punishment';
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
    
    switch emulator
        case true
            %%
            if currentTrial == 1
                sma = NewStateMachine();
                % unique barcode sent to identify protocol in first trial
                sma = AddState(sma, 'Name', 'Barcode1', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode2'},...
                'OutputActions', {'BNC1', 1}); 
        
                sma = AddState(sma, 'Name', 'Barcode2', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode3'},...
                'OutputActions', {'BNC1', 0}); 
        
                sma = AddState(sma, 'Name', 'Barcode3', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode4'},...
                'OutputActions', {'BNC1', 1}); 
        
                sma = AddState(sma, 'Name', 'Barcode4', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode5'},...
                'OutputActions', {'BNC1', 0}); 
        
                sma = AddState(sma, 'Name', 'Barcode5', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 1}); 
            else
                sma = NewStateMachine();
            end
            %%
            sma = AddState(sma, 'Name', 'TrialStart', ...
                'Timer', S.GUI.CueTime,...
                'StateChangeConditions', {'Tup', 'DeliverStim'},...
                'OutputActions', {'PWM1', S.GUI.Intensity_cue}); % light on
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'GetResponse'},...
                'OutputActions', {'PWM2', S.GUI.Intensity_cue}); % light on
            sma = AddState(sma, 'Name', 'GetResponse', ...
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', {'Port2In', goAction, 'Port3In', noGoAction, 'Tup', noGoAction},...
                'OutputActions', {'PWM3', S.GUI.Intensity_cue});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', valveTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', rewardAction); 
            sma = AddState(sma, 'Name', 'Punishment', ...
                'Timer', S.GUI.NoiseTime,...
                'StateChangeConditions', {'Tup', 'TimeOut'},...
                'OutputActions', {}); 
            sma = AddState(sma, 'Name', 'TimeOut', ...
                'Timer', errorDelay - noiseTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
        case false
            %%
            if currentTrial == 1
                sma = NewStateMachine();
                % unique barcode sent to identify protocol in first trial
                sma = AddState(sma, 'Name', 'Barcode1', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode2'},...
                'OutputActions', {'BNC1', 1}); 
        
                sma = AddState(sma, 'Name', 'Barcode2', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode3'},...
                'OutputActions', {'BNC1', 0}); 
        
                sma = AddState(sma, 'Name', 'Barcode3', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode4'},...
                'OutputActions', {'BNC1', 1}); 
        
                sma = AddState(sma, 'Name', 'Barcode4', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode5'},...
                'OutputActions', {'BNC1', 0}); 
        
                sma = AddState(sma, 'Name', 'Barcode5', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 1}); 
            else
                sma = NewStateMachine();
            end
            %%
            sma = AddState(sma, 'Name', 'TrialStart', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'ShowCue'},...
                'OutputActions', startAction); % light on
            sma = AddState(sma, 'Name', 'ShowCue', ... % Turn on LED of port1. Wait for InitDelay seconds. Ensure that wheel does not move.
                'Timer', S.GUI.CueTime,...
                'StateChangeConditions', {'Tup', chooseState1},...
                'OutputActions', cueAction); % '*' = push new thresholds to rotary encoder 'Z' = zero position
            sma = AddState(sma, 'Name', 'InitRE', ...
                'Timer', 0.2,...
                'StateChangeConditions', {'RotaryEncoder1_3', chooseState2, 'RotaryEncoder1_4', chooseState2},...
                'OutputActions', {'RotaryEncoder1', [';' 4]}); % ';' = enable thresholds specified by bits of a byte. 4 = binary 100 (enable threshold# 3)  
            sma = AddState(sma, 'Name', 'GetSniff', ...
                'Timer', 0, ...
                'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'}, ...
                'OutputActions', {'BNC1', 1});
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'GetResponse'},...
                'OutputActions', stimAction); % light on
            sma = AddState(sma, 'Name', 'GetResponse', ...
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', responseDetect,...
                'OutputActions', responseAction);
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', valveTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', rewardAction); 
            sma = AddState(sma, 'Name', 'Punishment', ...
                'Timer', noiseTime,...
                'StateChangeConditions', {'Tup', 'TimeOut'},...
                'OutputActions', punishAction); 
            sma = AddState(sma, 'Name', 'TimeOut', ...
                'Timer', errorDelay - noiseTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
    end
end

%% Handle pause condition
% function handle_pause_condition(H, R, A)
function handle_pause_condition(H, R)
    global BpodSystem
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            % A.stopUSBStream;
            % A.scope_StartStop; % Stop Oscope GUI
            % A.endAcq; % Close Oscope GUI
            % A.stopReportingEvents; % Stop sending events to state machine
            return
    end
end

%% Cleanup
function cleanup()
    global BpodSystem
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1); % Save FlexI/O analog input data
    SaveBpodSessionData;
    % SaveBpodProtocolSettings;
    % A.endAcq; % Close Oscope GUI
    % A.stopReportingEvents; % Stop sending events to state machine
end

%% Save online plots
function SaveOnlinePlots()
    global BpodSystem

    % Get full path of the session file
    dataFile = BpodSystem.Path.CurrentDataFile;

    % Extract folder where the data file is saved
    savePath = fileparts(dataFile);

    % Get session name without extension
    [~, sessionName, ~] = fileparts(dataFile);
    % sessionName = regexprep(sessionName, '_\d{6}$', '');
    figNames = {'OutcomePlot', 'AccuracyPlot', 'RewardPlot', 'ResponsePlot'};

    for i = 1:numel(figNames)
        try
            fig = BpodSystem.ProtocolFigures.(figNames{i});  % get the figure handle
            fname = fullfile(savePath, [sessionName '_' figNames{i} '.png']);
            saveas(fig, fname)
        catch
            warning('Could not save figure %s', figNames{i})
        end
    end
end