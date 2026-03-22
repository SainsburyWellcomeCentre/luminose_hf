function GUIparams_luminose_hf_goNogo()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', 'CSplus_prob', 'maxTrials'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.ProtocolSettings = {'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Training Params ==
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu';
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Training'};
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUI.CSplus_prob = 1;
    S.GUI.maxTrials = 1000;    
    
    % == Test Pulses ==
    S.GUI.TestPulses = false;
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
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', ...
        'ErrorDelay', 'Amplitude_error', 'NoiseTime'};
    S.GUIPanels.ITI = {'VariableITI', 'InterTrialInterval', 'MaxITI'};
    % == CueParams ==
    S.GUI.CueType = 3;
    S.GUIMeta.CueType.Style = 'popupmenu';
    S.GUIMeta.CueType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.CueTime = 1;
    
    % == Stimulus ==
    S.GUI.CSplusType = 1;
    S.GUIMeta.CSplusType.Style = 'popupmenu';
    S.GUIMeta.CSplusType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.CSminusType = 1;
    S.GUIMeta.CSminusType.Style = 'popupmenu';
    S.GUIMeta.CSminusType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.StimTime = 1*(0.001+1+0.001); % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    
    % == Response ==
    S.GUI.Amplitude_error = [1, 1];
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUI.ResponseTime = 1;
    S.GUI.RewardAmount = 4;
    S.GUI.ErrorDelay = 5;
    S.GUI.NoiseTime = 1; % must be less than error delay

    % == ITI ==
    S.GUI.VariableITI = true;
    S.GUI.InterTrialInterval = 5;
    S.GUIMeta.VariableITI.Style = 'checkbox';
    S.GUI.MaxITI = 6;

    %% ===== Cue =====
    S.GUITabs.Cue = {'Pattern_cue', 'Odour_cue', 'Light_cue', 'Sound_cue'};
    S.GUIPanels.Odour_cue = {'valves_cue', 'dutyCycles_cue'};
    S.GUIPanels.Sound_cue = {'Amplitude_cue', 'Freq_cue'};
    S.GUIPanels.Light_cue = {'Intensity_cue'};
    S.GUIPanels.Pattern_cue = {'Nimages_cue', 'imgIdx_cue', 'exposure_cue', 'dark_cue', 'repeat_cue'};
    % == Odour ==
    S.GUI.valves_cue = [7];
    S.GUI.dutyCycles_cue = repelem(1, 1); % specify scalar 0 to use default duty cycles
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
    S.GUITabs.CSplus = {'Light_CSplus', 'Sound_CSplus', 'Pattern_CSplus', 'Odour_CSplus'};
    S.GUIPanels.Odour_CSplus = {'valves_CSplus', 'dutyCycles_CSplus'};
    S.GUIPanels.Sound_CSplus = {'Amplitude_CSplus', 'HighFreq_CSplus', 'LowFreq_CSplus'};
    S.GUIPanels.Light_CSplus = {'Intensity_CSplus'};
    S.GUIPanels.Pattern_CSplus = {'Nimages_CSplus', 'imgIdx_CSplus', 'exposure_CSplus', 'dark_CSplus', 'repeat_CSplus'};
    % == Odour ==
    S.GUI.valves_CSplus = [11];
    S.GUI.dutyCycles_CSplus = repelem(1, 1); % specify scalar 0 to use default duty cycles
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
    S.GUITabs.CSminus = {'Light_CSminus', 'Sound_CSminus', 'Pattern_CSminus', 'Odour_CSminus'};
    S.GUIPanels.Odour_CSminus = {'valves_CSminus', 'dutyCycles_CSminus'};
    S.GUIPanels.Sound_CSminus = {'Amplitude_CSminus', 'HighFreq_CSminus', 'LowFreq_CSminus'};
    S.GUIPanels.Light_CSminus = {'Intensity_CSminus'};
    S.GUIPanels.Pattern_CSminus = {'Nimages_CSminus', 'imgIdx_CSminus', 'exposure_CSminus', 'dark_CSminus', 'repeat_CSminus'};
    % == Odour ==
    S.GUI.valves_CSminus = [16];
    S.GUI.dutyCycles_CSminus = repelem(1, 1); % specify scalar 0 to use default duty cycles
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
    S.GUIMeta.DrugType.String = {'baclofen', 'APV', 'bicuculline', 'gabazine', 'muscimol', 'isofluorane'};
    S.GUI.DrugDose = 1;

end