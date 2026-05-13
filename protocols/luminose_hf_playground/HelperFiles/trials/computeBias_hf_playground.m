function bias = computeBias_hf_playground(data, N)
% computeBias calculates response bias based on last N trials
% bias > 0: right bias (more right responses)
% bias < 0: left bias (more left responses)

if nargin < 2, N = 20; end

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

% Bias from -1 (total left) to 1 (total right)
bias = pRight - pLeft;

end
