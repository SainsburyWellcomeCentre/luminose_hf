function liveBarPlot_hf_2AFC(ax, op, data)
    % barPlot - Creates and updates a bar plot showing accuracy for Left and Right trials
    %
    % Syntax:
    %   barPlot(ax, 'init', trialTypes, [])  - Initialize the plot
    %   barPlot(ax, 'update', trialTypes, data) - Update with new trial data
    %
    % Inputs:
    %   ax - axes handle for plotting
    %   op - operation: 'init' or 'update'
    %   trialTypes - vector of trial types (1 = Left, 2 = Right)
    %   data - BpodSystem.Data structure containing trial outcomes
    
    global BpodSystem
    
    op = lower(op);
    
    switch op
        case 'init'
            % Initialize the bar plot
            cla(ax);
            hold(ax, 'on');
            
            % Create initial bars with zero height
            BpodSystem.GUIHandles.AccuracyPlot.Bars = bar(ax, [1 2], [0 0], 0.6);
            BpodSystem.GUIHandles.AccuracyPlot.Bars.FaceColor = 'flat';
            BpodSystem.GUIHandles.AccuracyPlot.Bars.CData(1,:) = [0.2 0.5 0.8];  % Left color (blue)
            BpodSystem.GUIHandles.AccuracyPlot.Bars.CData(2,:) = [0.8 0.4 0.2];  % Right color (orange)
            
            % Formatting
            ax.XTick = [1 2];
            ax.XTickLabel = {'Left', 'Right'};
            ax.YLim = [0 100];
            ax.YLabel.String = 'Accuracy (%)';
            ax.FontSize = 11;
            ax.FontName = 'Segoe UI';
            ax.Box = 'on';
            ax.LineWidth = 1.5;
            grid(ax, 'on');
            ax.GridAlpha = 0.3;
            
            % Create text labels for percentages
            BpodSystem.GUIHandles.AccuracyPlot.Text1 = text(ax, 1, 5, '', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'Color', [0.2 0.2 0.2]);
            BpodSystem.GUIHandles.AccuracyPlot.Text2 = text(ax, 2, 5, '', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'Color', [0.2 0.2 0.2]);
            
            % Create title
            BpodSystem.GUIHandles.AccuracyPlot.Title = title(ax, 'Overall Accuracy: 0% (0/0 trials)', ...
                'FontSize', 12, ...
                'FontWeight', 'bold', ...
                'Color', [0.2 0.2 0.2]);
            
            hold(ax, 'off');
            
        case 'update'
            if isempty(data) || ~isfield(data, 'TrialTypes')
                return;
            end
            
            % Get completed trials
            nTrials = length(data.TrialTypes);
            if nTrials == 0
                return;
            end
            
            % Initialize counters
            nLeft = 0;
            nRight = 0;
            correctLeft = 0;
            correctRight = 0;
            
            % Count trials and correct responses
            for i = 1:nTrials
                trialType = data.TrialTypes(i);
                
                % Check if trial had a reward (correct) or punishment (incorrect)
                states = data.RawEvents.Trial{i}.States;
                hasReward = isfield(states, 'Reward') && ~isnan(states.Reward(1));
                hasPunishment = isfield(states, 'Punishment') && ~isnan(states.Punishment(1));
                
                if trialType == 1  % left trial (should GO - lick)
                    nLeft = nLeft + 1;
                    if hasReward
                        correctLeft = correctLeft + 1;
                    end
                elseif trialType == 2  % right trial (should NO-GO - withhold)
                    nRight = nRight + 1;
                    % Correct if reached ITI without punishment
                    hasITI = isfield(states, 'InterTrialInterval') && ~isnan(states.InterTrialInterval(1));
                    if hasITI && ~hasPunishment
                        correctRight = correctRight + 1;
                    end
                end
            end
            
            % Calculate accuracies
            if nLeft > 0
                accuracyLeft = (correctLeft / nLeft) * 100;
            else
                accuracyLeft = 0;
            end
            
            if nRight > 0
                accuracyRight = (correctRight / nRight) * 100;
            else
                accuracyRight = 0;
            end
            
            % Overall accuracy
            totalTrials = nLeft + nRight;
            totalCorrect = correctLeft + correctRight;
            if totalTrials > 0
                overallAccuracy = (totalCorrect / totalTrials) * 100;
            else
                overallAccuracy = 0;
            end
            
            % Update bar heights
            set(BpodSystem.GUIHandles.AccuracyPlot.Bars, 'YData', [accuracyLeft, accuracyRight]);
            
            % Update text labels
            if accuracyLeft > 0
                set(BpodSystem.GUIHandles.AccuracyPlot.Text1, 'Position', [1, accuracyLeft + 3, 0]);
                set(BpodSystem.GUIHandles.AccuracyPlot.Text1, 'String', sprintf('%.1f%%', accuracyLeft));
            else
                set(BpodSystem.GUIHandles.AccuracyPlot.Text1, 'String', '');
            end
            
            if accuracyRight > 0
                set(BpodSystem.GUIHandles.AccuracyPlot.Text2, 'Position', [2, accuracyRight + 3, 0]);
                set(BpodSystem.GUIHandles.AccuracyPlot.Text2, 'String', sprintf('%.1f%%', accuracyRight));
            else
                set(BpodSystem.GUIHandles.AccuracyPlot.Text2, 'String', '');
            end
            
            % Update title with overall accuracy
            titleStr = sprintf('Overall Accuracy: %.1f%% (%d/%d trials)', ...
                overallAccuracy, totalCorrect, totalTrials);
            set(BpodSystem.GUIHandles.AccuracyPlot.Title, 'String', titleStr);
            
            % Update title color based on performance
            if overallAccuracy >= 75
                titleColor = [0.2 0.6 0.2];  % Green for good performance
            elseif overallAccuracy >= 50
                titleColor = [0.8 0.6 0.2];  % Orange for medium performance
            else
                titleColor = [0.8 0.2 0.2];  % Red for low performance
            end
            set(BpodSystem.GUIHandles.AccuracyPlot.Title, 'Color', titleColor);
            
        otherwise
            error('Invalid operation. Use ''init'' or ''update''');
    end
end