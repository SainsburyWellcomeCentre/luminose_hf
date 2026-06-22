function bias = computeBias_hf_playground(data, N, leftProb)
% computeBias calculates response bias based on last N trials, relative to
% the expected response split under leftProb (not a flat 50/50), so an
% intentionally skewed leftProb is not itself read as bias.
% bias > 0: right bias (more right responses than leftProb would predict)
% bias < 0: left bias (more left responses than leftProb would predict)

if nargin < 2, N = 20; end
if nargin < 3, leftProb = 0.5; end

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

pLeft = sum(validResponses == 1) / length(validResponses);
pRight = sum(validResponses == 2) / length(validResponses);

% Deviation from the expected split given leftProb, from -1 to 1
bias = (pRight - pLeft) - (1 - 2 * leftProb);

end
