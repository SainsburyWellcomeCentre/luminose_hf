function liveOutcomePlot_hf_goNogo(ax, action, data, nextTrialType)
persistent h xC yC xE yE xN yN

switch action
    case 'init'
        xC = []; yC = []; xE = []; yE = []; xN = []; yN = [];
        axes(ax); cla; hold on
        h.correct = plot(NaN, NaN, 'go', 'MarkerFaceColor', 'g');
        h.error   = plot(NaN, NaN, 'ro', 'MarkerFaceColor', 'r');
        h.noresp  = plot(NaN, NaN, 'o', 'Color', [0.7 0.7 0.7], 'MarkerFaceColor', 'none');
        h.current = plot(NaN, NaN, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
        set(ax, 'YLim', [-0.5 1.5], ...
                'YTick', [0 1], ...
                'YTickLabel', {'No go', 'Go'}, ...
                'XLim', [0 10], ...
                'TickDir', 'out')
        xlabel('Trial #')
        if nargin >= 4 && ~isempty(nextTrialType)
            set(h.current, 'XData', 1, 'YData', nextTrialType == 1)
        end
        drawnow nocallbacks

    case 'update'
        nDone = data.nTrials;

        % Only process the latest trial
        i = nDone;
        side    = getTrialSide_hf_goNogo(data, i);
        outcome = getTrialOutcome_hf_goNogo(data, i);

        if outcome == 1
            xC(end+1) = i; yC(end+1) = side;
        elseif outcome == 0
            xE(end+1) = i; yE(end+1) = side;
        elseif outcome == 3
            xN(end+1) = i; yN(end+1) = side;
        end

        safeSet(h.correct, xC, yC);
        safeSet(h.error,   xE, yE);
        safeSet(h.noresp,  xN, yN);

        % Move blue dot to the next trial
        nextTrial = nDone + 1;
        nextSide = NaN;
        if nargin >= 4 && ~isempty(nextTrialType)
            nextSide = nextTrialType == 1;
        end
        set(ax,'XLim',[max(nDone-100, 0) max(nDone+1, 100)])
        set(h.current, 'XData', nextTrial, 'YData', nextSide)
        drawnow nocallbacks
end
end

function safeSet(h, x, y)
    if isempty(x), x = NaN; y = NaN; end
    set(h, 'XData', x, 'YData', y);
end

