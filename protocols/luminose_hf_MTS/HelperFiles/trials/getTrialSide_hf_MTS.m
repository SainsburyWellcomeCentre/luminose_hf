function side = getTrialSide_hf_MTS(data, trialIdx)
% 1 = Match, 2 = Non-match (for plotting)

side = data.TrialTypes(trialIdx) == 1;

end
