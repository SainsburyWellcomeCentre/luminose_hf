function side = getTrialSide_hf_goNogo(data, trialIdx)
% 1 = CSplus, 2 = CSminus (for plotting)

side = data.TrialTypes(trialIdx) == 1;

end