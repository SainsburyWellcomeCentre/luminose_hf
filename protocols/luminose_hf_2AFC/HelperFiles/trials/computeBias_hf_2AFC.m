function RBias = computeBias_hf_2AFC(data, N)
% computeBias calculates the response bias over the last N trials
% BpodData: BpodSystem.Data
% N: number of previous trials to consider
%
% Returns:
%   RBias: bias measure (Right proportion - Left proportion), from -1 to 1

if nargin < 2
    N = 50; % default window
end

if ~isfield(data,'RawEvents') || isempty(data.RawEvents)
    RBias = 0;
    return
end
nTrials = length(data.RawEvents.Trial);
startIdx = max(1, nTrials - N + 1);

% Extract first lick choice from each trial
choices = nan(1, nTrials);
for i = startIdx:nTrials
    events = data.RawEvents.Trial{i}.Events;
    hasLeft  = isfield(events,'BNC1High');
    hasRight = isfield(events,'BNC2High');
    
    if hasLeft && ~hasRight
        choices(i) = 1; % left
    elseif hasRight && ~hasLeft
        choices(i) = 2; % right
    else
        choices(i) = NaN;
    end
end

% Only keep non-NaN trials
validChoices = choices(startIdx:nTrials);
validChoices = validChoices(~isnan(validChoices));

% Compute wrong side proportion
% Assuming BpodData.TrialTypes stores correct side: 1 = left, 2 = right
correctSides = data.TrialTypes(startIdx:nTrials);
correctSides = correctSides(~isnan(validChoices));

WrongSides = validChoices ~= correctSides;
WrongSideProportion = sum(WrongSides)/length(WrongSides);

% Fraction of wrong responses to each side
WrongRightsProportion = WrongSideProportion * sum(WrongSides & validChoices==2)/sum(WrongSides);
WrongLeftsProportion  = WrongSideProportion * sum(WrongSides & validChoices==1)/sum(WrongSides);

% Bias (positive = right bias, negative = left bias)
RBias = WrongRightsProportion - WrongLeftsProportion;

end