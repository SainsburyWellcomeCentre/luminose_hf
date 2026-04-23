function GUIparams_luminose_hf_goNogo()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TreatmentType', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', 'RepeatOnError', 'CSplus_prob', 'maxTrials'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUIPanels.ProtocolSettings = {'Sleep', 'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Training Params ==
    S.GUI.TrainingLevel = 2; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu';
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Training'};
    S.GUIMeta.TrainingLevel.Label = 'Training Level';
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUIMeta.BiasCorrection.Label = 'Bias Correction';
    S.GUI.RepeatOnError = false;
    S.GUIMeta.RepeatOnError.Style = 'checkbox';
    S.GUIMeta.RepeatOnError.Label = 'Repeat on Error';
    S.GUI.CSplus_prob = 0.5;
    S.GUIMeta.CSplus_prob.Label = 'CS+ Probability';
    S.GUI.maxTrials = 1000;    
    S.GUIMeta.maxTrials.Label = 'Max Trials';
    
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

    %% ===== Task =====
    S.GUITabs.Task = {'ITI', 'Response', 'Stimulus', 'CueParams'};
    S.GUIPanels.CueParams = {'CueType', 'CueTime'};
    S.GUIPanels.Stimulus = {'CSplusType', 'CSminusType', 'StimTime'};
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', ...
        'ErrorDelay', 'NoiseTime'};
    S.GUIPanels.ITI = {'VariableITI', 'InterTrialInterval', 'MaxITI'};
    % == CueParams ==
    S.GUI.CueType = 1;
    S.GUIMeta.CueType.Style = 'popupmenu';
    S.GUIMeta.CueType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.CueType.Label = 'Cue Type';
    S.GUI.CueTime = 1;
    S.GUIMeta.CueTime.Label = 'Cue Duration (s)';
    
    % == Stimulus ==
    S.GUI.CSplusType = 3;
    S.GUIMeta.CSplusType.Style = 'popupmenu';
    S.GUIMeta.CSplusType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.CSplusType.Label = 'CS+ Type';
    S.GUI.CSminusType = 3;
    S.GUIMeta.CSminusType.Style = 'popupmenu';
    S.GUIMeta.CSminusType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.CSminusType.Label = 'CS- Type';
    S.GUI.StimTime = 1; % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    S.GUIMeta.StimTime.Label = 'Stim Duration (s)';
    
    % == Response ==
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUIMeta.ResponseType.Label = 'Response Type';
    S.GUI.ResponseTime = 2;
    S.GUIMeta.ResponseTime.Label = 'Response Window (s)';
    S.GUI.RewardAmount = 2;
    S.GUIMeta.RewardAmount.Label = 'Reward Amount (ul)';
    S.GUI.ErrorDelay = 5;
    S.GUIMeta.ErrorDelay.Label = 'Error ITI Delay (s)';
    S.GUI.NoiseTime = 1; % must be less than error delay
    S.GUIMeta.NoiseTime.Label = 'White Noise Dur (s)';

    % == ITI ==
    S.GUI.VariableITI = true;
    S.GUIMeta.VariableITI.Style = 'checkbox';
    S.GUIMeta.VariableITI.Label = 'Variable ITI';
    S.GUI.InterTrialInterval = 5;
    S.GUIMeta.InterTrialInterval.Label = 'Mean ITI (s)';
    S.GUI.MaxITI = 6;
    S.GUIMeta.MaxITI.Label = 'Max ITI (s)';

    %% ===== Cue =====
    S.GUITabs.Cue = {'Light_cue', 'Sound_cue', 'Odour_cue', 'Pattern_cue'};
    S.GUIPanels.Light_cue = {'Intensity_cue'};
    S.GUIPanels.Sound_cue = {'Freq_cue'};
    S.GUIPanels.Odour_cue = {'valves_cue'};
    S.GUIPanels.Pattern_cue = {'imgIdx_cue', 'exposure_cue'};
    % == Light ==
    S.GUI.Intensity_cue = 100;
    S.GUIMeta.Intensity_cue.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.Freq_cue = 5000;   
    S.GUIMeta.Freq_cue.Label = 'Frequency (Hz)';
    % == Odour ==
    S.GUI.valves_cue = [7];
    S.GUIMeta.valves_cue.Style = 'odour_selector';
    S.GUIMeta.valves_cue.ProbParam = 'probs_cue';
    S.GUIMeta.valves_cue.DutyParam = 'dutyCycles_cue';
    S.GUIMeta.valves_cue.Label = 'Valves';
    S.GUI.dutyCycles_cue = [1]; 
    S.GUI.probs_cue = [1];
    % == Pattern ==
    S.GUI.imgIdx_cue = 1;
    S.GUIMeta.imgIdx_cue.Label = 'Image Index';
    S.GUI.exposure_cue = 1e+6;
    S.GUIMeta.exposure_cue.Label = 'Exposure (us)';

    %% ===== CS+ =====
    S.GUITabs.CSplus = {'Light_CSplus', 'Sound_CSplus', 'Odour_CSplus', 'Pattern_CSplus'};
    S.GUIPanels.Light_CSplus = {'Intensity_CSplus'};
    S.GUIPanels.Sound_CSplus = {'HighFreq_CSplus', 'LowFreq_CSplus'};
    S.GUIPanels.Odour_CSplus = {'valves_CSplus'};
    S.GUIPanels.Pattern_CSplus = {'imgIdx_CSplus', 'exposure_CSplus'};
    % == Light ==
    S.GUI.Intensity_CSplus = 100;
    S.GUIMeta.Intensity_CSplus.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_CSplus = 8;   
    S.GUIMeta.HighFreq_CSplus.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_CSplus = 4;     
    S.GUIMeta.LowFreq_CSplus.Label = 'Low Freq (Hz)';
    % == Odour ==
    S.GUI.valves_CSplus = [11]; 
    S.GUIMeta.valves_CSplus.Style = 'odour_selector';
    S.GUIMeta.valves_CSplus.ProbParam = 'probs_CSplus';
    S.GUIMeta.valves_CSplus.DutyParam = 'dutyCycles_CSplus';
    S.GUIMeta.valves_CSplus.Label = 'Valves';
    S.GUI.dutyCycles_CSplus = [1]; 
    S.GUI.probs_CSplus = [1];
    % == Pattern ==
    S.GUI.imgIdx_CSplus = 1;
    S.GUIMeta.imgIdx_CSplus.Label = 'Image Index';
    S.GUI.exposure_CSplus = 1e+6;
    S.GUIMeta.exposure_CSplus.Label = 'Exposure (us)';

    %% ===== CS- =====
    S.GUITabs.CSminus = {'Light_CSminus', 'Sound_CSminus', 'Odour_CSminus', 'Pattern_CSminus'};
    S.GUIPanels.Light_CSminus = {'Intensity_CSminus'};
    S.GUIPanels.Sound_CSminus = {'HighFreq_CSminus', 'LowFreq_CSminus'};
    S.GUIPanels.Odour_CSminus = {'valves_CSminus'};
    S.GUIPanels.Pattern_CSminus = {'imgIdx_CSminus', 'exposure_CSminus'};
    % == Light ==
    S.GUI.Intensity_CSminus = 100;
    S.GUIMeta.Intensity_CSminus.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_CSminus = 16;   
    S.GUIMeta.HighFreq_CSminus.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_CSminus = 12;     
    S.GUIMeta.LowFreq_CSminus.Label = 'Low Freq (Hz)';
    % == Odour ==
    S.GUI.valves_CSminus = [16];
    S.GUIMeta.valves_CSminus.Style = 'odour_selector';
    S.GUIMeta.valves_CSminus.ProbParam = 'probs_CSminus';
    S.GUIMeta.valves_CSminus.DutyParam = 'dutyCycles_CSminus';
    S.GUIMeta.valves_CSminus.Label = 'Valves';
    S.GUI.dutyCycles_CSminus = [1]; 
    S.GUI.probs_CSminus = [1];
    % == Pattern ==
    S.GUI.imgIdx_CSminus = 2;
    S.GUIMeta.imgIdx_CSminus.Label = 'Image Index';
    S.GUI.exposure_CSminus = 1e+6;
    S.GUIMeta.exposure_CSminus.Label = 'Exposure (us)';
    
    %% OptoStim
    S.GUITabs.OptoStim = {'MaskLED', 'SinglePulse', 'PairedPulse'};
    S.GUIPanels.SinglePulse = {'SPduration', 'SPfrequency', 'SPamplitude'};
    S.GUIPanels.PairedPulse = {'PPfrequency', 'PPamplitude', 'PPduration'};
    S.GUIPanels.MaskLED = {'Intensity_mask', 'Duration_mask'};
    S.GUI.SPduration = 1000;
    S.GUIMeta.SPduration.Label = 'Duration (ms)';
    S.GUI.SPfrequency = 1;
    S.GUIMeta.SPfrequency.Label = 'Freq (Hz)';
    S.GUI.SPamplitude = 1;
    S.GUIMeta.SPamplitude.Label = 'Amp (V)';
    S.GUI.PPduration = 1000;
    S.GUIMeta.PPduration.Label = 'Duration (ms)';
    S.GUI.PPfrequency = 1;
    S.GUIMeta.PPfrequency.Label = 'Freq (Hz)';
    S.GUI.PPamplitude = 1;
    S.GUIMeta.PPamplitude.Label = 'Amp (V)';
    S.GUI.Intensity_mask = 100;
    S.GUIMeta.Intensity_mask.Label = 'Intensity (0-255)';
    S.GUI.Duration_mask = S.GUI.StimTime;
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