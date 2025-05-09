function olfactometer_goNogo
    %% Set global variables and softcode handler function
    run luminose_init.m
    global BpodSystem olfactometer

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
    R.streamUI;
    R.readUSBStream;

    trialManager = BpodTrialManager;

    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        S.GUI.OdourTime = 1;
        S.GUI.RewardAmount = 3;
        S.GUI.ResponseTime = 1;
        S.GUI.ErrorDelay = 5;
        S.GUI.InterTrialInterval = 1;
        S.GUI.ErrorSoundIntensity = 0.5;
        S.GUIPanels.Reward = {'RewardAmount'};
        S.GUIPanels.Time = {'OdourTime', 'ResponseTime', 'ErrorDelay', "InterTrialInterval"};
        S.GUIPanels.Sound = {'ErrorSoundIntensity'};
    end

    maxTrials = 1000;
    trialTypes = round(rand(1,maxTrials));

    BpodSystem.Data.TrialTypes = [];
    
    outcomePlot = LiveOutcomePlot([1 2], {'Go', 'No go'}, trialTypes+1, 90);
    outcomePlot.RewardStateNames = {'GoReward', 'NoGoReward'}; % List of state names where reward was delivered
    outcomePlot.PunishStateNames = {'Punishment'}; % List of state names where choice was incorrect and negatively reinforced
    
    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 
    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    %% Setup sound
    % Configure HiFi module
    H.SamplingRate = S.StimSamplingRate;
    H.DigitalAttenuation_dB = 0; % Set a negative value here if necessary for digital volume control.
    H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 10; % Configure headphone amplifier if using SD model
    H.SynthWaveform = 'WhiteNoise'; % A synth waveform will be played continuously when other sounds are not playing
    H.SynthAmplitude = S.GUI.NoiseMaskIntensity; % Set synth waveform intensity. The stimulus waveforms will have white noise added at this intensity 
                                                 % for a seamless background noise mask
    H.AMenvelope = 1/(H.SamplingRate*0.001):1/(H.SamplingRate*0.001):1; % Define 1ms linear envelope of amplitude coefficients, applied at sound onset 
                                                                        % + in reverse at sound offset. This helps avoid speaker 'pop'
    errorSound = GenerateWhiteNoise(H.SamplingRate, S.GUI.ErrorDelay, S.GUI.ErrorSoundIntensity, 2);
    H.load(1, errorSound);
    H.push; % Add any recently loaded sounds to the current sound set

    %% Configure Flex I/O Channels
    BpodSystem.FlexIOConfig.channelTypes = [2 1 4 4];
    BpodSystem.FlexIOConfig.threshold1 = ones(1,4)*4; % In range 0-5
    BpodSystem.FlexIOConfig.polarity1 = zeros(1,4); % Polarity 0: Threshold activated when analog is > thresh
    BpodSystem.FlexIOConfig.threshold2 = ones(1,4)*1; % In range 0-5
    BpodSystem.FlexIOConfig.polarity2 = ones(1,4); % Polarity 1: Threshold activated when analog is < thresh
    BpodSystem.FlexIOConfig.thresholdMode = ones(1,4); % Mode 1: Crossing threshold 1 enables threshold 2, crossing 2 enables 1

    % Initialize analog viewer GUI (online monitor of FlexIO analog inputs, not necessary for data logging)
    BpodSystem.startAnalogViewer; 

    %% Setup analog input module
    A.SamplingRate = 1000; % Hz
    A.nActiveChannels = 2; % Record from up to 2 channels
    A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
    A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
    A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
    A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
    A.startReportingEvents; % Enable threshold event signaling
    behaviorDataFile = BpodSystem.Path.CurrentDataFile;
    A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
    A.scope; % Launch Scope GUI
    A.scope_StartStop % Start USB streaming + data logging

    %%
    sma = PrepareStateMachine(S, trialTypes, 1, []);
    trialManager.startTrial(sma);

    for currentTrial = 1:maxTrials
        S = BpodParameterGUI('sync', S);
        currentTrialEvents = trialManager.getCurrentEvents({'Reward', 'Punishment', 'TimedOut'});

        if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            return
        end

        [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial+1, currentTrialEvents);
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
            if currentTrial == 1
                eventData = R.readUSBStream(0);
                TrialStartTime = eventData.EventTimestamps(1);
            end
            BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1);
            BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0);
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.CorrectChoice(currentTrial) = correctChoice(currentTrial);
            BpodSystem.Data.TrialSettings(currentTrial) = S;
            BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial);
            outcomePlot.update(trialTypes+1, BpodSystem.Data);

            BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime;
            BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime;

            TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
            last_trial_encoder_plot(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial},TrialDuration);

            SaveBpodSessionData; 
        end
    end
    R.stopUSBStream;
end

function [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial)
    switch trialTypes(currentTrial)
        case 0
            lickAction = 'Reward'; noLickAction = 'Punishment'; 
            valveTime = GetValveTimes(S.GUI.RewardAmount, 0);
        case 1
            noLickAction = 'Reward'; lickAction = 'Punishment';
            valveTime = GetValveTimes(S.GUI.RewardAmount, 1);
    end
    sma = NewStateMachine();
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'deliverOdour'},...
        'OutputActions', {'PWM3', 255, 'RotaryEncoder1', ['#' 0]}, {'AnalogIn1', ['#' 0]});
    sma = AddState(sma, 'Name', 'deliverOdour', ... 
        'Timer', S.GUI.OdourTime,...
        'StateChangeConditions', {'Tup', 'getResponse'},...
        'OutputActions', {'LED', 1, 'SoftCode', trialTypes(currentTrial)+1}, {'AnalogIn1', ['#' 1]});
    sma = AddState(sma, 'Name', 'getResponse', ...
        'Timer', S.GUI.ResponseTime,...
        'StateChangeConditions', {'AnalogIn1', lickAction, 'Tup', noLickAction},...
        'OutputActions', {'AnalogIn1', ['#' 2]});
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', valveTime,...
        'StateChangeConditions', {'Tup', 'TimedOut'},...
        'OutputActions', {'Valve3', 1}); 
    sma = AddState(sma, 'Name', 'Punishment', ...
        'Timer', S.GUI.ErrorDelay,...
        'StateChangeConditions', {'Tup', 'TimedOut'},...
        'OutputActions', {'HiFi1', ['P' 1]}); 
    sma = AddState(sma, 'Name', 'TimedOut', ...
        'Timer', S.GUI.ErrorDelay,...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
        'OutputActions', {'HiFi1', 'X'});
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', S.GUI.InterTrialInterval,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {{'AnalogIn1', ['#' 3]}});
end
