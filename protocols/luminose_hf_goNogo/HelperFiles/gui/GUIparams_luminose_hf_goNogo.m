function GUIparams_luminose_hf_goNogo()
    global S BpodSystem
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', ...
        'maxTrials'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.ProtocolSettings = {'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Training Params ==
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu';
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Training'};
    S.GUI.BiasCorrection = false;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUI.maxTrials = 1000;    
    
    % == Test Pulses ==
    S.GUI.TestPulses = true;
    S.GUIMeta.TestPulses.Style = 'checkbox';
    S.GUI.TestPulsesType = 2;
    S.GUIMeta.TestPulsesType.Style = 'popupmenu';
    S.GUIMeta.TestPulsesType.String = {'SinglePulse', 'PairedPulse'};
    
    % == Protocol Settings ==
    S.GUI.muBarcodeDur = 0.2;
    S.GUI.sigmaBarcodeDur = 0.05;

    %% ===== Task =====
    S.GUITabs.Task = {'ITI', 'Response', 'Stimulus', 'CueParams'};
    S.GUIPanels.CueParams = {'CueType', 'CueTime'};
    S.GUIPanels.Stimulus = {'CSplusType', 'CSminusType', 'StimTime'};
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', 'ErrorDelay', ...
        'Amplitude_error', 'NoiseTime', 'SoundSamplingRate'};
    S.GUIPanels.ITI = {'VariableITI', 'InterTrialInterval', 'MaxITI'};
    % == CueParams ==
    S.GUI.CueType = 4;
    S.GUIMeta.CueType.Style = 'popupmenu';
    S.GUIMeta.CueType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.CueTime = 1;
    
    % == Stimulus ==
    S.GUI.CSplusType = 2;
    S.GUIMeta.CSplusType.Style = 'popupmenu';
    S.GUIMeta.CSplusType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.CSminusType = 2;
    S.GUIMeta.CSminusType.Style = 'popupmenu';
    S.GUIMeta.CSminusType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.StimTime = 10;
    
    % == Response ==
    S.GUI.SoundSamplingRate = 192000;
    S.GUI.Amplitude_error = [1, 1];
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUI.ResponseTime = 2;
    S.GUI.RewardAmount = 10;
    S.GUI.ErrorDelay = 1;
    S.GUI.NoiseTime = 0.6; % must be less than error delay

    % == ITI ==
    S.GUI.VariableITI = true;
    S.GUI.InterTrialInterval = 5;
    S.GUIMeta.VariableITI.Style = 'checkbox';
    S.GUI.MaxITI = 10;

    %% ===== Cue =====
    S.GUITabs.Cue = {'Pattern', 'Odour', 'Light', 'Sound'};
    S.GUIPanels.Odour = {'valves_cue', 'dutyCycles_cue', 'label_cue'};
    S.GUIPanels.Sound = {'Amplitude_cue', 'HighFreq_cue', 'LowFreq_cue'};
    S.GUIPanels.Light = {'Intensity_cue'};
    S.GUIPanels.Pattern = {'Nimages_cue', 'imgIdx_cue', 'exposure_cue', 'dark_cue', 'repeat_cue'};
    % == Odour ==
    S.GUI.valves_cue = [12];
    S.GUI.dutyCycles_cue = 0; % specify scalar 0 to use default duty cycles
    S.GUI.label_cue = 'cue';
    % == Sound ==
    S.GUI.Amplitude_cue = [0.001, 0.001];
    S.GUI.Freq_cue = 5000;     
    % == Light ==
    S.GUI.Intensity_cue = 100;
    % == Pattern ==
    S.GUI.Nimages_cue = 4;
    S.GUI.imgIdx_cue = [1, 8, 3, 6];
    S.GUI.exposure_cue = [1e+6, 1e+6, 1e+6, 1e+6];
    S.GUI.dark_cue = [0, 0, 0, 0];
    S.GUI.repeat_cue = 1;

    %% ===== CS+ =====
    S.GUITabs.CSplus = {'Light', 'Sound', 'Pattern', 'Odour'};
    S.GUIPanels.Odour = {'valves_CSplus', 'dutyCycles_CSplus', 'label_CSplus'};
    S.GUIPanels.Sound = {'Amplitude_CSplus', 'HighFreq_CSplus', 'LowFreq_CSplus'};
    S.GUIPanels.Light = {'Intensity_CSplus'};
    S.GUIPanels.Pattern = {'Nimages_CSplus', 'imgIdx_CSplus', 'exposure_CSplus', 'dark_CSplus', 'repeat_CSplus'};
    % == Odour ==
    S.GUI.valves_CSplus = [12];
    S.GUI.dutyCycles_CSplus = repelem(1, 1); % specify scalar 0 to use default duty cycles
    S.GUI.label_CSplus = 'CSplus';
    % == Sound ==
    S.GUI.Amplitude_CSplus = [0.1, 0.1];
    S.GUI.HighFreq_CSplus = 8;   
    S.GUI.LowFreq_CSplus = 4;     
    % == Light ==
    S.GUI.Intensity_CSplus = 100;
    % == Pattern ==
    S.GUI.Nimages_CSplus = 4;
    S.GUI.imgIdx_CSplus = [1, 2, 3, 4];
    S.GUI.exposure_CSplus = [1e+6, 1e+6, 1e+6, 1e+6];
    S.GUI.dark_CSplus = [0, 0, 0, 0];
    S.GUI.repeat_CSplus = 1;

    %% ===== CS- =====
    S.GUITabs.CSminus = {'Light', 'Sound', 'Pattern', 'Odour'};
    S.GUIPanels.Odour = {'valves_CSminus', 'dutyCycles_CSminus', 'label_CSminus'};
    S.GUIPanels.Sound = {'Amplitude_CSminus', 'HighFreq_CSminus', 'LowFreq_CSminus'};
    S.GUIPanels.Light = {'Intensity_CSminus'};
    S.GUIPanels.Pattern = {'Nimages_CSminus', 'imgIdx_CSminus', 'exposure_CSminus', 'dark_CSminus', 'repeat_CSminus'};
    % == Odour ==
    S.GUI.valves_CSminus = [16];
    S.GUI.dutyCycles_CSminus = repelem(1, 1); % specify scalar 0 to use default duty cycles
    S.GUI.label_CSminus = 'CSminus';
    % == Sound ==
    S.GUI.Amplitude_CSminus = [0.1, 0.1];
    S.GUI.HighFreq_CSminus = 16;   
    S.GUI.LowFreq_CSminus = 12;     
    % == Light ==
    S.GUI.Intensity_CSminus = 100;
    % == Pattern ==
    S.GUI.Nimages_CSminus = 4;
    S.GUI.imgIdx_CSminus = [5, 6, 7, 8];
    S.GUI.exposure_CSminus = [1e+6, 1e+6, 1e+6, 1e+6];
    S.GUI.dark_CSminus = [0, 0, 0, 0];
    S.GUI.repeat_CSminus = 1;
    
    %% OptoStim
    S.GUITabs.OptoStim = {'MaskLED', 'SinglePulse', 'PairedPulse'};
    S.GUIPanels.SinglePulse = {'SPduration', 'SPfrequency', 'SPamplitude'};
    S.GUIPanels.PairedPulse = {'PPduration', 'PPfrequency', 'PPamplitude'};
    S.GUIPanels.MaskLED = {'Intensity_mask', 'Duration_mask'};
    S.GUI.SPduration = 1000;
    S.GUI.SPfrequency = 1;
    S.GUI.SPamplitude = 1;
    S.GUI.PPduration = 1000;
    S.GUI.PPfrequency = 1;
    S.GUI.PPamplitude = 1;
    S.GUI.Intensity_mask = 100;
    S.GUI.Duration_mask = S.GUI.StimTime;
    
    %% Treatment
    S.GUITabs.Ephys = {'DrugSpecs', 'EEGSpecs', 'EphysSpecs', 'TreatmentType'};
    
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUI.Ephys = false;
    S.GUIMeta.Ephys.Style = 'checkbox';
    S.GUI.EEG = false;
    S.GUIMeta.EEG.Style = 'checkbox';
    S.GUI.Drug = false;
    S.GUIMeta.Drug.Style = 'checkbox';
    
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
    S.GUIMeta.DrugType.String = {'muscimol', 'isofluorane'};
    S.GUI.DrugDose = 1;

end