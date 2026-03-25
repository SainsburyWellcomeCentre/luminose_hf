function liveAccuracyPlot_hf_goNogo(ax, op, data)
    % liveAccuracyPlot_hf_goNogo - Moving average accuracy plot for go/no-go task
    %
    % Syntax:
    %   liveAccuracyPlot_hf_goNogo(ax, 'init', [])     - Initialize the plot
    %   liveAccuracyPlot_hf_goNogo(ax, 'update', data) - Update with new trial data
    %
    % Inputs:
    %   ax   - axes handle for plotting
    %   op   - operation: 'init' or 'update'
    %   data - BpodSystem.Data structure containing trial outcomes

    global BpodSystem

    WINDOW = 20; % moving average window (trials)

    op = lower(op);

    switch op
        case 'init'
            cla(ax);
            hold(ax, 'on');

            % Moving average lines (one per trial type + overall)
            BpodSystem.GUIHandles.AccuracyPlot.LineCSplus = plot(ax, NaN, NaN, ...
                '-o', 'Color', [0.18 0.55 0.80], 'LineWidth', 2, ...
                'MarkerSize', 4, 'MarkerFaceColor', [0.18 0.55 0.80], ...
                'DisplayName', sprintf('CS+ (Go) — win=%d', WINDOW));
            BpodSystem.GUIHandles.AccuracyPlot.LineCSminus = plot(ax, NaN, NaN, ...
                '-s', 'Color', [0.85 0.33 0.10], 'LineWidth', 2, ...
                'MarkerSize', 4, 'MarkerFaceColor', [0.85 0.33 0.10], ...
                'DisplayName', sprintf('CS- (No-Go) — win=%d', WINDOW));
            BpodSystem.GUIHandles.AccuracyPlot.LineOverall = plot(ax, NaN, NaN, ...
                '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5, ...
                'DisplayName', 'Overall');

            % Chance line
            yline(ax, 50, ':', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2, ...
                'HandleVisibility', 'off');

            % Formatting
            ax.XLabel.String = 'Trial';
            ax.YLabel.String = 'Accuracy (%)';
            ax.YLim = [0 100];
            ax.FontSize = 11;
            ax.FontName = 'Segoe UI';
            ax.Box = 'on';
            ax.LineWidth = 1.2;
            grid(ax, 'on');
            ax.GridAlpha = 0.25;
            legend(ax, 'Location', 'southwest', 'FontSize', 9);

            BpodSystem.GUIHandles.AccuracyPlot.Title = title(ax, ...
                'Moving Accuracy', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);

            hold(ax, 'off');

        case 'update'
            if isempty(data) || ~isfield(data, 'TrialTypes')
                return;
            end

            nTrials = length(data.TrialTypes);
            if nTrials == 0
                return;
            end

            % Build per-trial correct vector for each trial type
            correctAll    = NaN(1, nTrials);
            correctCSplus = NaN(1, nTrials);
            correctCSminus = NaN(1, nTrials);

            for i = 1:nTrials
                trialType = data.TrialTypes(i);
                states    = data.RawEvents.Trial{i}.States;

                hasReward = isfield(states, 'Reward') && ~isnan(states.Reward(1));
                hasPunishment = isfield(states, 'Punishment') && ~isnan(states.Punishment(1));
                hasITI    = isfield(states, 'InterTrialInterval') && ~isnan(states.InterTrialInterval(1));

                switch trialType
                    case 1  % CS+ — correct = Reward
                        isCorrect = hasReward;
                        correctCSplus(i) = double(isCorrect);
                    case 2  % CS- — correct = reached ITI without punishment
                        isCorrect = hasITI && ~hasPunishment;
                        correctCSminus(i) = double(isCorrect);
                end
                correctAll(i) = double(isCorrect);
            end

            trialIdx = 1:nTrials;

            % Compute moving averages
            maOverall  = movingAccuracy(correctAll,    WINDOW);
            maCSplus   = movingAccuracy(correctCSplus,  WINDOW);
            maCSminus  = movingAccuracy(correctCSminus, WINDOW);

            % Update lines
            set(BpodSystem.GUIHandles.AccuracyPlot.LineOverall,  'XData', trialIdx, 'YData', maOverall  * 100);
            set(BpodSystem.GUIHandles.AccuracyPlot.LineCSplus,   'XData', trialIdx, 'YData', maCSplus   * 100);
            set(BpodSystem.GUIHandles.AccuracyPlot.LineCSminus,  'XData', trialIdx, 'YData', maCSminus  * 100);

            % Update x-axis limits
            ax.XLim = [max(1, nTrials - 200), max(WINDOW + 1, nTrials + 1)];

            % Update title
            totalCorrect = sum(correctAll, 'omitnan');
            overallAcc   = totalCorrect / nTrials * 100;

            titleStr = sprintf('Mov. Acc. (win=%d)—Total: %.1f%% (%d/%d)', ...
                WINDOW, overallAcc, totalCorrect, nTrials);
            set(BpodSystem.GUIHandles.AccuracyPlot.Title, 'String', titleStr);

            if overallAcc >= 75
                titleColor = [0.13 0.55 0.13];
            elseif overallAcc >= 50
                titleColor = [0.80 0.50 0.10];
            else
                titleColor = [0.75 0.15 0.15];
            end
            set(BpodSystem.GUIHandles.AccuracyPlot.Title, 'Color', titleColor);

        otherwise
            error('liveAccuracyPlot_hf_goNogo: invalid operation ''%s''. Use ''init'' or ''update''.', op);
    end
end

%% Helper — moving average ignoring NaN (trials of the other type)
function ma = movingAccuracy(correct, window)
    n  = length(correct);
    ma = NaN(1, n);
    for i = 1:n
        idx    = max(1, i - window + 1):i;
        vals   = correct(idx);
        valid  = vals(~isnan(vals));
        if ~isempty(valid)
            ma(i) = mean(valid);
        end
    end
end