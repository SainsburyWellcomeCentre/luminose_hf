function outcome = getTrialOutcome_hf_MTS(data, trialIdx)
% outcome:
% 1 = correct (rewarded)
% 0 = incorrect
% 3 = no response

hasMatchResponse    = isfield(data.RawEvents.Trial{trialIdx}.Events,'BNC1High');
hasNonMatchResponse = isfield(data.RawEvents.Trial{trialIdx}.Events,'BNC2High');

hasReward = isfield(data.RawEvents.Trial{trialIdx}.States,'Reward') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Reward(1));
hasPunishment = isfield(data.RawEvents.Trial{trialIdx}.States,'Punishment') && ...
            ~isnan(data.RawEvents.Trial{trialIdx}.States.Punishment(1));

if ~hasMatchResponse && ~hasNonMatchResponse && hasPunishment
    outcome = 3;
elseif hasReward
    outcome = 1;
elseif hasPunishment
    outcome = 0;
else
    outcome = 3;
end
end
