function outcome = getTrialOutcome_hf_2AFC(data, trialIdx)
% outcome:
% 1 = correct (rewarded)
% 0 = incorrect
% 3 = no response

RE = data.RawEvents.Trial{trialIdx};

hasLeft  = isfield(RE.Events,'BNC1High');
hasRight = isfield(RE.Events,'BNC2High');

hasReward = isfield(RE.States,'Reward') && ...
            ~isnan(RE.States.Reward(1));

if ~hasLeft && ~hasRight
    outcome = 3;
elseif hasReward
    outcome = 1;
else
    outcome = 0;
end
end