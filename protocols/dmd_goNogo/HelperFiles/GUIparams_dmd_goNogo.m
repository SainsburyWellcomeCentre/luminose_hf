function GUIparams_olfactometer_goNogo()
    global S olfactometer % BpodSystem
    S.GUIPanels.Sound = {'SoundSamplingRate','ErrorSoundAmplitude'};
    S.GUIPanels.Light = {'LEDIntensity'};
    S.GUIPanels.TrialInfo = {'maxTrials', 'CSplus_prob', 'PatternTime', 'RewardAmount', 'ResponseTime', ...
                             'ErrorDelay','VariableITI','InterTrialInterval', 'MaxITI'};
    S.GUIPanels.TrainingType = {'TrainingLevel', 'BiasCorrection'};
    
    % Sound
    S.GUI.SoundSamplingRate = 192000;
    S.GUI.ErrorSoundAmplitude = [0.1, 0.1];
    
    % Light
    S.GUI.LEDIntensity = 100;

    % Trial info
    S.GUI.maxTrials = 1000;
    S.GUI.CSplus_prob = 1;
    S.GUI.LEDtime = 1;
    S.GUI.PatternTime = 0;
    S.GUI.ResponseTime = 10;
    S.GUI.RewardAmount = 10;
    S.GUI.ErrorDelay = 1;
    S.GUI.ErrorSoundTime = 0.1; % must be less than error delay
    S.GUI.VariableITI = true;
    S.GUI.InterTrialInterval = 5;
    S.GUI.MaxITI = 10;

    % Training type
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Odour', 'Odour_Psychometric'};    
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';