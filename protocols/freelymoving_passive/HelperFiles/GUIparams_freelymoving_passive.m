function GUIparams_freelymoving_passive()
    global S % BpodSystem
    S.GUIPanels.TrialInfo = {'maxTrials', 'ITItype', 'muITI', 'sigmaITI', 'pulseDur'};    

    % Trial info
    S.GUI.muBarcodeDur = 0.2;
    S.GUI.sigmaBarcodeDur = 0.05;

    S.GUI.maxTrials = 1000;

    S.GUI.ITItype = 1;
    S.GUIMeta.ITItype.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.ITItype.String = {"uniform", "gaussian"};    
    S.GUI.muITI = 5;
    S.GUI.sigmaITI = 1;
    S.GUI.pulseDur = 0.1;
end