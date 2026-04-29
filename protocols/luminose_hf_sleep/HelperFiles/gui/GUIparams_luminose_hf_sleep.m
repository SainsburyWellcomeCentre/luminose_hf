function GUIparams_luminose_hf_sleep()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TreatmentType', 'TestPulses', 'TrialParams'};
    S.GUIPanels.TrialParams = {'maxTrials', 'Typeprob', 'ITImin', 'ITImax'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUIPanels.ProtocolSettings = {'Sleep', 'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Trial Params ==
    S.GUI.maxTrials = 10000;  
    S.GUIMeta.maxTrials.Label = 'Max Trials';
    S.GUI.Typeprob = 0.5;
    S.GUIMeta.Typeprob.Label = 'Type 1 Probability';
    S.GUI.ITImin = 2;
    S.GUIMeta.ITImin.Label = 'ITI Min (s)';
    S.GUI.ITImax = 5;
    S.GUIMeta.ITImax.Label = 'ITI Max (s)';
    
    % == Test Pulses ==
    S.GUI.TestPulses = false;
    S.GUIMeta.TestPulses.Style = 'checkbox';
    S.GUIMeta.TestPulses.Label = 'Test Pulses';
    S.GUI.TestPulsesType = 2;
    S.GUIMeta.TestPulsesType.Style = 'popupmenu';
    S.GUIMeta.TestPulsesType.String = {'SinglePulse', 'PairedPulse'};
    S.GUIMeta.TestPulsesType.Label = 'Pulse Type';
    
    % == Treatment Type ==
    S.GUI.Ephys = false;
    S.GUIMeta.Ephys.Style = 'checkbox';
    S.GUIMeta.Ephys.Label = 'Ephys';
    S.GUI.EEG = false;
    S.GUIMeta.EEG.Style = 'checkbox';
    S.GUIMeta.EEG.Label = 'EEG';
    S.GUI.Drug = false;
    S.GUIMeta.Drug.Style = 'checkbox';
    S.GUIMeta.Drug.Label = 'Drug';

    % == Protocol Settings ==
    S.GUI.muBarcodeDur = 0.2;
    S.GUIMeta.muBarcodeDur.Label = 'Barcode mean';
    S.GUI.sigmaBarcodeDur = 0.05;
    S.GUIMeta.sigmaBarcodeDur.Label = 'Barcode std';
    S.GUI.Sleep = 1;
    S.GUIMeta.Sleep.Style = 'popupmenu';
    S.GUIMeta.Sleep.String = {'Pre-sleep', 'Post-sleep', 'During-sleep', 'None'};
    S.GUIMeta.Sleep.Label = 'Sleep Phase';

    %% OptoStim
    S.GUITabs.OptoStim = {'Pattern_Type1', 'Pattern_Type2', 'MaskLED', 'SinglePulse', 'PairedPulse'};

    S.GUIPanels.Pattern_Type1  = {'imgIdx_CSplus',  'exposure_CSplus',  'DesignPattern_CSplus'};
    S.GUIPanels.Pattern_Type2 = {'imgIdx_CSminus', 'exposure_CSminus', 'DesignPattern_CSminus'};

    S.GUI.imgIdx_CSplus = 1;
    S.GUIMeta.imgIdx_CSplus.Label = 'Image Index (Type 1)';
    S.GUI.exposure_CSplus = 1e+6;
    S.GUIMeta.exposure_CSplus.Label = 'Exposure (us, Type 1)';
    S.GUI.DesignPattern_CSplus = 0;
    S.GUIMeta.DesignPattern_CSplus.Style       = 'pushbutton';
    S.GUIMeta.DesignPattern_CSplus.String      = 'Design Pattern...';
    S.GUIMeta.DesignPattern_CSplus.Callback    = 'PatternDesignerGUI';
    S.GUIMeta.DesignPattern_CSplus.CallbackArg = 'CSplus';
    S.GUIMeta.DesignPattern_CSplus.Label       = '';
    S.GUI.nFrames_CSplus = 1;
    S.GUIMeta.nFrames_CSplus.Hidden = true;

    S.GUI.imgIdx_CSminus = 2;
    S.GUIMeta.imgIdx_CSminus.Label = 'Image Index (Type 2)';
    S.GUI.exposure_CSminus = 1e+6;
    S.GUIMeta.exposure_CSminus.Label = 'Exposure (us, Type 2)';
    S.GUI.DesignPattern_CSminus = 0;
    S.GUIMeta.DesignPattern_CSminus.Style       = 'pushbutton';
    S.GUIMeta.DesignPattern_CSminus.String      = 'Design Pattern...';
    S.GUIMeta.DesignPattern_CSminus.Callback    = 'PatternDesignerGUI';
    S.GUIMeta.DesignPattern_CSminus.CallbackArg = 'CSminus';
    S.GUIMeta.DesignPattern_CSminus.Label       = '';
    S.GUI.nFrames_CSminus = 1;
    S.GUIMeta.nFrames_CSminus.Hidden = true;

    S.GUIPanels.SinglePulse = {'SPduration', 'SPfrequency', 'SPamplitude', 'SPvariable', 'MaxSPfrequency'};
    S.GUIPanels.PairedPulse = {'PPduration', 'PPfrequency', 'PPamplitude', 'PPvariable', 'MaxPPfrequency'};
    S.GUIPanels.MaskLED = {'Intensity_mask', 'Duration_mask'};

    S.GUI.SPduration = 0.01;
    S.GUIMeta.SPduration.Label = 'Duration (ms)';
    S.GUI.SPfrequency = 0.01;
    S.GUIMeta.SPfrequency.Label = 'Freq (Hz)';
    S.GUI.SPamplitude = 1;
    S.GUIMeta.SPamplitude.Label = 'Amp (V)';
    S.GUI.SPvariable = true;
    S.GUIMeta.SPvariable.Style = 'checkbox';
    S.GUIMeta.SPvariable.Label = 'Variable Freq';
    S.GUI.MaxSPfrequency = 0.02;
    S.GUIMeta.MaxSPfrequency.Label = 'Max Freq (Hz)';

    S.GUI.PPduration = 0.01;
    S.GUIMeta.PPduration.Label = 'Duration (ms)';
    S.GUI.PPfrequency = 0.01;
    S.GUIMeta.PPfrequency.Label = 'Freq (Hz)';
    S.GUI.PPamplitude = 1;
    S.GUIMeta.PPamplitude.Label = 'Amp (V)';
    S.GUI.PPvariable = true;
    S.GUIMeta.PPvariable.Style = 'checkbox';
    S.GUIMeta.PPvariable.Label = 'Variable Freq';
    S.GUI.MaxPPfrequency = 0.02;
    S.GUIMeta.MaxPPfrequency.Label = 'Max Freq (Hz)';
    
    S.GUI.Intensity_mask = 100;
    S.GUIMeta.Intensity_mask.Label = 'Intensity (0-255)';
    S.GUI.Duration_mask = 0.01;
    S.GUIMeta.Duration_mask.Label = 'Duration (s)';
    
    %% Treatment
    S.GUITabs.Ephys = {'DrugSpecs', 'EEGSpecs', 'EphysSpecs'};
    
    S.GUIPanels.EphysSpecs = {'EphysType', 'EphysCoords'};
    S.GUI.EphysType = 1;
    S.GUIMeta.EphysType.Style = 'popupmenu';
    S.GUIMeta.EphysType.String = {'NP chronic', 'NP acute'};
    S.GUIMeta.EphysType.Label = 'Probe Type';
    S.GUI.EphysCoords = 1;
    S.GUIMeta.EphysCoords.Label = 'Coordinates';

    S.GUIPanels.EEGSpecs = {'EEGchannels', 'EMGchannels'};
    S.GUI.EEGchannels = 2;
    S.GUIMeta.EEGchannels.Label = 'EEG Channels';
    S.GUI.EMGchannels = 1;
    S.GUIMeta.EMGchannels.Label = 'EMG Channels';
    
    S.GUIPanels.DrugSpecs = {'DrugType', 'DrugDose'};
    S.GUI.DrugType = 1;
    S.GUIMeta.DrugType.Style = 'popupmenu';
    S.GUIMeta.DrugType.String = {'baclofen', 'APV', 'bicuculline', 'gabazine', 'muscimol', 'isofluorane'};
    S.GUIMeta.DrugType.Label = 'Drug Compound';
    S.GUI.DrugDose = 1;
    S.GUIMeta.DrugDose.Label = 'Dose (mg/kg)';

end