function nextTrialType = getNextTrialType_hf_playground(data, varargin)
% getNextTrialType determines the next trial side based on bias and error repeating
% Supports either:
%   getNextTrialType_hf_playground(data, S)
% or the legacy form:
%   getNextTrialType_hf_playground(data, nTrialsToUse, biasCorrection, correctionGain, leftProb)

if nargin >= 2 && isstruct(varargin{1})
    S = varargin{1};
    leftProb = S.Leftprob; % Base probability
    useBiasCorrection = isfield(S, 'BiasCorrection') && S.BiasCorrection;
    useRepeatOnError = isfield(S, 'RepeatOnError') && S.RepeatOnError;
    nTrialsToUse = 20;
    correctionGain = 0.5;
else
    S = struct;
    nTrialsToUse = varargin{1};
    useBiasCorrection = varargin{2};
    correctionGain = varargin{3};
    leftProb = varargin{4};
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
correctedLeftProb = leftProb;
if useBiasCorrection
    bias = computeBias_hf_playground(data, nTrialsToUse, leftProb);
    
    % Adjust probability: 
    % If bias > 0 (Right bias), increase Left probability
    % If bias < 0 (Left bias), decrease Left probability (increase Right)
    % A simple linear correction:
    correctedLeftProb = leftProb + bias * correctionGain;
    
    % Bound probability
    correctedLeftProb = max(0.1, min(0.9, correctedLeftProb));
end

% 3. Random Selection
if rand < correctedLeftProb
    nextTrialType = 1;
else
    nextTrialType = 2;
end

end
