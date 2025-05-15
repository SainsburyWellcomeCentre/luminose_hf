function GUIparams_olfactometer_goNogo()
    global S % BpodSystem
    olfactometer = LuminoseConstants.addOlfactometer();
    S.GUIPanels.Sound = {'SoundSamplingRate','ErrorSoundAmplitude'};
    S.GUIPanels.Light = {'LEDIntensity'};
    S.GUIPanels.TrialInfo = {'maxTrials', 'OdourTime', 'RewardAmount', 'ResponseTime', ...
                             'ErrorDelay','VariableITI','InterTrialInterval', 'MaxITI'};
    S.GUIPanels.TrainingType = {'TrainingLevel', 'BiasCorrection'};
    
    % Sound
    S.GUI.SoundSamplingRate = 192000;
    S.GUI.ErrorSoundAmplitude = 1;
    
    % Light
    S.GUI.LEDIntensity = 100;

    % Trial info
    S.GUI.maxTrials = 1000;
    S.GUI.OdourTime = olfactometer.acquisitionTime;
    S.GUI.PatternTime = 0.2;
    S.GUI.RewardAmount = 10;
    S.GUI.ResponseTime = 1;
    S.GUI.ErrorDelay = 1;
    S.GUI.VariableITI = true;
    S.GUI.InterTrialInterval = 0.1;
    S.GUI.MaxITI = 0.1;

    % Training type
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Odour', 'Odour_Psychometric'};    
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';