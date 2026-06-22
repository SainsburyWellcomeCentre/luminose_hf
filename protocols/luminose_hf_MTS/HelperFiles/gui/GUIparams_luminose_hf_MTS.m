function GUIparams_luminose_hf_MTS()
    global S

    %% ===== Trials =====
    S.GUITabs.Trials = {'ProtocolSettings', 'Sniff', 'TreatmentType', 'TestPulses', 'TrainingParams'};
    S.GUIPanels.TrainingParams = {'TrainingLevel', 'BiasCorrection', 'RepeatOnError', 'maxTrials', 'MatchProb'};
    S.GUIPanels.TestPulses = {'TestPulses', 'TestPulsesType'};
    S.GUIPanels.TreatmentType = {'Ephys', 'EEG', 'Drug'};
    S.GUIPanels.ProtocolSettings = {'Sleep', 'muBarcodeDur', 'sigmaBarcodeDur'};
    S.GUIPanels.Sniff = {'SniffOnsetThreshold', 'SniffOffsetThreshold', 'SniffRising', 'CalibrateSniff'};

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
    S.GUI.maxTrials = 1000;
    S.GUIMeta.maxTrials.Label = 'Max Trials';
    S.GUI.MatchProb = 0.5;
    S.GUIMeta.MatchProb.Label = 'Match Probability';

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

    % == Sniff ==
    S.GUI.SniffOnsetThreshold = 2.0;  % baseline ~2.5V; fires when sniff drops below this
    S.GUIMeta.SniffOnsetThreshold.Label = 'Sniff Onset Thresh (V)';
    S.GUI.SniffOffsetThreshold = 2.0;  % fires when signal returns above this
    S.GUIMeta.SniffOffsetThreshold.Label = 'Sniff Offset Thresh (V)';
    S.GUI.SniffRising = false;
    S.GUIMeta.SniffRising.Style = 'checkbox';
    S.GUIMeta.SniffRising.Label = 'Rising Edge';
    S.GUI.CalibrateSniff = 0;
    S.GUIMeta.CalibrateSniff.Style = 'pushbutton';
    S.GUIMeta.CalibrateSniff.String = 'Calibrate Sniff (12s)';
    S.GUIMeta.CalibrateSniff.Callback = 'RunSniffCalibration';
    S.GUIMeta.CalibrateSniff.CallbackArg = '';

    %% ===== Task =====
    S.GUITabs.Task = {'ITI', 'Response', 'Stimulus', 'DelayParams', 'CueParams'};
    S.GUIPanels.CueParams = {'CueType', 'CueTime'};
    S.GUIPanels.Stimulus = {'TemplateType', 'SampleType', 'StimTime'};
    S.GUIPanels.DelayParams = {'Delay'};
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
    S.GUI.TemplateType = 3;
    S.GUIMeta.TemplateType.Style = 'popupmenu';
    S.GUIMeta.TemplateType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.TemplateType.Label = 'Template Type';
    S.GUI.SampleType = 3;
    S.GUIMeta.SampleType.Style = 'popupmenu';
    S.GUIMeta.SampleType.String = {'Light', 'Sound', 'Odour', 'Pattern'};
    S.GUIMeta.SampleType.Label = 'Sample Type';
    S.GUI.StimTime = 1; % olfactometer: preSequence_delay + pulseTime + postSequence_delay
    S.GUIMeta.StimTime.Label = 'Stim Duration (s)';

    % == Delay ==
    S.GUI.Delay = 2;
    S.GUIMeta.Delay.Label = 'Template-Sample Delay (s)';

    % == Response ==
    S.GUI.ResponseType = 1;
    S.GUIMeta.ResponseType.Style = 'popupmenu';
    S.GUIMeta.ResponseType.String = {'Lick', 'Rotary Encoder'};
    S.GUIMeta.ResponseType.Label = 'Response Type';
    S.GUI.ResponseTime = 2;
    S.GUIMeta.ResponseTime.Label = 'Response Window (s)';
    S.GUI.RewardAmount = 2;
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
    S.GUI.InterTrialInterval = 5;
    S.GUIMeta.InterTrialInterval.Label = 'Mean ITI (s)';
    S.GUI.MaxITI = 6;
    S.GUIMeta.MaxITI.Label = 'Max ITI (s)';

    %% ===== Cue =====
    S.GUITabs.Cue = {'Light_cue', 'Sound_cue', 'Odour_cue', 'Pattern_cue'};
    S.GUIPanels.Light_cue = {'Intensity_cue'};
    S.GUIPanels.Sound_cue = {'Freq_cue'};
    S.GUIPanels.Odour_cue = {'valves_cue'};
    S.GUIPanels.Pattern_cue = {'patternSel_cue'};
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
    S.GUI.patternSel_cue = 0;
    S.GUIMeta.patternSel_cue.Style = 'pattern_selector';
    S.GUIMeta.patternSel_cue.ProbParam = 'patternProbs_cue';
    S.GUIMeta.patternSel_cue.NFramesParam = 'patternNFrames_cue';
    S.GUIMeta.patternSel_cue.ExposureParam = 'patternExposure_cue';
    S.GUIMeta.patternSel_cue.TypeName = 'cue';
    S.GUIMeta.patternSel_cue.Label = '';
    S.GUI.patternProbs_cue = [1];
    S.GUIMeta.patternProbs_cue.Hidden = true;
    S.GUI.patternNFrames_cue = [1];
    S.GUIMeta.patternNFrames_cue.Hidden = true;
    S.GUI.patternExposure_cue = [1e6];
    S.GUIMeta.patternExposure_cue.Hidden = true;

    %% ===== Template =====
    % The Template's own probability column (in the Odour_Template /
    % Pattern_Template row tables) decides which template row is delivered
    % each trial; this is the existing odour_selector / pattern_selector
    % mechanism, unmodified.
    S.GUITabs.Template = {'Light_Template', 'Sound_Template', 'Odour_Template', 'Pattern_Template'};
    S.GUIPanels.Light_Template = {'Intensity_Template'};
    S.GUIPanels.Sound_Template = {'HighFreq_Template', 'LowFreq_Template'};
    S.GUIPanels.Odour_Template = {'valves_Template'};
    S.GUIPanels.Pattern_Template = {'patternSel_Template'};
    % == Light ==
    S.GUI.Intensity_Template = 100;
    S.GUIMeta.Intensity_Template.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_Template = 8;
    S.GUIMeta.HighFreq_Template.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_Template = 4;
    S.GUIMeta.LowFreq_Template.Label = 'Low Freq (Hz)';
    % == Odour ==
    S.GUI.valves_Template = [12; 16; 7];
    S.GUIMeta.valves_Template.Style = 'odour_selector';
    S.GUIMeta.valves_Template.ProbParam = 'probs_Template';
    S.GUIMeta.valves_Template.DutyParam = 'dutyCycles_Template';
    S.GUIMeta.valves_Template.Label = 'Valves';
    S.GUI.dutyCycles_Template = [1; 1; 1];
    S.GUI.probs_Template = [1/3; 1/3; 1/3];
    % == Pattern ==
    S.GUI.patternSel_Template = 0;
    S.GUIMeta.patternSel_Template.Style = 'pattern_selector';
    S.GUIMeta.patternSel_Template.ProbParam = 'patternProbs_Template';
    S.GUIMeta.patternSel_Template.NFramesParam = 'patternNFrames_Template';
    S.GUIMeta.patternSel_Template.ExposureParam = 'patternExposure_Template';
    S.GUIMeta.patternSel_Template.TypeName = 'Template';
    S.GUIMeta.patternSel_Template.Label = '';
    S.GUI.patternProbs_Template = [1];
    S.GUIMeta.patternProbs_Template.Hidden = true;
    S.GUI.patternNFrames_Template = [1];
    S.GUIMeta.patternNFrames_Template.Hidden = true;
    S.GUI.patternExposure_Template = [1e6];
    S.GUIMeta.patternExposure_Template.Hidden = true;

    %% ===== Sample =====
    % On a Match trial, the sample is delivered by literally replaying
    % whichever template row was selected — the Sample tab's settings only
    % matter for Non-match trials.
    S.GUITabs.Sample = {'Light_Sample', 'Sound_Sample', 'Odour_Sample', 'Pattern_Sample'};
    S.GUIPanels.Light_Sample = {'Intensity_Sample'};
    S.GUIPanels.Sound_Sample = {'HighFreq_Sample', 'LowFreq_Sample'};
    S.GUIPanels.Odour_Sample = {'valves_Sample'};
    S.GUIPanels.Pattern_Sample = {'patternSel_Sample'};
    % == Light ==
    S.GUI.Intensity_Sample = 100;
    S.GUIMeta.Intensity_Sample.Label = 'Intensity (0-255)';
    % == Sound ==
    S.GUI.HighFreq_Sample = 16;
    S.GUIMeta.HighFreq_Sample.Label = 'High Freq (Hz)';
    S.GUI.LowFreq_Sample = 12;
    S.GUIMeta.LowFreq_Sample.Label = 'Low Freq (Hz)';
    % == Odour ==
    % Each row is a candidate Non-match odour. Instead of its own
    % probability, each row carries one checkbox per current Template row
    % ('templateMask_Sample', rows=sample options x columns=template rows):
    % checked means that sample row is a valid Non-match follow-up for that
    % template. On a Non-match trial, the delivered row is drawn uniformly
    % among the rows checked for whichever template row was selected.
    S.GUI.valves_Sample = [15; 3; 6];
    S.GUIMeta.valves_Sample.Style = 'odour_selector_conditional';
    S.GUIMeta.valves_Sample.DutyParam = 'dutyCycles_Sample';
    S.GUIMeta.valves_Sample.MaskParam = 'templateMask_Sample';
    S.GUIMeta.valves_Sample.Label = 'Valves';
    S.GUI.dutyCycles_Sample = [1; 1; 1];
    S.GUI.templateMask_Sample = false(3, 8); % rows=sample options, cols=template rows (up to MAX_TEMPLATE_COLS)
    S.GUI.templateMask_Sample(1, 1) = true; S.GUI.templateMask_Sample(2, 2) = true; S.GUI.templateMask_Sample(3, 3) = true; 
    S.GUIMeta.templateMask_Sample.Hidden = true;
    % == Pattern ==
    S.GUI.patternSel_Sample = 0;
    S.GUIMeta.patternSel_Sample.Style = 'pattern_selector';
    S.GUIMeta.patternSel_Sample.ProbParam = 'patternProbs_Sample';
    S.GUIMeta.patternSel_Sample.NFramesParam = 'patternNFrames_Sample';
    S.GUIMeta.patternSel_Sample.ExposureParam = 'patternExposure_Sample';
    S.GUIMeta.patternSel_Sample.TypeName = 'Sample';
    S.GUIMeta.patternSel_Sample.Label = '';
    S.GUI.patternProbs_Sample = [1];
    S.GUIMeta.patternProbs_Sample.Hidden = true;
    S.GUI.patternNFrames_Sample = [1];
    S.GUIMeta.patternNFrames_Sample.Hidden = true;
    S.GUI.patternExposure_Sample = [1e6];
    S.GUIMeta.patternExposure_Sample.Hidden = true;

    %% OptoStim
    S.GUITabs.OptoStim = {'MaskLED', 'SinglePulse', 'PairedPulse', 'Pattern_opto'};
    S.GUIPanels.SinglePulse = {'SPfrequency', 'SPamplitude'};
    S.GUIPanels.PairedPulse = {'PPfrequency', 'PPamplitude'};
    S.GUIPanels.MaskLED = {'Intensity_mask', 'Duration_mask'};
    S.GUIPanels.Pattern_opto = {'patternSel_opto'};
    S.GUI.SPfrequency = 1;
    S.GUIMeta.SPfrequency.Label = 'Freq (Hz)';
    S.GUI.SPamplitude = 1;
    S.GUIMeta.SPamplitude.Label = 'Amp (V)';
    S.GUI.PPfrequency = 1;
    S.GUIMeta.PPfrequency.Label = 'Freq (Hz)';
    S.GUI.PPamplitude = 1;
    S.GUIMeta.PPamplitude.Label = 'Amp (V)';
    S.GUI.Intensity_mask = 100;
    S.GUIMeta.Intensity_mask.Label = 'Intensity (0-255)';
    S.GUI.Duration_mask = S.GUI.StimTime;
    S.GUIMeta.Duration_mask.Label = 'Duration (s)';
    % == Pattern ==
    S.GUI.patternSel_opto = 0;
    S.GUIMeta.patternSel_opto.Style = 'pattern_selector';
    S.GUIMeta.patternSel_opto.ProbParam = 'patternProbs_opto';
    S.GUIMeta.patternSel_opto.NFramesParam = 'patternNFrames_opto';
    S.GUIMeta.patternSel_opto.ExposureParam = 'patternExposure_opto';
    S.GUIMeta.patternSel_opto.TypeName = 'opto';
    S.GUIMeta.patternSel_opto.Label = '';
    S.GUI.patternProbs_opto = [1];
    S.GUIMeta.patternProbs_opto.Hidden = true;
    S.GUI.patternNFrames_opto = [1];
    S.GUIMeta.patternNFrames_opto.Hidden = true;
    S.GUI.patternExposure_opto = [1e6];
    S.GUIMeta.patternExposure_opto.Hidden = true;

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
