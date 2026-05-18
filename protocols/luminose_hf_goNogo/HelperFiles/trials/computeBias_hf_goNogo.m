function bias = computeBias_hf_goNogo(data, N)
% computeBias calculates lick bias based on last N trials
% bias > 0: no-lick bias (animal doesn't lick enough) -> increase CS+ probability
% bias < 0: lick bias (animal licks too much)         -> decrease CS+ probability

if nargin < 2, N = 20; end

if ~isfield(data, 'TrialResponse')
    bias = 0;
    return;
end

responses = data.TrialResponse;
nTrials = length(responses);
startIdx = max(1, nTrials - N + 1);
window = responses(startIdx:end);

validResponses = window(~isnan(window));

if isempty(validResponses)
    bias = 0;
    return;
end

pLick = sum(validResponses == 1) / length(validResponses);
bias = 0.5 - pLick;

end
