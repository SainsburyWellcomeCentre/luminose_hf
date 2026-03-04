function nextTrialType = getNextTrialType_hf_goNogo(data, N, biasCorrection, biasThreshold, CSplusProb)
% getNextTrialType calls the biasCorrectedTrial function with default params
% Inputs:
%   BpodData - BpodSystem.Data
% Output:
%   nextTrialType - 1=CSplus, 2=CSminus

% Call the bias function with last 50 trials and threshold 0.2
if biasCorrection
    Bias = computeBias_hf_2AFC(data, N);
    if Bias > biasThreshold
        nextTrialType = 1; % give more left trials
    elseif Bias < -biasThreshold
        nextTrialType = 2; % give more right trials
    else
        if rand < CSplusProb
            nextTrialType = 1;
        else
            nextTrialType = 2;
        end
    end
else
    if rand < CSplusProb
        nextTrialType = 1;
    else
        nextTrialType = 2;
    end
end