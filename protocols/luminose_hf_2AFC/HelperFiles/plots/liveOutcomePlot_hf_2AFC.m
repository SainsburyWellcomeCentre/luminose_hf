function liveOutcomePlot_hf_2AFC(ax, action, data, nextTrialType)
persistent h xC yC xE yE xN yN

switch action
    case 'init'
        xC = []; yC = []; xE = []; yE = []; xN = []; yN = [];
        axes(ax); cla; hold on
        h.correct = plot(NaN, NaN, 'go', 'MarkerFaceColor', 'g');
        h.error   = plot(NaN, NaN, 'ro', 'MarkerFaceColor', 'r');
        h.noresp  = plot(NaN, NaN, 'ko', 'MarkerFaceColor', 'none');
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
        drawnow nocallbacks

    case 'update'
        nDone = data.nTrials;

        % Only process the latest trial (not all trials)
        i = nDone;
        side    = getTrialSide_hf_2AFC(data, i);
        outcome = getTrialOutcome_hf_2AFC(data, i);

        if outcome == 1
            xC(end+1) = i; yC(end+1) = side;
        elseif outcome == 0
            xE(end+1) = i; yE(end+1) = side;
        elseif outcome == 3
            xN(end+1) = i; yN(end+1) = side;
        end

        % Use safeSet: replace empty arrays with NaN so the Line object
        % stays at length 1 (rather than jumping from length 1 to length 0),
        % which would leave a cached XData/YData mismatch that fires on the
        % drawnow below.
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
% Replace empty arrays with NaN before setting XData/YData.
% When a Line is initialised with plot(NaN,NaN) (length 1) and we later
% call set(h,'XData',[],'YData',[]) (length 0), MATLAB applies XData first
% leaving an intermediate length-1 vs length-0 mismatch.  That mismatch is
% cached and fires again on the next drawnow.  Using NaN keeps the Line at
% length 1 throughout, so the length never changes for empty categories.
    if isempty(x)
        x = NaN;
        y = NaN;
    end
    set(h, 'XData', x, 'YData', y);
end
