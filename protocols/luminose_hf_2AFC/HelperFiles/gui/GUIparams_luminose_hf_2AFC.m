function GUIparams_luminose_hf_2AFC()
    global S
    
    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', 'maxTrials', 'Leftprob'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.ProtocolSettings = {'muBarcodeDur', 'sigmaBarcodeDur'};

    % == Training Params ==
    S.GUI.TrainingLevel = 1; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu';
    S.GUIMeta.TrainingLevel.String = {'Habituation', 'Training'};
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUI.maxTrials = 2000;  
    S.GUI.Leftprob = 0.5;
    
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
    S.GUIPanels.Stimulus = {'LeftType', 'RightType', 'StimTime'};
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', 'Punishment', ...
        'ErrorDelay', 'Amplitude_error', 'NoiseTime'};
    S.GUIPanels.ITI = {'VariableITI', 'InterTrialInterval', 'MaxITI'};
    % == CueParams ==
    S.GUI.CueType = 3;
    S.GUIMeta.CueType.Style = 'popupmenu';
    S.GUIMeta.CueType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.CueTime = 1;
    
    % == Stimulus ==
    S.GUI.LeftType = 1;
    S.GUIMeta.LeftType.Style = 'popupmenu';
    S.GUIMeta.LeftType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.RightType = 1;
    S.GUIMeta.RightType.Style = 'popupmenu';
    S.GUIMeta.RightType.String = {'Odour', 'Pattern', 'Light', 'Sound'};
    S.GUI.StimTime = 1*(0.001+1+0.001); % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    
    % == Response ==
    S.GUI.Amplitude_error = [1, 1];
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUI.ResponseTime = 1;
    S.GUI.RewardAmount = 4;
    S.GUI.Punishment = true;
    S.GUIMeta.Punishment.Style = 'checkbox';
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

    %% ===== Left =====
    S.GUITabs.Left = {'Light_Left', 'Sound_Left', 'Pattern_Left', 'Odour_Left'};
    S.GUIPanels.Odour_Left = {'valves_Left', 'dutyCycles_Left'};
    S.GUIPanels.Sound_Left = {'Amplitude_Left', 'HighFreq_Left', 'LowFreq_Left'};
    S.GUIPanels.Light_Left = {'Intensity_Left'};
    S.GUIPanels.Pattern_Left = {'Nimages_Left', 'imgIdx_Left', 'exposure_Left', 'dark_Left', 'repeat_Left'};
    % == Odour ==
    S.GUI.valves_Left = [12];
    S.GUI.dutyCycles_Left = repelem(1, 1); % specify scalar 0 to use default duty cycles
    % == Sound ==
    S.GUI.Amplitude_Left = [0.1, 0.1];
    S.GUI.HighFreq_Left = 8;   
    S.GUI.LowFreq_Left = 4;     
    % == Light ==
    S.GUI.Intensity_Left = 100;
    % == Pattern ==
    S.GUI.Nimages_Left = 4;
    S.GUI.imgIdx_Left = [1, 2, 3, 4];
    S.GUI.exposure_Left = [1e+6, 1e+6, 1e+6, 1e+6];
    S.GUI.dark_Left = [0, 0, 0, 0];
    S.GUI.repeat_Left = 1;

    %% ===== Right =====
    S.GUITabs.Right = {'Light_Right', 'Sound_Right', 'Pattern_Right', 'Odour_Right'};
    S.GUIPanels.Odour_Right = {'valves_Right', 'dutyCycles_Right'};
    S.GUIPanels.Sound_Right = {'Amplitude_Right', 'HighFreq_Right', 'LowFreq_Right'};
    S.GUIPanels.Light_Right = {'Intensity_Right'};
    S.GUIPanels.Pattern_Right = {'Nimages_Right', 'imgIdx_Right', 'exposure_Right', 'dark_Right', 'repeat_Right'};
    % == Odour ==
    S.GUI.valves_Right = [16];
    S.GUI.dutyCycles_Right = repelem(1, 1); % specify scalar 0 to use default duty cycles
    % == Sound ==
    S.GUI.Amplitude_Right = [0.1, 0.1];
    S.GUI.HighFreq_Right = 16;   
    S.GUI.LowFreq_Right = 12;     
    % == Light ==
    S.GUI.Intensity_Right = 100;
    % == Pattern ==
    S.GUI.Nimages_Right = 4;
    S.GUI.imgIdx_Right = [5, 6, 7, 8];
    S.GUI.exposure_Right = [1e+6, 1e+6, 1e+6, 1e+6];
    S.GUI.dark_Right = [0, 0, 0, 0];
    S.GUI.repeat_Right = 1;
    
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