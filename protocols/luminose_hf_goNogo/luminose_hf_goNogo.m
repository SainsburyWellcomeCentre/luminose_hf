function luminose_hf_goNogo
    %% clear & setup
    clc;
    % Suppress JavaFrame warnings globally for this session
    warning('off', 'MATLAB:HandleGraphics:ObsoleteProperty:JavaFrame');

    global BpodSystem S luminose olfModel
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_goNogo';
    
    %% Configure trials  
    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_luminose_hf_goNogo();
    end
    % Initialize parameter GUI plugin
    LuminoseParameterGUI_hf_goNogo('init', S);
    % Wait for Start button press
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return  % GUI was closed
        end
    end
    S = LuminoseParameterGUI_hf_goNogo('sync', S);
    disp('START pressed — beginning experiment.');
    
    BpodSystem.Data.Custom.TrialSide = [];
    BpodSystem.Data.Custom.TrialResponse = [];
    BpodSystem.Data.Custom.TrialOutcome = [];
    BpodSystem.Data.Custom.TrialType = [];
    
    nextTrialType = getNextTrialType_hf_goNogo(BpodSystem.Data, S);
    currentTrialType = nextTrialType;

    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    CSplus = S.GUIMeta.CSplusType.String{S.GUI.CSplusType};
    CSminus = S.GUIMeta.CSminusType.String{S.GUI.CSminusType};
    
    if S.GUI.VariableITI % questionable method
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
    liveOutcomePlot_hf_goNogo(BpodSystem.GUIHandles.OutcomeAxes, 'init', BpodSystem.Data, currentTrialType);
    
    % Live accuracy bar plot
    BpodSystem.ProtocolFigures.AccuracyPlot = figure('Position', [1040 1035 350 350], ...
        'name', 'Accuracy Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.AccuracyAxes = axes('Position', [.15 .12 .8 .8]);
    liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'init', []);
    
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

    % Live Encoder Plot
    BpodSystem.ProtocolFigures.EncoderPlot = figure('Position', [1045 730 500 350], ...
        'name', 'Encoder Plot', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'on');
    BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
    liveEncoderPlot_hf_goNogo(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

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
        channelTypes(chanNIDAQ) = 2; % Digital Input
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
        % Configure HiFi module
        sf = 192000;
        H.SamplingRate = sf;
        errorSound = GenerateWhiteNoise(sf, S.GUI.NoiseTime, 1, 2);
        H.load(1, errorSound);
        cueSound = GenerateSineWave(sf, S.GUI.Freq_cue, S.GUI.CueTime);
        H.load(2, cueSound);
        TimeSoundCSplus = 0:1/sf:S.GUI.StimTime;
        CSplusSound = chirp(TimeSoundCSplus, S.GUI.LowFreq_CSplus, S.GUI.CueTime, S.GUI.HighFreq_CSplus);
        H.load(3, CSplusSound);
        TimeSoundCSminus = 0:1/sf:S.GUI.StimTime;
        CSminusSound = chirp(TimeSoundCSminus, S.GUI.LowFreq_CSminus, S.GUI.CueTime, S.GUI.HighFreq_CSminus);
        H.load(4, CSminusSound);

        H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 63; % Ignored if using HD version of the HiFi module
        H.DigitalAttenuation_dB = -60; % Set a negative value here if necessary for digital volume control.
        
        H.push; % Add any recently loaded sounds to the current sound set
    
        % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
        Envelope = 1/(H.SamplingRate*0.001):1/(H.SamplingRate*0.001):1; 
        H.AMenvelope = Envelope;
    
        %% Setup Rotary Encoder module
        if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
            R.useAdvancedThresholds = 'on'; % Advanced thresholds are available on rotary encoder module r2.0 or newer.
                                % See notes in setAdvancedThresholds() function in /Modules/RotaryEncoderModule.m for parameters and usage
            R.setAdvancedThresholds([-35 10 10],... 
                [0 1 1], [0 S.GUI.ResponseTime 0.2]); % Syntax: setAdvancedThresholds(thresholds, thresholdTypes, thresholdTimes)
            R.sendThresholdEvents = 'on'; % Enable sending threshold crossing events to state machine
        else
            R.useAdvancedThresholds = 'off';
        end
        R.startUSBStream; % Begin streaming position data to PC via USB
        
        %% Prepare and start first trial 
        ManualOverride('OP', 5); ManualOverride('OP', 5); ManualOverride('OP', 5); disp('rig lights toggled');
        trialManager = BpodTrialManager;
        sma = PrepareStateMachine(S, currentTrialType, 1, ITI, emulator); % Prepare state machine for trial 1 with empty "current events" variable
        sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS'); 
        trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                                  % console UI, while code below proceeds in parallel.
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                t1 = tic;
                S = LuminoseParameterGUI_hf_goNogo('sync', S); % Sync parameters with LuminoseParameterGUI_hf_goNogo plugin
    
                currentTrialType = nextTrialType;
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                BpodSystem.Data.Custom.TrialSide(currentTrial) = currentTrialType;
                BpodSystem.Data.Custom.TrialType(currentTrial) = currentTrialType;

                handle_pause_condition(H, R); % Handle pause/stop by user
                
                if currentTrial < S.GUI.maxTrials
                    nextTrialType = getNextTrialType_hf_goNogo(BpodSystem.Data, S);
                    [sma, S] = PrepareStateMachine(S, nextTrialType, currentTrial+1, ITI, emulator);
                    disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                    SendStateMachine(sma, 'RunASAP');
                end
                                   
                RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
                handle_pause_condition(H, R); % Handle pause/stop by user
                
                t2 = tic;
                if strcmp(S.GUIMeta.ResponseType.String(S.GUI.ResponseType), 'Rotary Encoder')
                    R.setAdvancedThresholds([-35 10 10],... 
                        [0 1 1], [0 S.GUI.ResponseTime 0.2]);
                end
                disp(['set RE: ', num2str(toc(t2))]);

                if currentTrial < S.GUI.maxTrials
                    trialManager.startTrial(); % Start processing the next trial's events (call with no argument since SM was already sent)
                end
                
                if ~isempty(fieldnames(RawEvents))
                    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
                    BpodSystem.Data.TrialSettings(currentTrial) = S;
                    
                    % Update Custom data
                    outcome = getTrialOutcome_hf_goNogo(BpodSystem.Data, currentTrial);
                    BpodSystem.Data.Custom.TrialOutcome(currentTrial) = outcome;
                    % For response: 1=Left/CS+, 2=Right/CS-, NaN=NoResp
                    if outcome == 1 % Correct
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = currentTrialType;
                    elseif outcome == 0 % Incorrect
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = 3 - currentTrialType;
                    else
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = NaN;
                    end

                    BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
                    
                    % Save rotary encoder data
                    if currentTrial == 1
                        eventData = R.readUSBStream(0); % Read and dump any REM data captured before first trial start. Subsequent REM data will be saved. 
                        TrialStartTime = eventData.EventTimestamps(1); % First trial start time on REM clock is taken from this initial read
                    end
                    
                    BpodSystem.Data.EncoderData{currentTrial} = R.readUSBStream(0); % Returns REM data up to event '0'
                    
                    %% Update plots
                    t3 = tic;
                    liveOutcomePlot_hf_goNogo(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
                    disp(['Updated outcome plot: ', num2str(toc(t3))]);

                    t4 = tic;
                    liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                    disp(['Updated bar plot: ', num2str(toc(t4))]);
                    
                    t5 = tic;
                    liveRewardPlot_hf_goNogo(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                    disp(['Updated reward plot: ', num2str(toc(t5))]);

                    t6 = tic;
                    liveResponseTimePlot_hf_goNogo(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                    disp(['Updated response time plot: ', num2str(toc(t6))]);

                    t7 = tic;
                    % Update rotary encoder plot
                    if currentTrial == 1 
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    else
                        TrialStartTime = NextTrialStartTime;
                        NextTrialStartTime = BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps(1);
                    end
                    BpodSystem.Data.EncoderData{currentTrial}.Times = BpodSystem.Data.EncoderData{currentTrial}.Times - TrialStartTime; 
                    BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps = ...
                        BpodSystem.Data.EncoderData{currentTrial}.EventTimestamps - TrialStartTime; 

                    TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    liveEncoderPlot_hf_goNogo(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial},TrialDuration);
                    
                    disp(['Updated rotary encoder plot: ', num2str(toc(t7))]);

                    t8 = tic;
                    SaveBpodSessionData; 
                    SaveOnlinePlots;
                    disp(['Saved data: ', num2str(toc(t8))]);
                end
            catch ME
                disp('=== CRASH ===');
                disp(ME.message);
                cleanup; % Save FlexI/O analog input data
                ManualOverride('OP', 5); ManualOverride('OP', 5); ManualOverride('OP', 5); disp('rig lights toggled');
                break
            end  
        end
    else % emulator mode
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                S = LuminoseParameterGUI_hf_goNogo('sync', S); % Sync parameters with LuminoseParameterGUI_hf_goNogo plugin
                
                currentTrialType = nextTrialType;
                BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                BpodSystem.Data.Custom.TrialSide(currentTrial) = currentTrialType;
                BpodSystem.Data.Custom.TrialType(currentTrial) = currentTrialType;

                sma = PrepareStateMachine(S, currentTrialType, currentTrial+1, ITI, emulator);
                SendStateMachine(sma);
                RawEvents = RunStateMachine; % Run the trial and return events
    
                if ~isempty(fieldnames(RawEvents))
                    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
                    BpodSystem.Data.TrialSettings(currentTrial) = S;
                    
                    % Update Custom data
                    outcome = getTrialOutcome_hf_goNogo(BpodSystem.Data, currentTrial);
                    BpodSystem.Data.Custom.TrialOutcome(currentTrial) = outcome;
                    if outcome == 1 % Correct
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = currentTrialType;
                    elseif outcome == 0 % Incorrect
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = 3 - currentTrialType;
                    else
                        BpodSystem.Data.Custom.TrialResponse(currentTrial) = NaN;
                    end

                    BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
    
                    % Update plots
                    TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    
                    nextTrialType = getNextTrialType_hf_goNogo(BpodSystem.Data, S);
                    liveOutcomePlot_hf_goNogo(BpodSystem.GUIHandles.OutcomeAxes, 'update', BpodSystem.Data, nextTrialType);
    
                    liveBarPlot_hf_goNogo(BpodSystem.GUIHandles.AccuracyAxes, 'update', BpodSystem.Data);
                    liveRewardPlot_hf_goNogo(BpodSystem.GUIHandles.RewardAxes, 'update', BpodSystem.Data);
                    liveResponseTimePlot_hf_goNogo(BpodSystem.GUIHandles.ResponseAxes, 'update', BpodSystem.Data);
                end
                HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
                if BpodSystem.Status.BeingUsed == 0 % If protocol was stopped, exit the loop
                    return
                end
            catch ME
                disp('=== CRASH ===');
                disp(ME.message);
                cleanup; % Save FlexI/O analog input data
                ManualOverride('OP', 5); ManualOverride('OP', 5); ManualOverride('OP', 5); disp('rig lights toggled');
                break
            end
        end
    end
end

%% State machine 
function [sma, S] = PrepareStateMachine(S, currentTrialType, currentTrial, ITI, emulator)
    cue = S.GUIMeta.CueType.String{S.GUI.CueType};
    CSplus = S.GUIMeta.CSplusType.String{S.GUI.CSplusType};
    CSminus = S.GUIMeta.CSminusType.String{S.GUI.CSminusType};   
    response = S.GUIMeta.ResponseType.String{S.GUI.ResponseType}; 
    
    startAction = {'BNC1', 1}; % sync
    if ~emulator
        startAction{end+1} = 'HiFi1'; startAction{end+1} = '*';
        startAction{end+1} = 'RotaryEncoder1'; startAction{end+1} = ['#' 0];
        startAction{end+1} = 'AnalogThreshEnable'; startAction{end+1} = 1;
    end
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
        case 1 % CS+
            switch CSplus
                case 'Odour'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 2;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 9;
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
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 3;
                    chooseState2 = 'DeliverStim';
                case 'Pattern'
                    stimAction{end+1} = 'BNC2'; stimAction{end+1} = 1;
                    startAction{end+1} = 'SoftCode'; startAction{end+1} = 10;
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
    responseAction = {};
    switch response
        case 'Lick'
            responseDetect = {'Port3In', goAction, 'Tup', noGoAction};
            chooseState1 = chooseState2;
        case 'Rotary Encoder'
            responseDetect = {'RotaryEncoder1_1', goAction, 'RotaryEncoder1_2', noGoAction};
            chooseState1 = 'InitRE';
            responseAction{end+1} = 'RotaryEncoder1'; responseAction{end+1} = ['Z;' 3];
    end
    valveTime = GetValveTimes(S.GUI.RewardAmount, 3);
    if S.GUI.NoiseTime ~= 0
        punishAction = {'HiFi1', ['P', 0], 'BNC1', 1};
    else
        punishAction = {'BNC1', 1};
    end
    
    switch emulator
        case true
            if currentTrial == 1
                sma = NewStateMachine();
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
                'OutputActions', {'PWM1', S.GUI.Intensity_cue}); 
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'getResponse'},...
                'OutputActions', {'PWM2', S.GUI.Intensity_cue}); 
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
                'OutputActions', {});
    
        case false
            if currentTrial == 1
                sma = NewStateMachine();
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
                'Timer', ITI(currentTrial)/2,...
                'StateChangeConditions', {'Tup', 'ShowCue'},...
                'OutputActions', startAction); 
            sma = AddState(sma, 'Name', 'ShowCue', ... 
                'Timer', S.GUI.CueTime,...
                'StateChangeConditions', {'Tup', chooseState1},...
                'OutputActions', cueAction); 
            sma = AddState(sma, 'Name', 'InitRE', ...
                'Timer', 0.2,...
                'StateChangeConditions', {'RotaryEncoder1_3', chooseState2, 'RotaryEncoder1_4', chooseState2},...
                'OutputActions', {'RotaryEncoder1', [';' 4]}); 
            sma = AddState(sma, 'Name', 'GetSniff', ...
                'Timer', 0, ...
                'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'}, ...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', S.GUI.StimTime,...
                'StateChangeConditions', {'Tup', 'GetResponse'},...
                'OutputActions', stimAction); 
            sma = AddState(sma, 'Name', 'GetResponse', ...
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', responseDetect,...
                'OutputActions', responseAction);
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
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial)/2,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
    end
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
    global BpodSystem
    BpodSystem.Data = AddFlexIOAnalogData(BpodSystem.Data, 'Volts', 1);
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
