function nextTrialType = getNextTrialType_hf_playground(data, S)
% getNextTrialType determines the next trial side based on bias and error repeating
% S: current S.GUI struct

leftProb = S.LeftProb; % Base probability
nextTrialType = 0;

% 1. Repeat on Error (if enabled)
if isfield(S, 'RepeatOnError') && S.RepeatOnError
    if isfield(data, 'Custom') && isfield(data.Custom, 'TrialOutcome') && ~isempty(data.Custom.TrialOutcome)
        lastOutcome = data.Custom.TrialOutcome(end);
        if lastOutcome == 0 % Incorrect response
            nextTrialType = data.Custom.TrialSide(end);
            return;
        end
    end
end

% 2. Bias Correction (if enabled)
correctedLeftProb = leftProb;
if isfield(S, 'BiasCorrection') && S.BiasCorrection
    % Calculate bias over last 20 trials
    bias = computeBias_hf_playground(data, 20);
    
    % Adjust probability: 
    % If bias > 0 (Right bias), increase Left probability
    % If bias < 0 (Left bias), decrease Left probability (increase Right)
    % A simple linear correction:
    correctedLeftProb = leftProb + bias * 0.5;
    
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
