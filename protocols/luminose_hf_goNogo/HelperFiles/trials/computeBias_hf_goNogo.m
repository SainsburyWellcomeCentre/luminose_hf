function Bias = computeBias_hf_goNogo(data, N)
% computeBias calculates the response bias over the last N trials
% BpodData: BpodSystem.Data
% N: number of previous trials to consider
%
% Returns:
%   Bias: bias measure (CSminus proportion - CSplus proportion), from -1 to 1

if nargin < 2
    N = 50; % default window
end

if ~isfield(data,'RawEvents') || isempty(data.RawEvents)
    Bias = 0;
    return
end
nTrials = length(data.RawEvents.Trial);
startIdx = max(1, nTrials - N + 1);

% Extract first lick choice from each trial
choices = nan(1, nTrials);
for i = startIdx:nTrials
    events = data.RawEvents.Trial{i}.Events;
    hasPlus  = isfield(events,'BNC1High');
    hasMinus = isfield(events,'BNC2High');
    
    if hasPlus && ~hasMinus
        choices(i) = 1; % left
    elseif hasMinus && ~hasPlus
        choices(i) = 2; % right
    else
        choices(i) = NaN;
    end
end

% Only keep non-NaN trials (filter both arrays using the same mask)
window = choices(startIdx:nTrials);
correctSides = data.TrialTypes(startIdx:nTrials);
validMask = ~isnan(window);
validChoices = window(validMask);
correctSides = correctSides(validMask);

if isempty(validChoices)
    Bias = 0;
    return
end

WrongResps = validChoices ~= correctSides;
nWrong = sum(WrongResps);
WrongRespProportion = nWrong / length(WrongResps);

% Fraction of wrong responses to each side (guard against zero wrong trials)
if nWrong == 0
    WrongMinusProportion = 0;
    WrongPlusProportion  = 0;
else
    WrongMinusProportion = WrongRespProportion * sum(WrongResps & validChoices==2) / nWrong;
    WrongPlusProportion  = WrongRespProportion * sum(WrongResps & validChoices==1) / nWrong;
end

% Bias (positive = right bias, negative = left bias)
Bias = WrongMinusProportion - WrongPlusProportion;

end