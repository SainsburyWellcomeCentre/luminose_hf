function olfactometer_goNogo
    %% Set global variables and softcode handler function
    clc;
    run luminose_init.m
    global BpodSystem S
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_olfactometer_goNogo';

    %% Assert HiFi + Rotary Encoder +Analog Input modules are present + USB-paired (via USB button on console GUI)
    BpodSystem.assertModule({'HiFi','RotaryEncoder', 'AnalogIn'}, [1 1 1]); 

    H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
    R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1); 
    A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);

    if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
        error('Error: This protocol requires rotary encoder module v2 or newer');
    end

    R.sendThresholdEvents = 'off';
    R.startUSBStream;

    trialManager = BpodTrialManager;

    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_olfactometer_goNogo();
    end

    trialTypes = round(1+rand(1,S.GUI.maxTrials)); % Uniform distribution of values 1 and 2.

    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    
    outcomePlot = LiveOutcomePlot([1 2], {'Go', 'No go'}, trialTypes, 90);
    outcomePlot.RewardStateNames = {'Reward'}; % List of state names where reward was delivered
    outcomePlot.PunishStateNames = {'Punishment'}; % List of state names where choice was incorrect and negatively reinforced
    BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [500 200 350 350],'name','Encoder plot',...
                                                   'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    last_trial_encoder_plot(BpodSystem.GUIHandles.EncoderAxes, 'init', 180);

    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 
    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    %% Setup sound
    % Configure HiFi module
    H.SamplingRate = S.GUI.SoundSamplingRate;
    errorSound = GenerateWhiteNoise(H.SamplingRate, S.GUI.ErrorDelay, S.GUI.ErrorSoundAmplitude, 2);
    H.load(2, errorSound);
    H.push; % Add any recently loaded sounds to the current sound set

    %% Configure Flex I/O Channels
    BpodSystem.FlexIOConfig.channelTypes = [2 4 4 4];
    BpodSystem.FlexIOConfig.threshold1 = ones(1,4)*3; % In range 0-5
    BpodSystem.FlexIOConfig.polarity1 = zeros(1,4); % Polarity 0: Threshold activated when analog is > thresh
    BpodSystem.FlexIOConfig.threshold2 = ones(1,4)*3; % In range 0-5
    BpodSystem.FlexIOConfig.polarity2 = ones(1,4); % Polarity 1: Threshold activated when analog is < thresh
    BpodSystem.FlexIOConfig.thresholdMode = ones(1,4); % Mode 1: Crossing threshold 1 enables threshold 2, crossing 2 enables 1

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
    sma = PrepareStateMachine(S, trialTypes, 1, ITI); % Prepare state machine for trial 1 with empty "current events" variable
    trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
    
    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        % currentTrialEvents = trialManager.getCurrentEvents({'Reward', 'Punishment', 'TimedOut'});
        
        if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            return
        end

        [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial+1, ITI);
        SendStateMachine(sma, 'RunASAP');

        RawEvents = trialManager.getTrialData;

        if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            return
        end

        HandlePauseCondition;
        trialManager.startTrial();
        if ~isempty(fieldnames(RawEvents))
            BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0);
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.TrialSettings(currentTrial) = S;
            BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial);
            outcomePlot.update(trialTypes, BpodSystem.Data);
        if currentTrial == 1
            eventData = R.readUSBStream(0); % Read and dump any REM data captured before first trial start. Subsequent REM data will be saved. 
            TrialStartTime = eventData.EventTimestamps(1); % First trial start time on REM clock is taken from this initial read
        end
            BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime;
            BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime;

            TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
            last_trial_encoder_plot(BpodSystem.GUIHandles.EncoderAxes, 'update', 180, BpodSystem.Data.EncoderData{currentTrial}, TrialDuration);

            SaveBpodSessionData; 
        end
    end
end

function [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial, ITI)
    valveTime = GetValveTimes(S.GUI.RewardAmount, 1);
    switch trialTypes(currentTrial)
        case 1
            lickAction = 'Reward'; noLickAction = 'Punishment'; 
        case 2
            noLickAction = 'Reward'; lickAction = 'Punishment';
    end
    LoadSerialMessages('AnalogIn1', {['L' 1], ['L' 0]});  % Set serial messages 1+2 to start+stop logging
    sma = NewStateMachine();
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'deliverPattern'},...
        'OutputActions', {'LED', 1, 'RotaryEncoder1', ['#' 0], 'AnalogThreshEnable', 1, 'Serial3', 1});
    sma = AddState(sma, 'Name', 'deliverPattern', ... 
        'Timer', S.GUI.PatternTime,...
        'StateChangeConditions', {'Tup', 'deliverOdour'},...
        'OutputActions', {'PWM1', S.GUI.LEDIntensity, 'Serial3', ['=' 1 'High']});
    sma = AddState(sma, 'Name', 'deliverOdour', ... 
        'Timer', S.GUI.OdourTime,...
        'StateChangeConditions', {'Tup', 'getResponse'},...
        'OutputActions', {'PWM1', S.GUI.LEDIntensity, 'SoftCode', trialTypes(currentTrial), 'Serial3', ['=' 0 'High']});
    sma = AddState(sma, 'Name', 'getResponse', ...
        'Timer', S.GUI.ResponseTime,...
        'StateChangeConditions', {'Flex1Trig1', lickAction, 'Tup', noLickAction},...
        'OutputActions', {'Serial3', ['#' 1]});
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', valveTime,...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
        'OutputActions', {'Valve1', 1}); 
    sma = AddState(sma, 'Name', 'Punishment', ...
        'Timer', S.GUI.ErrorDelay,...
        'StateChangeConditions', {'Tup', 'TimedOut'},...
        'OutputActions', {'HiFi1', ['P' 2]}); 
    sma = AddState(sma, 'Name', 'TimedOut', ...
        'Timer', S.GUI.ErrorDelay,...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
        'OutputActions', {'HiFi1', 'X'});
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI(currentTrial),...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'Serial3', 0});
end
