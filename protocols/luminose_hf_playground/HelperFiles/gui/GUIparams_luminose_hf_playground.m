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
    S.GUI.BiasCorrection = true;
    S.GUIMeta.BiasCorrection.Style = 'checkbox';
    S.GUI.RepeatOnError = false;
    S.GUIMeta.RepeatOnError.Style = 'checkbox';
    S.GUI.maxTrials = 2000;  
    S.GUI.Leftprob = 0.5;
    
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

    %% ===== Task =====
    S.GUITabs.Task = {'ITI', 'Response', 'Stimulus', 'CueParams'};
    S.GUIPanels.CueParams = {'CueType', 'CueTime'};
    S.GUIPanels.Stimulus = {'LeftType', 'RightType', 'StimTime'};
    S.GUIPanels.Response = {'ResponseType', 'ResponseTime', 'RewardAmount', 'Punishment', ...
        'ErrorDelay', 'Amplitude_error', 'NoiseTime'};
    S.GUIPanels.ITI = {'VariableITI', 'InterTrialInterval', 'MaxITI'};
    % == CueParams ==
    S.GUI.CueType = 1;
    S.GUIMeta.CueType.Style = 'popupmenu';
    S.GUIMeta.CueType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUI.CueTime = 1;
    
    % == Stimulus ==
    S.GUI.LeftType = 3;
    S.GUIMeta.LeftType.Style = 'popupmenu';
    S.GUIMeta.LeftType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUI.RightType = 3;
    S.GUIMeta.RightType.Style = 'popupmenu';
    S.GUIMeta.RightType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUI.StimTime = 1*(0.001+1+0.001); % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    
    % == Response ==
    S.GUI.Amplitude_error = [1, 1];
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUI.ResponseTime = 5;
    S.GUI.RewardAmount = 4;
    S.GUI.Punishment = true;
    S.GUIMeta.Punishment.Style = 'checkbox';
    S.GUI.ErrorDelay = 5;
    S.GUI.NoiseTime = 1; % must be less than error delay

    % == ITI ==
    S.GUI.VariableITI = true;
    S.GUI.InterTrialInterval = 2;
    S.GUIMeta.VariableITI.Style = 'checkbox';
    S.GUI.MaxITI = 3;

    %% ===== Cue =====
    S.GUITabs.Cue = {'Pattern_cue', 'Odour_cue', 'Sound_cue', 'Light_cue'};
    S.GUIPanels.Odour_cue = {'valves_cue'};
    S.GUIPanels.Sound_cue = {'Amplitude_cue', 'Freq_cue'};
    S.GUIPanels.Light_cue = {'Intensity_cue'};
    S.GUIPanels.Pattern_cue = {'Nimages_cue', 'imgIdx_cue', 'exposure_cue', 'dark_cue', 'repeat_cue'};
    % == Odour ==
    S.GUI.valves_cue = [7];
    S.GUIMeta.valves_cue.Style = 'odour_selector';
    S.GUIMeta.valves_cue.ProbParam = 'probs_cue';
    S.GUIMeta.valves_cue.DutyParam = 'dutyCycles_cue';
    S.GUI.dutyCycles_cue = [1]; 
    S.GUI.probs_cue = [1];
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
    S.GUITabs.Left = {'Pattern_Left', 'Odour_Left', 'Sound_Left', 'Light_Left'};
    S.GUIPanels.Odour_Left = {'valves_Left'};
    S.GUIPanels.Sound_Left = {'Amplitude_Left', 'HighFreq_Left', 'LowFreq_Left'};
    S.GUIPanels.Light_Left = {'Intensity_Left'};
    S.GUIPanels.Pattern_Left = {'Nimages_Left', 'imgIdx_Left', 'exposure_Left', 'dark_Left', 'repeat_Left'};
    % == Odour ==
    S.GUI.valves_Left = [11];
    S.GUIMeta.valves_Left.Style = 'odour_selector';
    S.GUIMeta.valves_Left.ProbParam = 'probs_Left';
    S.GUIMeta.valves_Left.DutyParam = 'dutyCycles_Left';
    S.GUI.dutyCycles_Left = [1]; 
    S.GUI.probs_Left = [1];
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
    S.GUITabs.Right = {'Pattern_Right', 'Odour_Right', 'Sound_Right', 'Light_Right'};
    S.GUIPanels.Odour_Right = {'valves_Right'};
    S.GUIPanels.Sound_Right = {'Amplitude_Right', 'HighFreq_Right', 'LowFreq_Right'};
    S.GUIPanels.Light_Right = {'Intensity_Right'};
    S.GUIPanels.Pattern_Right = {'Nimages_Right', 'imgIdx_Right', 'exposure_Right', 'dark_Right', 'repeat_Right'};
    % == Odour ==
    S.GUI.valves_Right = [16];
    S.GUIMeta.valves_Right.Style = 'odour_selector';
    S.GUIMeta.valves_Right.ProbParam = 'probs_Right';
    S.GUIMeta.valves_Right.DutyParam = 'dutyCycles_Right';
    S.GUI.dutyCycles_Right = [1]; 
    S.GUI.probs_Right = [1];
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