function habituation_goNogo
    %% Set global variables and softcode handler function
    clc;
    global BpodSystem S
    beep('off'); % native matlab error sounds OFF

    %% Define luminose constants
    % Add folders and save path
    folders = LuminoseConstants.addFolders();
    % Load experiment configuration structs
    bpod = LuminoseConstants.addBpod();
    olfactometer = LuminoseConstants.addOlfactometer();
    dmd = LuminoseConstants.addDMD();
    bonsai = LuminoseConstants.addBonsai();
    
    % Display confirmation
    disp('Luminose experiment initialized:');
    disp("=====  Folders =====");
    disp(folders);
    disp("=====  Bpod =====");
    disp(bpod);
    disp("=====  Olfactometer =====");
    disp(olfactometer);
    disp("=====  DMD =====");
    disp(dmd);
    disp("=====  Bonsai =====");
    disp(bonsai);
    
    %% Launch bonsai
    currentDataFile = split(BpodSystem.Path.CurrentDataFile, '\');
    currentFilePrefix = currentDataFile(end); currentFilePrefix = currentFilePrefix(1:end-4);
    currentSubject = currentDataFile(end-2); 
    currentProtocol = currentDataFile(end-1);
    bonsai.dataPath = fullfile(folders.data, 'rawdata', currentSubject, currentProtocol, 'Session Videos');
    launch_bonsai(bonsai.exePath, bonsai.workflowPath, bonsai.dataPath, currentFilePrefix);

    %% Assert HiFi + Rotary Encoder +Analog Input modules are present + USB-paired (via USB button on console GUI)
    BpodSystem.assertModule({'RotaryEncoder', 'AnalogIn'}, [1 1]); 

    R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1); 
    A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);

    if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
        error('Error: This protocol requires rotary encoder module v2 or newer');
    end

    %% Configure trials 
    R.sendThresholdEvents = 'off';
    R.startUSBStream;

    trialManager = BpodTrialManager;

    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_habituation_goNogo();
    end
        
    BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [500 200 350 350],'name','Encoder plot',...
                                                   'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    last_trial_encoder_plot(BpodSystem.GUIHandles.EncoderAxes, 'init', 180);

    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 
    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    %% Configure Flex I/O Channels
    chanLick = 1; chanSniff = 3;
    channelTypes = ones(1, 4) * 4; % Disabled
    channelTypes([chanLick, chanSniff]) = 2; % Analog Input
    BpodSystem.FlexIOConfig.channelTypes = channelTypes;
    BpodSystem.FlexIOConfig.threshold1(chanLick) = 4; % In range 0-5
    BpodSystem.FlexIOConfig.polarity1(chanLick) = 0; % Polarity 0: Threshold activated when analog is > thresh
    BpodSystem.FlexIOConfig.thresholdMode(chanLick) = 0; % Mode 0: Thresholds must be manually re-enabled using the 'AnalogThreshEnable' output action.
    BpodSystem.FlexIOConfig.analogSamplingRate = 1000; % Sampling rate

    % Initialize analog viewer GUI (online monitor of FlexIO analog inputs, not necessary for data logging)
    BpodSystem.startAnalogViewer; 

    %% Setup analog input module
    A.InputRange(1:2) = {'-5V:5V', '-5V:5V'}; % set range to -5V:5V
    A.SamplingRate = 1000; % Hz
    A.nActiveChannels = 2; % Record from up to 2 channels
    A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
    A.DIOconfig(1:2) = 1;
    % A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
    % A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
    % A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
    % A.startReportingEvents; % Enable threshold event signaling
    behaviorDataFile = BpodSystem.Path.CurrentDataFile;
    A.USBStreamFile = [behaviorDataFile(1:end-4) '_FlowMeters.mat']; % Set datafile for analog data captured in this session
    A.scope; % Launch Scope GUI
    A.scope_StartStop % Start USB streaming + data logging
    
    %% Precompute CueDelay for all trials
    if S.GUI.VariableITI
        % Generate incremental CueDelay values using a geometric progression
        ITI = S.GUI.InterTrialInterval * (1.01 .^ (0:S.GUI.maxTrials-1));
    else
        % Constant CueDelay for all trials
        ITI = S.GUI.InterTrialInterval * ones(1, S.GUI.maxTrials);
    end
    % Enforce maximum ITI duration for all trials
    ITI(ITI > S.GUI.MaxITI) = S.GUI.MaxITI;
    
    %% Prepare and start first trial
    sma = PrepareStateMachine(S, 1, ITI, []); % Prepare state machine for trial 1 with empty "current events" variable
    trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
    
    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        currentTrialEvents = trialManager.getCurrentEvents({'Reward', 'InterTrialInterval'});
        
        % Handle pause/stop by user
        HandlePauseCondition;
        if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            A.stopUSBStream;
            A.scope_StartStop; % Stop Oscope GUI
            A.endAcq; % Close Oscope GUI
            A.stopReportingEvents; % Stop sending events to state machine
            return
        end

        if currentTrial < S.GUI.maxTrials
            [sma, S] = PrepareStateMachine(S, currentTrial+1, ITI, currentTrialEvents);
            SendStateMachine(sma, 'RunASAP');
        end
        RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data

        % Handle pause/stop by user
        HandlePauseCondition;
        if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            A.stopUSBStream;
            A.scope_StartStop; % Stop Oscope GUI
            A.endAcq; % Close Oscope GUI
            A.stopReportingEvents; % Stop sending events to state machine
            return
        end

        if currentTrial < S.GUI.maxTrials
            trialManager.startTrial(); % Start processing the next trial's events (call with no argument since SM was already sent)
        end
        
        if ~isempty(fieldnames(RawEvents))
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
            BpodSystem.Data.TrialSettings(currentTrial) = S;
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            
            % Save rotary encoder data
            if currentTrial == 1
                eventData = R.readUSBStream(0); % Read and dump any REM data captured before first trial start. Subsequent REM data will be saved. 
                TrialStartTime = eventData.EventTimestamps(1); % First trial start time on REM clock is taken from this initial read
            end
            BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0);
            BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime;
            BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime;
            
            % Update plots
            TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
            last_trial_encoder_plot(BpodSystem.GUIHandles.EncoderAxes, 'update', 180, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);

            SaveBpodSessionData; 
        end
    end
    cleanup; % Save FlexI/O analog input data
end

function [sma, S] = PrepareStateMachine(S, currentTrial, ITI, currentTrialEvents)
    valveTime = GetValveTimes(S.GUI.RewardAmount, 1);
    sma = NewStateMachine();
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'Reward'},...
        'OutputActions', {'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1, 'Serial3', ['#' 1]}); % set RE, enable flexI/O threshold, sync analog input module
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', valveTime,...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
        'OutputActions', {'Valve1', 1, 'Serial3', ['=' 0 'High']}); % deliver reward, sync cameras
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI(currentTrial),...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
end

function cleanup()
    global BpodSystem
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1); % Save FlexI/O analog input data
    SaveBpodSessionData;
end