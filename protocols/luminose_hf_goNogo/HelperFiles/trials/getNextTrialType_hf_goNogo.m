function nextTrialType = getNextTrialType_hf_goNogo(data, varargin)
% getNextTrialType determines the next trial type based on bias and error repeating
% Supports either:
%   getNextTrialType_hf_goNogo(data, S)
% or the legacy form:
%   getNextTrialType_hf_goNogo(data, nTrialsToUse, biasCorrection, correctionGain, CSplusProb)

if nargin >= 2 && isstruct(varargin{1})
    S = varargin{1};
    CSplusProb = S.GUI.CSplus_prob; % Base probability
    useBiasCorrection = isfield(S.GUI, 'BiasCorrection') && S.GUI.BiasCorrection;
    useRepeatOnError = isfield(S.GUI, 'RepeatOnError') && S.GUI.RepeatOnError;
    nTrialsToUse = 20;
    correctionGain = 0.5;
else
    nTrialsToUse = varargin{1};
    useBiasCorrection = varargin{2};
    correctionGain = varargin{3};
    CSplusProb = varargin{4};
    useRepeatOnError = false;
end

nextTrialType = 0;

% 1. Repeat on Error (if enabled)
if useRepeatOnError
    if isfield(data, 'TrialOutcome') && ~isempty(data.TrialOutcome)
        lastOutcome = data.TrialOutcome(end);
        if lastOutcome == 0 % Incorrect response
            nextTrialType = data.TrialTypes(end);
            return;
        end
    end
end

% 2. Bias Correction (if enabled)
correctedPlusProb = CSplusProb;
if useBiasCorrection
    bias = computeBias_hf_goNogo(data, nTrialsToUse, CSplusProb);
    
    % Adjust probability: 
    % If bias > 0 (Right/CS- bias), increase Left/CS+ probability
    % If bias < 0 (Left/CS+ bias), decrease Left/CS+ probability
    correctedPlusProb = CSplusProb + bias * correctionGain;
    
    % Bound probability
    correctedPlusProb = max(0.1, min(0.9, correctedPlusProb));
end

% 3. Random Selection
if rand < correctedPlusProb
    nextTrialType = 1;
else
    nextTrialType = 2;
end

end
