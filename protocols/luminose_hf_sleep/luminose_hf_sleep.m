function luminose_hf_sleep
    %% clear & setup
    clc;

    global BpodSystem S luminose dmdModel olfModel
    beep('off'); % native matlab error sounds OFF
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_luminose_hf_sleep';

    %% Define luminose constants
    % Add folders and save path
    luminose = LuminoseConstants();
    currentDataFile = split(BpodSystem.Path.CurrentDataFile, '\');
    log_file = char(fullfile(join(currentDataFile(1:end-1), '\'), sprintf('output_log_%s.txt', datestr(now, 'yyyy-mm-dd_HH-MM-SS'))));
    diary(log_file);

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
        GUIparams_luminose_hf_sleep();
    end
    % Initialize parameter GUI plugin
    LuminoseParameterGUI_hf_sleep('init', S);
    % Wait for Start button press
    disp('Waiting for START button...');
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', false);
    while ~getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed')
        pause(0.1);
        if ~ishandle(BpodSystem.ProtocolFigures.ParameterGUI)
            return  % GUI was closed
        end
    end
    LuminoseParameterGUI_hf_sleep('sync', S);
    disp('START pressed — beginning experiment.');

    % BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    % 
    trialTypes = 1 + (rand(1, S.GUI.maxTrials) >= S.GUI.Typeprob); % distribution of values 1 and 2 with given probability p and 1-p respectively.
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    if S.GUI.TestPulses
        if S.GUI.TestPulsesType == 1
            stimTime = S.GUI.SPduration;
            if S.GUI.SPvariable
                ITI = (1 / S.GUI.SPfrequency) * (1.01 .^ (0:S.GUI.maxTrials-1)); % Generate incremental ITI values using a geometric progression
                ITI(ITI > (1 / S.GUI.MaxSPfrequency)) = 1 / S.GUI.MaxSPfrequency; % Enforce maximum ITI duration for all trials
                ITI = ITI(randperm(length(ITI)))';
                ITI = round(ITI * 1000) / 1000;
            else
                ITI = (1 / S.GUI.SPfrequency) * ones(1, S.GUI.maxTrials);
            end
        elseif S.GUI.TestPulsesType == 2
            stimTime = S.GUI.PPduration;
            if S.GUI.PPvariable
                ITI = (1 / S.GUI.PPfrequency) * (1.01 .^ (0:S.GUI.maxTrials-1)); % Generate incremental ITI values using a geometric progression
                ITI(ITI > (1 / S.GUI.MaxPPfrequency)) = 1 / S.GUI.MaxPPfrequency; % Enforce maximum ITI duration for all trials
                ITI = ITI(randperm(length(ITI)))';
                ITI = round(ITI * 1000) / 1000;
            else
                ITI = (1 / S.GUI.PPfrequency) * ones(1, S.GUI.maxTrials);
            end
        end
    else
        stimTime = 0;
        ITI = round(2 + 3 * rand(1,S.GUI.maxTrials), 3);
    end

    %% Begin plotting
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
        BpodSystem.assertModule({'RotaryEncoder'}, [1]); 
    
        R = RotaryEncoderModule(BpodSystem.ModuleUSB.RotaryEncoder1); 
        % A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
    
        if BpodSystem.Modules.HWVersion_Major(strcmp(BpodSystem.Modules.Name, 'RotaryEncoder1')) < 2
            error('Error: This protocol requires rotary encoder module v2 or newer');
        end
    
        %% Setup Rotary Encoder module
        R.useAdvancedThresholds = 'off';
        R.startUSBStream; % Begin streaming position data to PC via USB
        BpodSystem.ProtocolFigures.EncoderPlotFig = figure('Position', [1400 1035 350 350],'name','Encoder plot',...
                                                   'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
        BpodSystem.GUIHandles.EncoderAxes = axes('Position', [.15 .15 .8 .8]);
        liveEncoderPlot_hf_sleep(BpodSystem.GUIHandles.EncoderAxes, 'init', 0);

        %% Setup analog input module
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
        trialManager = BpodTrialManager;
        sma = PrepareStateMachine(S, trialTypes, 1, stimTime, ITI, emulator); % Prepare state machine for trial 1 with empty "current events" variable
        sessionStart = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
        trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                                  % console UI, while code below proceeds in parallel.
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                t1 = tic;
                S = LuminoseParameterGUI_hf_sleep('sync', S); % Sync parameters with LuminoseParameterGUI_hf_sleep plugin
                
                currentTrialType = trialTypes(currentTrial);
                disp(['calculated next trial: ', num2str(toc(t1))]);

                handle_pause_condition(R); % Handle pause/stop by user
                
                if currentTrial < S.GUI.maxTrials
                    [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial+1, stimTime, ITI, emulator);
                    disp(['Session: ', sessionStart, ' | Trial: ', num2str(currentTrial)]);
                    SendStateMachine(sma, 'RunASAP');
                end
                
                RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
                ManualOverride('OP', 5);
                handle_pause_condition(R); % Handle pause/stop by user
                
                if currentTrial < S.GUI.maxTrials
                    trialManager.startTrial(); % Start processing the next trial's events (call with no argument since SM was already sent)
                end

                %%
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
                    
                    %% Update plots   
                    t3 = tic;
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
                    liveEncoderPlot_hf_sleep(BpodSystem.GUIHandles.EncoderAxes, 'update', 0, BpodSystem.Data.EncoderData{currentTrial},TrialDuration);
                    disp(['Updated rotary encoder plot: ', num2str(toc(t3))]);

                    t4 = tic;
                    SaveBpodSessionData; 
                    disp(['Saved data: ', num2str(toc(t4))]);
                end
            catch
                cleanup; % Save FlexI/O analog input data
                ManualOverride('OP', 5); disp('rig lights toggled');
                break
            end
        end
    else % emulator mode
        %% Main trial loop
        for currentTrial = 1:S.GUI.maxTrials
            try
                S = LuminoseParameterGUI_hf_sleep('sync', S); % Sync parameters with LuminoseParameterGUI_hf_sleep plugin
                currentTrialType = trialTypes(currentTrial);
    
                sma = PrepareStateMachine(S, trialTypes, currentTrial+1, stimTime, ITI, emulator);
                SendStateMachine(sma);
                RawEvents = RunStateMachine; % Run the trial and return events
                ManualOverride('OP', 5);
    
                if ~isempty(fieldnames(RawEvents))
                    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
                    BpodSystem.Data.TrialSettings(currentTrial) = S;
                    BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;
                    BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
    
                    % Update plots
                    TrialDuration = BpodSystem.Data.TrialEndTimestamp(currentTrial)-BpodSystem.Data.TrialStartTimestamp(currentTrial);
                    
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
function [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial, stimTime, ITI, emulator)
       
    % analog input module: 'Serial3', ['=' 1 'High'], 'Serial3', ['=' 0 'High']
    startAction = {'PWM5', 255}; 
    if ~emulator
        startAction{end+1} = 'RotaryEncoder1'; startAction{end+1} = ['#' 0];
        startAction{end+1} = 'AnalogThreshEnable'; startAction{end+1} = 1;
        % startAction{end+1} = 'Serial3'; startAction{end+1} = ['#' 1]; % analog input module sync
    end
    sniffAction = {'RotaryEncoder1', '*Z', 'PWM5', 255};
    stimAction = {'BNC1', 1, 'PWM5', 255}; % sync
    if S.GUI.TestPulses
        switch trialTypes(currentTrial)
            case 1 
                % stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 9;
            case 2 
                % stimAction{end+1} = 'SoftCode'; stimAction{end+1} = 10;
        end
        chooseState1 = 'GetSniff';
    else
        chooseState1 = 'InterTrialInterval';
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
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode2', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode3'},...
                'OutputActions', {'BNC1', 0, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode3', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode4'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode4', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode5'},...
                'OutputActions', {'BNC1', 0, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode5', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
            else
                sma = NewStateMachine();
            end
            %%
            sma = AddState(sma, 'Name', 'TrialStart', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', chooseState1},...
                'OutputActions', {'PWM3', S.GUI.Intensity_cue, 'PWM5', 255}); 
            sma = AddState(sma, 'Name', 'GetSniff', ... 
                'Timer', 0,...
                'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'},...
                'OutputActions', {'PWM1', S.GUI.Intensity_cue, 'PWM5', 255});
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', stimTime,...
                'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
                'OutputActions', {'PWM2', S.GUI.Intensity_cue, 'PWM5', 255}); % light on
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'PWM5', 255});
        case false
            %%
            if currentTrial == 1
                sma = NewStateMachine();
                % unique barcode sent to identify protocol in first trial
                sma = AddState(sma, 'Name', 'Barcode1', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode2'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode2', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode3'},...
                'OutputActions', {'BNC1', 0, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode3', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode4'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode4', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'Barcode5'},...
                'OutputActions', {'BNC1', 0, 'PWM5', 255}); 
        
                sma = AddState(sma, 'Name', 'Barcode5', ...
                'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
                'StateChangeConditions', {'Tup', 'TrialStart'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255}); 
            else
                sma = NewStateMachine();
            end
            %%
            sma = AddState(sma, 'Name', 'TrialStart', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', chooseState1},...
                'OutputActions', startAction); 
            sma = AddState(sma, 'Name', 'GetSniff', ... 
                'Timer', 0,...
                'StateChangeConditions', {'Flex1Trig1', 'DeliverStim'},...
                'OutputActions', sniffAction);
            sma = AddState(sma, 'Name', 'DeliverStim', ... 
                'Timer', stimTime,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', stimAction); 
            sma = AddState(sma, 'Name', 'InterTrialInterval', ...
                'Timer', ITI(currentTrial),...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'BNC1', 1, 'PWM5', 255});
                
    end
end

%% Handle pause condition
function handle_pause_condition(R)
    global BpodSystem
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
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
    diary off;
end
