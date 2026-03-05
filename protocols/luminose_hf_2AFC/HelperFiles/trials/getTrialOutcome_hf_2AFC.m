function outcome = getTrialOutcome_hf_2AFC(data, trialIdx)
% outcome:
% 1 = correct (rewarded)
% 0 = incorrect
% 3 = no response

hasLeft  = isfield(data.RawEvents.Trial{trialIdx}.Events,'BNC1High');
hasRight = isfield(data.RawEvents.Trial{trialIdx}.Events,'BNC2High');

hasReward = isfield(data.RawEvents.Trial{trialIdx}.States,'Reward') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Reward(1));
hasPunishment = isfield(data.RawEvents.Trial{trialIdx}.States,'Punishment') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Punishment(1));

if ~hasLeft && ~hasRight && hasPunishment
    outcome = 3;
elseif hasReward
    outcome = 1;
elseif hasPunishment
    outcome = 0;
end
end