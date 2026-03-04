function side = getTrialSide_hf_2AFC(data, trialIdx)
% 1 = Left, 2 = Right (for plotting)

side = data.TrialTypes(trialIdx) == 1;

end