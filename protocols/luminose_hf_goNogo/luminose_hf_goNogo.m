function luminose_hf_goNogo
    %% clear & setup
    clc;

    global BpodSystem S luminose dmdModel olfModel
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_goNogo';

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
        GUIparams_luminose_hf_goNogo();
    end
       
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    if rand < S.GUI.CSplus_prob
        nextTrialType = 1;
    else
        nextTrialType = 2;
    end
    currentTrialType = nextTrialType;

    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    CSplus = S.GUIMeta.CSplusType.String{S.GUI.CSplusType};
    CSminus = S.GUIMeta.CSminusType.String{S.GUI.CSminusType};
    
    if strcmp(cue, 'Odour') % currently coded such that cue and stim cannot both be odours at the same trial 
        olfactometer_hf_goNogo(1);
    elseif any([strcmp(CSplus, 'Odour'), strcmp(CSminus, 'Odour')])
        olfactometer_hf_goNogo(currentTrialType + 1);
    end
    
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
    % Initialize parameter GUI plugin
    LuminoseParameterGUI_hf_goNogo('init', S);liveOutcome
    % Wait for Start button press
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return  % GUI was closed
        end
    end
    disp('START pressed — beginning experiment.');

    % Live outcome plot
    BpodSystem.ProtocolFigures.OutcomePlot = figure('Position', [30 1035 1000 350], ...
        'name', 'Outcome Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.OutcomeAxes = axes('Position', [.15 .12 .8 .8]);
    liveOutcomePlot_hf_goNogo(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);
    
    % Live accuracy bar plot
    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);
    
    % % Live psychometric curve
    % BpodSystem.ProtocolFigures.PsychometricPlot = figure('Position', [500 600 450 350], ...
    %     'name', 'Psychometric Curve', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
    % BpodSystem.GUIHandles.PsychometricAxes = axes('Position', [.15 .15 .8 .75]);
    % livePsychometricPlot_hf_goNogo(BpodSystem.GUIHandles.PsychometricAxes, 'init', [], [1]);
    
    % Live reward monitor
    BpodSystem.ProtocolFigures.RewardPlot = figure('Position', [1040 645 350 350], ...
        'name', 'Reward Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.RewardAxes = axes('Position', [.15 .12 .8 .8]);
    liveRewardPlot_hf_goNogo(BpodSystem.GUIHandles.RewardAxes, 'init', []);
    
    % Live response time plot
    BpodSystem.ProtocolFigures.ResponsePlot = figure('Position', [1400 645 350 350], ...
        'name', 'Response Time Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.ResponseAxes = axes('Position', [.15 .12 .8 .8]);
    liveResponseTimePlot_hf_goNogo(BpodSystem.GUIHandles.ResponseAxes, 'init', []);

    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 

    %% Configure bpod
    emulator = BpodSystem.EmulatorMode == 1;
    if ~emulator
        %% Configure Flex I/O Channels
        chanSniff = 1; chanPhotodetector = 2; chanFlowmeterIn = 3; chanFlowmeterOut = 4;
        channelTypes(1:4) = 4; % Disabled
        channelTypes(chanSniff) = 2; % Analog Input
        channelTypes(chanPhotodetector) = 4; % Analog Input
        channelTypes(chanFlowmeterIn) = 2; % Analog Input
        channelTypes(chanFlowmeterOut) = 2; % Analog Input
        BpodSystem.FlexIOConfig.channelTypes = channelTypes;
        
        % Set sniff threshold for inhalation triggered stimulus
        BpodSystem.FlexIOConfig.threshold1(chanSniff) = 0.5;
        BpodSystem.FlexIOConfig.polarity1(chanSniff) = 1;
        BpodSystem.FlexIOConfig.thresholdMode(chanSniff) = 0;

        % Set sampling rate 
        BpodSystem.FlexIOConfig.analogSamplingRate = 500; % Sampling rate
        
        % Initialize analog viewer GUI (online monitor of FlexIO analog inputs, not necessary for data logging)
        BpodSystem.startAnalogViewer; 
        flexioPos = get(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position');
        flexioPos(1:2) = [10, 100];
        set(BpodSystem.GUIHandles.OscopeFig_Builtin, 'Position', flexioPos);

        %% Assert modules are USB-paired
        BpodSystem.assertModule({'HiFi','RotaryEncoder', 'AnalogIn'}, [1 1 1]); 
    
        H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
        R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1); 
        A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
    
        if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
            error('Error: This protocol requires rotary encoder module v2 or newer');
        end

        %% Setup sound
        % Configure HiFi module
        H.SamplingRate = S.GUI.SoundSamplingRate;
        errorSound = GenerateWhiteNoise(H.SamplingRate, S.GUI.NoiseTime, S.GUI.Amplitude_error, 2);
        H.load(1, errorSound);
        cueSound = GenerateSineWave(S.GUI.SoundSamplingRate, S.GUI.Freq_cue, S.GUI.CueTime);
        H.load(2, cueSound);
        TimeSoundCSplus = 0:1/S.GUI.SoundSamplingRate:S.GUI.StimTime;
        CSplusSound = chirp(TimeSoundCSplus, S.GUI.LowFreq_CSplus, S.GUI.CueTime, S.GUI.HighFreq_CSplus);
        H.load(3, CSplusSound);
        TimeSoundCSminus = 0:1/S.GUI.SoundSamplingRate:S.GUI.StimTime;
        CSminusSound = chirp(TimeSoundCSminus, S.GUI.LowFreq_CSminus, S.GUI.CueTime, S.GUI.HighFreq_CSminus);
        H.load(4, CSminusSound);

        H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 10; % Ignored if using HD version of the HiFi module
        H.DigitalAttenuation_dB = -60; % Set a negative value here if necessary for digital volume control.
        
        H.push; % Add any recently loaded sounds to the current sound set
    
        % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
        Envelope = 1/(S.GUI.SoundSamplingRate*0.001):1/(S.GUI.SoundSamplingRate*0.001):1; 
        H.AMenvelope = Envelope;
    
        %% Setup Rotary Encoder module
        if strcmp(S.GUIMeta.ResponseType(S.GUI.ResponseType), 'Rotary Encoder')
            R.useAdvancedThresholds = 'on'; % Advanced thresholds are available on rotary encoder module r2.0 or newer.
                                % See notes in setAdvancedThresholds() function in /Modules/RotaryEncoderModule.m for parameters and usage
            R.setAdvancedThresholds([90 -90 10],... 
                [0 0 1], [0 0 0.2]); % Syntax: setAdvancedThresholds(thresholds, thresholdTypes, thresholdTimes)
            R.sendThresholdEvents = 'on'; % Enable sending threshold crossing events to state machine
        else
            R.useAdvancedThresholds = 'off';
        end
        R.startUSBStream; % Begin streaming position data to PC via USB
        BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [1400 1035 350 350],'name','Encoder plot',...
                                                   'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
        BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
        liveEncoderPlot_hf_goNogo(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

        %% Setup analog input module
        % A.InputRange(1:3) = {'-5V:5V', '-5V:5V', '-2.5V:2.5V'}; % set range to -5V:5V
        % A.SamplingRate = 1000; % Hz
        % A.nActiveChannels = 0; 
        % A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
        A.DIOconfig(1:2) = 1;
        % A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
        % A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
        % A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
        % A.startReportingEvents; % Enable threshold event signaling
        % behaviorDataFile = BpodSystem.Path.CurrentDataFile;
        % A.USBStreamFile = [behaviorDataFile(1:end-4) '_StimFeedback.mat']; % Set datafile for analog data captured in this session
        % A.scope; % Launch Scope GUI
        % A.scope_StartStop; % Start USB streaming + data logging
        
        
        %% Prepare and start first trial      
        trialManager = BpodTrialManager;
        sma = PrepareStateMachine(S, currentTrialType, 1, ITI, emulator); % Prepare state machine for trial 1 with empty "current events" variable
        trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                                  % console UI, while code below proceeds in parallel.
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            S = LuminoseParameterGUI_hf_goNogo('sync', S); % Sync parameters with LuminoseParameterGUI_hf_goNogo plugin

            currentTrialType = nextTrialType;
            nextTrialType = getNextTrialType_hf_goNogo(BpodSystem.Data, 50, S.GUI.BiasCorrection, 0.2, S.GUI.CSplus_prob);
            
            handle_pause_condition(H, R, A); % Handle pause/stop by user
            
            if currentTrial < S.GUI.maxTrials
                [sma, S] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI, emulator);
                SendStateMachine(sma, 'RunASAP');
            end
            
            RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
            handle_pause_condition(H, R, A); % Handle pause/stop by user
            
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
                liveOutcomePlot_hf_2AFC(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                
                liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                
                % livePsychometricPlot_hf_goNogo(BpodSystem.GUIHandles.PsychometricAxes, 'update', ...
                    % BpodSystem.Data, [1]);
                
                liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);

                liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                
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
                liveEncoderPlot_hf_goNogo(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial},TrialDuration);

                SaveBpodSessionData; 
                SaveBpodProtocolSettings;
            end
        end
        cleanup; % Save FlexI/O analog input data
    else % emulator mode
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            S = LuminoseParameterGUI_hf_goNogo('sync', S); % Sync parameters with LuminoseParameterGUI_hf_goNogo plugin
            
            currentTrialType = nextTrialType;
            nextTrialType = getNextTrialType_hf_goNogo(BpodSystem.Data, 50, S.GUI.BiasCorrection, 0.2, S.GUI.CSplus_prob);
            
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

                liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);

                % livePsychometricPlot_hf_goNogo(BpodSystem.GUIHandles.PsychometricAxes, 'update', ...
                    % BpodSystem.Data, [1]);

                liveRewardPlot_hf_2AFC(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                
                liveResponseTimePlot_hf_2AFC(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
            end
            HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
            if BpodSystem.Status.BeingUsed == 0 % If protocol was stopped, exit the loop
                return
            end
        end
    end
    cleanup; % Save FlexI/O analog input data
end

%% State machine 
function [sma, S] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI, emulator)
    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    CSplus = S.GUIMeta.CSplusType.String{S.GUI.CSplusType};
    CSminus = S.GUIMeta.CSminusType.String{S.GUI.CSminusType};   
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType}; 
    
    % analog input module: 'Serial3', ['=' 1 'High'], 'Serial3', ['=' 0 'High']
    startAction = {'BNC1', 1}; % sync
    if ~emulator
        startAction{end+1} = 'HiFi1'; startAction{end+1} = '*';
        startAction{end+1} = 'RotaryEncoder1'; startAction{end+1} = ['#' 0];
        startAction{end+1} = 'AnalogThreshEnable'; startAction{end+1} = 1;
        startAction{end+1} = 'Serial3'; startAction{end+1} = ['#' 1]; % analog input module sync
    end
    cueAction = {'RotaryEncoder1', '*Z'};
    prepareOdourAction = {}; % send odour info to olfactometer and wait for BNC2 trigger
    switch cue
        case 'Odour'
            cueAction{end+1} = 'BNC2'; cueAction{end+1} = 1;
            prepareOdourAction{end+1} = 'SoftCode'; prepareOdourAction{end+1} = 1;
        case 'Pattern'
            cueAction{end+1} = 'SoftCode'; cueAction{end+1} = 8;
        case 'Light'
            cueAction{end+1} = 'PWM3'; cueAction{end+1} = S.GUI.Intensity_cue;
        case 'Sound'
            cueAction{end+1} = 'HiFi1'; cueAction{end+1} = ['P', 1];
    end
    stimAction = {'BNC1', 1}; % sync
    switch currentTrialType
        case 1 % CS+
            switch CSplus
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    prepareOdourAction{end+1} = 'SoftCode'; prepareOdourAction{end+1} = 2;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 9;
                    chooseState2 = 'GetSniff';
                case 'Light'
                    stimAction{end+1} = 'PWM1'; stimAction{end+1} = S.GUI.Intensity_CSplus;
                    chooseState2 = 'DeliverStim';
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 2];
                    chooseState2 = 'DeliverStim';
            end
            goAction = 'Reward'; noGoAction = 'InterTrialInterval'; 
        case 2 % CS-
            switch CSminus
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    prepareOdourAction{end+1} = 'SoftCode'; prepareOdourAction{end+1} = 3;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 10;
                    stimAction{end+1} = 'Serial3'; stimAction{end+1} = ['=' 0 'High'];
                    chooseState2 = 'GetSniff';
                case 'Light'
                    stimAction{end+1} = 'PWM2'; stimAction{end+1} = S.GUI.Intensity_CSminus;
                    chooseState2 = 'DeliverStim';
                case 'Sound'
                    stimAction{end+1} = 'HiFi1'; stimAction{end+1} = ['P', 3];
                    chooseState2 = 'DeliverStim';
            end
            noGoAction = 'InterTrialInterval'; goAction = 'Punishment';
    end
    responseDetect = {};
    switch response
        case 'Lick'
            responseDetect = {'Port3In', goAction, 'Tup', noGoAction};
            chooseState1 = chooseState2;
        case 'Rotary Encoder'
            stimAction{end+1} = 'RotaryEncoder1'; stimAction{end+1} = ['Z;' 3];
            responseDetect = {'RotaryEncoder1_1', goAction, 'Tup', noGoAction};
            chooseState1 = 'InitRE';
    end
    valveTime = GetValveTimes(S.GUI.RewardAmount, 3);
    if S.GUI.NoiseTime ~= 0
        punishAction = {'HiFi1', ['P', 0], 'BNC1', 1};
    else
        punishAction = {'BNC1', 1};
    end

    switch emulator
        %%
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
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 0}); 
            else
                sma = NewStateMachine();
            end

            sma = AddState(sma, 'Name', 'TrialStart', ...
                'Timer', S.GUI.CueTime,...
                'StateChangeConditions', {'Tup', 'DeliverStim'},...
                'OutputActions', {'PWM1', S.GUI.Intensity_cue}); % light on
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'getResponse'},...
                'OutputActions', {'PWM2', S.GUI.Intensity_cue}); % light on
            sma = AddState(sma, 'Name', 'getResponse', ...
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', {'Port3In', goAction, 'Tup', noGoAction},...
                'OutputActions', {'PWM3', S.GUI.Intensity_cue});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', valveTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {'Valve3', 1}); 
            sma = AddState(sma, 'Name', 'Punishment', ...
                'Timer', S.GUI.NoiseTime,...
                'StateChangeConditions', {'Tup', 'TimeOut'},...
                'OutputActions', {}); 
            sma = AddState(sma, 'Name', 'TimeOut', ...
                'Timer', S.GUI.ErrorDelay - S.GUI.NoiseTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', prepareOdourAction);
    
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
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 0});
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
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'GetResponse'},...
                'OutputActions', stimAction); % light on
            sma = AddState(sma, 'Name', 'GetResponse', ...
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', responseDetect,...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', valveTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {'Valve3', 1, 'BNC1', 1}); 
            sma = AddState(sma, 'Name', 'Punishment', ...
                'Timer', S.GUI.NoiseTime,...
                'StateChangeConditions', {'Tup', 'TimeOut'},...
                'OutputActions', punishAction); 
            sma = AddState(sma, 'Name', 'TimeOut', ...
                'Timer', S.GUI.ErrorDelay - S.GUI.NoiseTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', prepareOdourAction);
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', prepareOdourAction);
    end
end
%% Handle pause condition
function handle_pause_condition(H, R, A)
    global BpodSystem
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
            H.stop;
            R.stopUSBStream;
            A.stopUSBStream;
            % A.scope_StartStop; % Stop Oscope GUI
            return
    end
end

%% Cleanup
function cleanup()
    global BpodSystem dmdModel
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1); % Save FlexI/O analog input data
    SaveBpodSessionData;
    SaveBpodProtocolSettings;
    dmdModel.disconnect_dmd();
    % A.endAcq; % Close Oscope GUI
    A.stopReportingEvents; % Stop sending events to state machine
end
