function data = updateTrialData_hf_playground(data, trialIdx)
% updateTrialData  Extracts response and side from raw events for bias correction
%
% Side: 1=Left, 2=Right
% Response: 1=Left, 2=Right, NaN=No Response

if ~isfield(data, 'TrialSide')
    data.TrialSide = [];
    data.TrialResponse = [];
    data.TrialOutcome = [];
end

% 1. Determine Trial Side (Correct Side)
% This is already in data.TrialTypes, but we'll store it for convenience
data.TrialSide(trialIdx) = data.TrialTypes(trialIdx);

% 2. Determine Animal Response
events = data.RawEvents.Trial{trialIdx}.Events;
hasLeft  = isfield(events, 'BNC1High');
hasRight = isfield(events, 'BNC2High');

% Note: BNC1High on Trial 1 might be barcode, but the state machine 
% for GetResponse only active after barcode.
% However, to be safe, we check if events happened during response state.
% But for simple bias, we just look at what they licked.

response = NaN;
if hasLeft && ~hasRight
    response = 1;
elseif hasRight && ~hasLeft
    response = 2;
elseif hasLeft && hasRight
    % Use the first one
    tLeft = events.BNC1High(1);
    tRight = events.BNC2High(1);
    if tLeft < tRight
        response = 1;
    else
        response = 2;
    end
end
data.TrialResponse(trialIdx) = response;

% 3. Determine Outcome (Correct, Incorrect, NoResponse)
hasReward = isfield(data.RawEvents.Trial{trialIdx}.States,'Reward') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Reward(1));
hasPunishment = isfield(data.RawEvents.Trial{trialIdx}.States,'Punishment') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Punishment(1));

if hasReward
    data.TrialOutcome(trialIdx) = 1; % Correct
elseif hasPunishment
    % Check if they actually licked the wrong side or didn't lick
    if isnan(response)
        data.TrialOutcome(trialIdx) = 3; % No Response
    else
        data.TrialOutcome(trialIdx) = 0; % Incorrect
    end
else
    % This handles cases where punishment is disabled or habituation
    if isnan(response)
        data.TrialOutcome(trialIdx) = 3;
    elseif response == data.TrialTypes(trialIdx)
        data.TrialOutcome(trialIdx) = 1;
    else
        data.TrialOutcome(trialIdx) = 0;
    end
end

end
