function outcome = getTrialOutcome_hf_goNogo(data, trialIdx)
% outcome:
% 1 = correct (rewarded)
% 0 = incorrect

trialType = getTrialSide_hf_goNogo(data, trialIdx);

hasReward = isfield(data.RawEvents.Trial{trialIdx}.States,'Reward') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Reward(1));
hasPunishment = isfield(data.RawEvents.Trial{trialIdx}.States,'Punishment') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Punishment(1));

if trialType == 1 
    if hasReward
        outcome = 1;
    else
        outcome = 0;
    end
else
    if hasPunishment
        outcome = 0;
    else
        outcome = 1;
    end
end