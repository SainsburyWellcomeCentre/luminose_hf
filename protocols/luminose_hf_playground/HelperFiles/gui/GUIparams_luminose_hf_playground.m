function GUIparams_luminose_hf_playground()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TreatmentType', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', 'RepeatOnError', 'maxTrials', 'Leftprob'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUIPanels.ProtocolSettings = {'Sleep', 'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Training Params ==
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu';
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Training'};
    S.GUIMeta.TrainingLevel.Label = 'Training Level';
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUIMeta.BiasCorrection.Label = 'Bias Correction';
    S.GUI.RepeatOnError = false;
    S.GUIMeta.RepeatOnError.Style = 'checkbox';
    S.GUIMeta.RepeatOnError.Label = 'Repeat on Error';
    S.GUI.maxTrials = 2000;  
    S.GUIMeta.maxTrials.Label = 'Max Trials';
    S.GUI.Leftprob = 0.5;
    S.GUIMeta.Leftprob.Label = 'Left Probability';
    
    % == Test Pulses ==
    S.GUI.TestPulses = false;
    S.GUIMeta.TestPulses.Style = 'checkbox';
    S.GUIMeta.TestPulses.Label = 'Test Pulses';
    S.GUI.TestPulsesType = 2;
    S.GUIMeta.TestPulsesType.Style = 'popupmenu';
    S.GUIMeta.TestPulsesType.String = {'SinglePulse', 'PairedPulse'};
    S.GUIMeta.TestPulsesType.Label = 'Test Pulses Type';
    
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
    S.GUIPanels.Stimulus = {'LeftType', 'RightType', 'StimTime'};
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', 'Punishment', ...
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
    S.GUI.LeftType = 3;
    S.GUIMeta.LeftType.Style = 'popupmenu';
    S.GUIMeta.LeftType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.LeftType.Label = 'Left Stim Type';
    S.GUI.RightType = 3;
    S.GUIMeta.RightType.Style = 'popupmenu';
    S.GUIMeta.RightType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.RightType.Label = 'Right Stim Type';
    S.GUI.StimTime = 1; % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    S.GUIMeta.StimTime.Label = 'Stim Duration (s)';
    
    % == Response ==
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUIMeta.ResponseType.Label = 'Response Type';
    S.GUI.ResponseTime = 5;
    S.GUIMeta.ResponseTime.Label = 'Response Window (s)';
    S.GUI.RewardAmount = 4;
    S.GUIMeta.RewardAmount.Label = 'Reward Amount (ul)';
    S.GUI.Punishment = true;
    S.GUIMeta.Punishment.Style = 'checkbox';
    S.GUIMeta.Punishment.Label = 'Enable Punishment';
    S.GUI.ErrorDelay = 5;
    S.GUIMeta.ErrorDelay.Label = 'Error ITI Delay (s)';
    S.GUI.NoiseTime = 1; % must be less than error delay
    S.GUIMeta.NoiseTime.Label = 'White Noise Dur (s)';

    % == ITI ==
    S.GUI.VariableITI = true;
    S.GUIMeta.VariableITI.Style = 'checkbox';
    S.GUIMeta.VariableITI.Label = 'Variable ITI';
    S.GUI.InterTrialInterval = 2;
    S.GUIMeta.InterTrialInterval.Label = 'Mean ITI (s)';
    S.GUI.MaxITI = 3;
    S.GUIMeta.MaxITI.Label = 'Max ITI (s)';

    %% ===== Cue =====
    S.GUITabs.Cue = {'Light_cue', 'Sound_cue', 'Odour_cue', 'Pattern_cue'};
    S.GUIPanels.Light_cue = {'Intensity_cue'};
    S.GUIPanels.Sound_cue = {'Freq_cue'};
    S.GUIPanels.Odour_cue = {'valves_cue'};
    S.GUIPanels.Pattern_cue = {'imgIdx_cue', 'exposure_cue', 'DesignPattern_cue'};
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
    S.GUI.DesignPattern_cue = 0;
    S.GUIMeta.DesignPattern_cue.Style       = 'pushbutton';
    S.GUIMeta.DesignPattern_cue.String      = 'Design Pattern...';
    S.GUIMeta.DesignPattern_cue.Callback    = 'PatternDesignerGUI';
    S.GUIMeta.DesignPattern_cue.CallbackArg = 'cue';
    S.GUIMeta.DesignPattern_cue.Label       = '';
    S.GUI.nFrames_cue = 1;
    S.GUIMeta.nFrames_cue.Hidden = true;

    %% ===== Left =====
    S.GUITabs.Left = {'Light_Left', 'Sound_Left', 'Odour_Left', 'Pattern_Left'};
    S.GUIPanels.Light_Left = {'Intensity_Left'};
    S.GUIPanels.Sound_Left = {'HighFreq_Left', 'LowFreq_Left'};
    S.GUIPanels.Odour_Left = {'valves_Left'};
    S.GUIPanels.Pattern_Left = {'imgIdx_Left', 'exposure_Left', 'DesignPattern_Left'};
    % == Light ==
    S.GUI.Intensity_Left = 100;
    S.GUIMeta.Intensity_Left.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_Left = 8;   
    S.GUIMeta.HighFreq_Left.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_Left = 4;     
    S.GUIMeta.LowFreq_Left.Label = 'Low Freq (Hz)';
    % == Odour ==
    S.GUI.valves_Left = [11];
    S.GUIMeta.valves_Left.Style = 'odour_selector';
    S.GUIMeta.valves_Left.ProbParam = 'probs_Left';
    S.GUIMeta.valves_Left.DutyParam = 'dutyCycles_Left';
    S.GUIMeta.valves_Left.Label = 'Valves';
    S.GUI.dutyCycles_Left = [1]; 
    S.GUI.probs_Left = [1];
    % == Pattern ==
    S.GUI.imgIdx_Left = 1;
    S.GUIMeta.imgIdx_Left.Label = 'Image Index';
    S.GUI.exposure_Left = 1e+6;
    S.GUIMeta.exposure_Left.Label = 'Exposure (us)';
    S.GUI.DesignPattern_Left = 0;
    S.GUIMeta.DesignPattern_Left.Style       = 'pushbutton';
    S.GUIMeta.DesignPattern_Left.String      = 'Design Pattern...';
    S.GUIMeta.DesignPattern_Left.Callback    = 'PatternDesignerGUI';
    S.GUIMeta.DesignPattern_Left.CallbackArg = 'Left';
    S.GUIMeta.DesignPattern_Left.Label       = '';
    S.GUI.nFrames_Left = 1;
    S.GUIMeta.nFrames_Left.Hidden = true;

    %% ===== Right =====
    S.GUITabs.Right = {'Light_Right', 'Sound_Right', 'Odour_Right', 'Pattern_Right'};
    S.GUIPanels.Light_Right = {'Intensity_Right'};
    S.GUIPanels.Sound_Right = {'HighFreq_Right', 'LowFreq_Right'};
    S.GUIPanels.Odour_Right = {'valves_Right'};
    S.GUIPanels.Pattern_Right = {'imgIdx_Right', 'exposure_Right', 'DesignPattern_Right'};
    % == Light ==
    S.GUI.Intensity_Right = 100;
    S.GUIMeta.Intensity_Right.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_Right = 16;   
    S.GUIMeta.HighFreq_Right.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_Right = 12;     
    S.GUIMeta.LowFreq_Right.Label = 'Low Freq (Hz)';
    % == Odour ==
    S.GUI.valves_Right = [16];
    S.GUIMeta.valves_Right.Style = 'odour_selector';
    S.GUIMeta.valves_Right.ProbParam = 'probs_Right';
    S.GUIMeta.valves_Right.DutyParam = 'dutyCycles_Right';
    S.GUIMeta.valves_Right.Label = 'Valves';
    S.GUI.dutyCycles_Right = [1]; 
    S.GUI.probs_Right = [1];
    % == Pattern ==
    S.GUI.imgIdx_Right = 2;
    S.GUIMeta.imgIdx_Right.Label = 'Image Index';
    S.GUI.exposure_Right = 1e+6;
    S.GUIMeta.exposure_Right.Label = 'Exposure (us)';
    S.GUI.DesignPattern_Right = 0;
    S.GUIMeta.DesignPattern_Right.Style       = 'pushbutton';
    S.GUIMeta.DesignPattern_Right.String      = 'Design Pattern...';
    S.GUIMeta.DesignPattern_Right.Callback    = 'PatternDesignerGUI';
    S.GUIMeta.DesignPattern_Right.CallbackArg = 'Right';
    S.GUIMeta.DesignPattern_Right.Label       = '';
    S.GUI.nFrames_Right = 1;
    S.GUIMeta.nFrames_Right.Hidden = true;
    
    %% OptoStim
    S.GUITabs.OptoStim = {'MaskLED', 'SinglePulse', 'PairedPulse'};
    S.GUIPanels.SinglePulse = {'SPduration', 'SPfrequency', 'SPamplitude'};
    S.GUIPanels.PairedPulse = {'PPduration', 'PPfrequency', 'PPamplitude'};
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