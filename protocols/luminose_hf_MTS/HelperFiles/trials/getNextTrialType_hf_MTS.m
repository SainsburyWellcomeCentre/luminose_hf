function nextTrialType = getNextTrialType_hf_MTS(data, S)
% getNextTrialType determines the next trial type (1=Match, 2=Non-match)
% based on bias and error repeating. Which physical template/sample row
% gets delivered is decided separately in PrepareStateMachine (template
% row: weighted draw from the Template odour/pattern table; sample row on
% Non-match: drawn from the rows checked for that template in the Sample
% odour table).

nTrialsToUse = 20;
correctionGain = 0.5;
matchProb = S.GUI.MatchProb;
useBiasCorrection = isfield(S.GUI, 'BiasCorrection') && S.GUI.BiasCorrection;
useRepeatOnError = isfield(S.GUI, 'RepeatOnError') && S.GUI.RepeatOnError;

% Habituation: strictly alternate Match (1) and Non-match (2)
if isfield(S.GUI, 'TrainingLevel') && S.GUI.TrainingLevel == 1
    if isfield(data, 'TrialTypes') && ~isempty(data.TrialTypes)
        lastType = data.TrialTypes(end);
        if lastType == 1, nextTrialType = 2;
        else,             nextTrialType = 1; end
    else
        nextTrialType = 1; % first trial: start Match
    end
    return;
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
correctedMatchProb = matchProb;
if useBiasCorrection
    bias = computeBias_hf_MTS(data, nTrialsToUse, matchProb);

    % Adjust probability:
    % If bias > 0 (Non-match bias), increase Match probability
    % If bias < 0 (Match bias), decrease Match probability (increase Non-match)
    correctedMatchProb = matchProb + bias * correctionGain;

    % Bound probability
    correctedMatchProb = max(0.1, min(0.9, correctedMatchProb));
end

% 3. Random Selection
if rand < correctedMatchProb
    nextTrialType = 1;
else
    nextTrialType = 2;
end

end
