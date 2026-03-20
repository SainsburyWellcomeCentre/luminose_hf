function nextTrialType = getNextTrialType_hf_2AFC(data, N, biasCorrection, biasThreshold, leftProb)

correctedLeftProb = leftProb;

if biasCorrection 
    try
        RBias = computeBias_hf_2AFC(data, N);
        excessBias = RBias - sign(RBias) * biasThreshold;
        excessBias = max(-1, min(1, excessBias));
        correctedLeftProb = leftProb + excessBias * (1 - leftProb) * (RBias > 0) ...
                                     - excessBias * leftProb       * (RBias < 0);
        correctedLeftProb = max(0, min(1, correctedLeftProb));
    catch ME
        warning('computeBias failed on trial %d: %s', nTrials, ME.message);
    end
end

if rand < correctedLeftProb
    nextTrialType = 1;
else
    nextTrialType = 2;
end