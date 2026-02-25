function nextTrialType = getNextTrialType_hf_2AFC(data, N, biasCorrection, biasThreshold, leftProb)
% getNextTrialType calls the biasCorrectedTrial function with default params
% Inputs:
%   BpodData - BpodSystem.Data
% Output:
%   nextTrialType - 1=Left, 2=Right

% Call the bias function with last 50 trials and threshold 0.2
if biasCorrection
    RBias = computeBias_hf_2AFC(data, N);
    if RBias > biasThreshold
        nextTrialType = 1; % give more left trials
    elseif RBias < -biasThreshold
        nextTrialType = 2; % give more right trials
    else
        if rand < leftProb
            nextTrialType = 1;
        else
            nextTrialType = 2;
        end
    end
else
    if rand < leftProb
        nextTrialType = 1;
    else
        nextTrialType = 2;
    end
end