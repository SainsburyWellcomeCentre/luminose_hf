function liveResponseTimePlot_hf_MTS(ax, op, data)
% liveResponseTimePlot - Live response time plot
%
% Response time definition:
%   RT = GetResponse(2) - GetResponse(1)
%
% Uses:
%   data.RawEvents.Trial{i}.States.GetResponse

    global BpodSystem

    op = lower(op);

    switch op

        case 'init'
            cla(ax);
            hold(ax, 'on');

            % Storage
            BpodSystem.GUIHandles.RTPlot.ResponseTimes = [];

            % Scatter plot for individual trials
            BpodSystem.GUIHandles.RTPlot.Line = plot(ax, ...
                [NaN NaN], [NaN NaN], 'LineWidth', 2);

            % Running median line
            BpodSystem.GUIHandles.RTPlot.MedianLine = plot(ax, ...
                [NaN NaN], [NaN NaN], 'k', 'LineWidth', 2);

            xlabel(ax, 'Trial #');
            ylabel(ax, 'Response Time (s)');
            title(ax, 'Response Time');
            grid(ax, 'on');
            ax.Box = 'on';
            ax.FontSize = 11;

            hold(ax, 'off');


        case 'update'

            if isempty(data) || ~isfield(data, 'RawEvents')
                return;
            end

            nTrials = length(data.RawEvents.Trial);
            if nTrials == 0
                return;
            end

            responseTimes = nan(1, nTrials);

            for i = 1:nTrials

                trial = data.RawEvents.Trial{1, i};

                if isfield(trial.States, 'GetResponse')
                    t = trial.States.GetResponse;

                    % Valid response if state was exited
                    if numel(t) >= 2 && ~isnan(t(1)) && ~isnan(t(2))
                        responseTimes(i) = t(2) - t(1);
                    end
                end
            end

            % Store
            BpodSystem.GUIHandles.RTPlot.ResponseTimes = responseTimes;

            trials = 1:nTrials;

            % Running median (ignore NaNs)
            medRT = arrayfun(@(k) median(responseTimes(1:k), 'omitnan'), trials);

            % Update plots
            set(BpodSystem.GUIHandles.RTPlot.Line, ...
                'XData', trials, ...
                'YData', responseTimes);

            set(BpodSystem.GUIHandles.RTPlot.MedianLine, ...
                'XData', trials, ...
                'YData', medRT);

            % Update title
            if any(~isnan(responseTimes))
                title(ax, sprintf('Response Time (median = %.3f s)', ...
                    median(responseTimes, 'omitnan')));
            end

        otherwise
            error('Invalid operation. Use ''init'' or ''update''');
    end
end
