function freelymoving_passive
    %% Set global variables and softcode handler function
    clc;
    global BpodSystem S
    beep('off'); % native matlab error sounds OFF
    
    %% Define luminose constants
    % Add folders and save path
    folders = LuminoseConstants.addFolders();
    % Load experiment configuration structs
    bpod = LuminoseConstants.addBpod();
    bonsai = LuminoseConstants.addBonsai();
    
    % Display confirmation
    disp('Luminose experiment initialized:');
    disp("=====  Folders =====");
    disp(folders);
    disp("=====  Bpod =====");
    disp(bpod);
    disp("=====  Bonsai =====");
    disp(bonsai);
    
    %% Launch bonsai
    currentDataFile = split(BpodSystem.Path.CurrentDataFile, '\');
    currentFilePrefix = currentDataFile{end}; currentFilePrefix = currentFilePrefix(1:end-4);
    currentSubject = currentDataFile(end-2); 
    currentProtocol = currentDataFile(end-1);
    bonsai.dataPath = fullfile(folders.data, 'rawdata', currentSubject, currentProtocol, 'Session Videos');
    launch_bonsai(bonsai.exePath, bonsai.workflowPath, bonsai.dataPath, currentFilePrefix);
    
    %% Configure bpod
    trialManager = BpodTrialManager;

    S = BpodSystem.ProtocolSettings;
    if isempty(fieldnames(S))
        GUIparams_freelymoving_passive();
    end
    
    % Initialize Bpod notebook (for manual data annotation)                                                          
    BpodNotebook('init'); 
    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    %% Configure Flex I/O Channels
    BpodSystem.FlexIOConfig.channelTypes = [1 4 4 4]; % Digital Output
    BpodSystem.FlexIOConfig.analogSamplingRate = 1000; % Sampling rate

    %% Prepare and start first trial
    sma = PrepareStateMachine(S, 1, S.GUI.muITI); % Prepare state machine for trial 1 with empty "current events" variable
    trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
    
    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        if S.GUI.ITItype == 1
            ITI = S.GUI.muITI;
        elseif S.GUI.ITItype == 2
            ITI = normrnd(S.GUI.muITI, S.GUI.sdITI);
        end

        if currentTrial < S.GUI.maxTrials
            [sma, S] = PrepareStateMachine(S, currentTrial, ITI);
            SendStateMachine(sma, 'RunASAP');
        end
        RawEvents = trialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data

        if currentTrial < S.GUI.maxTrials
            trialManager.startTrial(); % Start processing the next trial's events (call with no argument since SM was already sent)
        end
        
        if ~isempty(fieldnames(RawEvents))
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
            BpodSystem.Data.TrialSettings(currentTrial) = S;
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin

            SaveBpodSessionData; 
        end
    end
end

function [sma, S] = PrepareStateMachine(S, currentTrial, ITI)
    if currentTrial == 1
        sma = NewStateMachine();
        % unique barcode
        sma = AddState(sma, 'Name', 'Barcode1', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'Barcode2'},...
        'OutputActions', {'Flex1DO', 1}); 

        sma = AddState(sma, 'Name', 'Barcode2', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'Barcode3'},...
        'OutputActions', {'Flex1DO', 0}); 

        sma = AddState(sma, 'Name', 'Barcode3', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'Barcode4'},...
        'OutputActions', {'Flex1DO', 1}); 

        sma = AddState(sma, 'Name', 'Barcode4', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'Barcode5'},...
        'OutputActions', {'Flex1DO', 0}); 

        sma = AddState(sma, 'Name', 'Barcode5', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'Barcode6'},...
        'OutputActions', {'Flex1DO', 1}); 

        sma = AddState(sma, 'Name', 'Barcode6', ...
        'Timer', normrnd(S.GUI.muBarcodeDur, S.GUI.sigmaBarcodeDur),...
        'StateChangeConditions', {'Tup', 'DeliverPulse'},...
        'OutputActions', {'Flex1DO', 0});
    else
        sma = NewStateMachine();
    end

    sma = AddState(sma, 'Name', 'DeliverPulse', ... 
        'Timer', S.GUI.pulseDur,...
        'StateChangeConditions', {'Tup', 'InterTrialInterval'},...
        'OutputActions', {'Flex1DO', 1});
    sma = AddState(sma, 'Name', 'InterTrialInterval', ...
        'Timer', ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});

end
