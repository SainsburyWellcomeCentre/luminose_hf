function RBias = computeBias_hf_2AFC(data, N)
% computeBias calculates the response bias over the last N trials
% data: BpodSystem.Data
% N: number of previous trials to consider
%
% Returns:
%   RBias: bias measure (Right proportion - Left proportion), from -1 to 1

if nargin < 2
    N = 50;
end

if ~isfield(data,'RawEvents') || isempty(data.RawEvents)
    RBias = 0;
    return
end

nTrials = length(data.RawEvents.Trial);
startIdx = max(1, nTrials - N + 1);

choices = nan(1, nTrials);
for i = startIdx:nTrials
    events = data.RawEvents.Trial{i}.Events;
    hasLeft  = isfield(events, 'BNC1High');
    hasRight = isfield(events, 'BNC2High');

    if hasLeft && ~hasRight
        choices(i) = 1;
    elseif hasRight && ~hasLeft
        choices(i) = 2;
    elseif hasLeft && hasRight
        % Both occurred — use whichever came first
        tLeft  = events.BNC1High(1);
        tRight = events.BNC2High(1);
        if tLeft < tRight
            choices(i) = 1;
        else
            choices(i) = 2;
        end
    % else: neither occurred, stays NaN
    end
end

% Trim to window and align with TrialTypes
window       = choices(startIdx:nTrials);
correctSides = data.TrialTypes(startIdx:nTrials);
validMask    = ~isnan(window);
validChoices = window(validMask);
correctSides = correctSides(validMask);

if isempty(validChoices)
    RBias = 0;
    return
end

WrongSides           = validChoices ~= correctSides;
nWrong               = sum(WrongSides);
WrongSideProportion  = nWrong / length(WrongSides);

if nWrong == 0
    WrongRightsProportion = 0;
    WrongLeftsProportion  = 0;
else
    WrongRightsProportion = WrongSideProportion * sum(WrongSides & validChoices==2) / nWrong;
    WrongLeftsProportion  = WrongSideProportion * sum(WrongSides & validChoices==1) / nWrong;
end

RBias = WrongRightsProportion - WrongLeftsProportion;
end