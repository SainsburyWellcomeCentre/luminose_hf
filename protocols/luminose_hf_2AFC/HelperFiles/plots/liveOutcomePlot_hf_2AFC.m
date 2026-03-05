function liveOutcomePlot_hf_2AFC(ax, action, data, nextTrialType)
persistent h
switch action
    case 'init'
        axes(ax); cla; hold on
        % Completed trials
        h.correct = plot(NaN, NaN, 'go', 'MarkerFaceColor', 'g');
        h.error   = plot(NaN, NaN, 'ro', 'MarkerFaceColor', 'r');
        h.noresp  = plot(NaN, NaN, 'ko', 'MarkerFaceColor', 'none');  % ← ADD THIS
        % Current trial as blue dot
        h.current = plot(NaN, NaN, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
        set(ax, 'YLim', [-0.5 1.5], ...
            'YTick', [0 1], ...
            'YTickLabel', {'Right', 'Left'}, ...
            'XLim', [0 10], ...
            'TickDir', 'out')
        xlabel('Trial #')
        if nargin >= 4 && ~isempty(nextTrialType)
            set(h.current, 'XData', 1, 'YData', nextTrialType == 1)
        end
        drawnow

    case 'update'
        nDone = data.nTrials;
        xC = []; yC = [];
        xE = []; yE = [];
        xN = []; yN = [];  % ← ADD THIS
        for i = 1:nDone
            side    = getTrialSide_hf_2AFC(data, i);
            outcome = getTrialOutcome_hf_2AFC(data, i);
            if outcome == 1
                xC(end+1) = i; yC(end+1) = side;
            elseif outcome == 0
                xE(end+1) = i; yE(end+1) = side;
            elseif outcome == 3              % ← ADD THIS
                xN(end+1) = i; yN(end+1) = side;
            end
        end
        set(h.correct, 'XData', xC, 'YData', yC)
        set(h.error,   'XData', xE, 'YData', yE)
        set(h.noresp,  'XData', xN, 'YData', yN)  % ← ADD THIS
        % Move blue dot to the next trial
        nextTrial = nDone + 1;
        if nargin >= 4 && ~isempty(nextTrialType)
            nextSide = nextTrialType == 1;
        else
            nextSide = NaN;
        end
        xlim(ax, [0 max(10, nextTrial + 5)])
        set(h.current, 'XData', nextTrial, 'YData', nextSide)
        drawnow
end
end