function GUIparams_habituation_goNogo()
    global S % BpodSystem
    S.GUIPanels.TrialInfo = {'maxTrials', 'RewardAmount', 'VariableITI', ...
                             'InterTrialInterval', 'MaxITI'};
    
    % Trial info
    S.GUI.maxTrials = 1000;
    S.GUI.RewardAmount = 10;
    S.GUI.VariableITI = false;
    S.GUI.InterTrialInterval = 0;
    S.GUI.MaxITI = 0;
