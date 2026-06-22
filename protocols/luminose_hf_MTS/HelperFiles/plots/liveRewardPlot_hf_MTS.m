function liveRewardPlot_hf_MTS(ax, op, data)
% liveRewardPlot - Cumulative reward volume (µL) across trials
%
% Uses:
%   Reward detection from RawEvents
%   RewardAmount from TrialSettings{i}.GUI.RewardAmount

    global BpodSystem

    op = lower(op);

    switch op

        case 'init'
            cla(ax);
            hold(ax, 'on');

            BpodSystem.GUIHandles.RewardPlot.CumReward = 0;
            BpodSystem.GUIHandles.RewardPlot.RewardHistory = [];

            BpodSystem.GUIHandles.RewardPlot.Line = plot(ax, 0, 0, ...
                'LineWidth', 2);

            xlabel(ax, 'Trial #');
            ylabel(ax, 'Cumulative Reward (µL)');
            title(ax, 'Total Reward Delivered: 0 µL');
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

            cumReward = 0;
            rewardHistory = zeros(1, nTrials);

            for i = 1:nTrials

                % Check reward delivery
                if isfield(data.RawEvents.Trial{i}.States, 'Reward')
                    hasReward = ~isnan(data.RawEvents.Trial{i}.States.Reward(1));
                else
                    hasReward = false;
                end

                if hasReward
                    rewardAmount = data.TrialSettings(i).GUI.RewardAmount;

                    if isempty(rewardAmount) || isnan(rewardAmount)
                        rewardAmount = 0;
                    end
                else
                    rewardAmount = 0;
                end

                cumReward = cumReward + rewardAmount;
                rewardHistory(i) = cumReward;
            end

            % Store values
            BpodSystem.GUIHandles.RewardPlot.CumReward = cumReward;
            BpodSystem.GUIHandles.RewardPlot.RewardHistory = rewardHistory;

            % Update plot
            set(BpodSystem.GUIHandles.RewardPlot.Line, ...
                'XData', 1:nTrials, ...
                'YData', rewardHistory);

            % Update title
            titleStr = sprintf('Total Reward Delivered: %.2f µL', cumReward);
            title(ax, titleStr);

        otherwise
            error('Invalid operation. Use ''init'' or ''update''');
    end
end
