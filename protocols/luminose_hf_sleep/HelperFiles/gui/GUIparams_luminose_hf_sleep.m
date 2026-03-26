function GUIparams_luminose_hf_sleep()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'TreatmentType', 'ProtocolSettings', 'TestPulses', 'TrialParams'};
    S.GUIPanels.TrialParams = {'maxTrials', 'Typeprob'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUIPanels.ProtocolSettings = {'Sleep', 'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Trial Params ==
    S.GUI.maxTrials = 10000;  
    S.GUI.Typeprob = 0.5;
    
    % == Test Pulses ==
    S.GUI.TestPulses = false;
    S.GUIMeta.TestPulses.Style = 'checkbox';
    S.GUI.TestPulsesType = 2;
    S.GUIMeta.TestPulsesType.Style = 'popupmenu';
    S.GUIMeta.TestPulsesType.String = {'SinglePulse', 'PairedPulse'};
    
    % == Treatment Type ==
    S.GUI.Ephys = false;
    S.GUIMeta.Ephys.Style = 'checkbox';
    S.GUI.EEG = false;
    S.GUIMeta.EEG.Style = 'checkbox';
    S.GUI.Drug = false;
    S.GUIMeta.Drug.Style = 'checkbox';

    % == Protocol Settings ==
    S.GUI.muBarcodeDur = 0.2;
    S.GUI.sigmaBarcodeDur = 0.05;
    S.GUI.Sleep = 1;
    S.GUIMeta.Sleep.Style = 'popupmenu';
    S.GUIMeta.Sleep.String = {'Pre-sleep', 'Post-sleep', 'During-sleep', 'None'};

    %% OptoStim
    S.GUITabs.OptoStim = {'MaskLED', 'SinglePulse', 'PairedPulse'};

    S.GUIPanels.SinglePulse = {'SPduration', 'SPfrequency', 'SPamplitude', 'SPvariable', 'MaxSPfrequency'};
    S.GUIPanels.PairedPulse = {'PPduration', 'PPfrequency', 'PPamplitude', 'SPvariable', 'MaxSPfrequency'};
    S.GUIPanels.MaskLED = {'Intensity_mask', 'Duration_mask'};

    S.GUI.SPduration = 0.01;
    S.GUI.SPfrequency = 0.01;
    S.GUI.SPamplitude = 1;
    S.GUI.SPvariable = true;
    S.GUIMeta.SPvariable.Style = 'checkbox';
    S.GUI.MaxSPfrequency = 0.02;

    S.GUI.PPduration = 0.01;
    S.GUI.PPfrequency = 0.01;
    S.GUI.PPamplitude = 1;
    S.GUI.PPvariable = true;
    S.GUIMeta.PPvariable.Style = 'checkbox';
    S.GUI.MaxPPfrequency = 0.02;
    
    S.GUI.Intensity_mask = 100;
    S.GUI.Duration_mask = 0.01;
    
    %% Treatment
    S.GUITabs.Ephys = {'DrugSpecs', 'EEGSpecs', 'EphysSpecs'};
    
    S.GUIPanels.EphysSpecs = {'EphysType', 'EphysCoords'};
    S.GUI.EphysType = 1;
    S.GUIMeta.EphysType.Style = 'popupmenu';
    S.GUIMeta.EphysType.String = {'NP chronic', 'NP acute'};
    S.GUI.EphysCoords = 1;

    S.GUIPanels.EEGSpecs = {'EEGchannels', 'EMGchannels'};
    S.GUI.EEGchannels = 2;
    S.GUI.EMGchannels = 1;
    
    S.GUIPanels.DrugSpecs = {'DrugType', 'DrugDose'};
    S.GUI.DrugType = 1;
    S.GUIMeta.DrugType.Style = 'popupmenu';
    S.GUIMeta.DrugType.String = {'baclofen', 'APV', 'bicuculline', 'gabazine', 'muscimol', 'isofluorane'};
    S.GUI.DrugDose = 1;

end