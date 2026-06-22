function bias = computeBias_hf_MTS(data, N, matchProb)
% computeBias calculates response bias based on last N trials, relative to
% the expected response split under matchProb (not a flat 50/50), so an
% intentionally skewed matchProb is not itself read as bias.
% bias > 0: non-match bias (more non-match responses than matchProb would predict)
% bias < 0: match bias (more match responses than matchProb would predict)

if nargin < 2, N = 20; end
if nargin < 3, matchProb = 0.5; end

if ~isfield(data, 'TrialResponse')
    bias = 0;
    return;
end

responses = data.TrialResponse;
nTrials = length(responses);
startIdx = max(1, nTrials - N + 1);
window = responses(startIdx:end);

% Ignore no-responses for bias calculation
validResponses = window(~isnan(window));

if isempty(validResponses)
    bias = 0;
    return;
end

pMatch = sum(validResponses == 1) / length(validResponses);
pNonMatch = sum(validResponses == 2) / length(validResponses);

% Deviation from the expected split given matchProb, from -1 to 1
bias = (pNonMatch - pMatch) - (1 - 2 * matchProb);

end
