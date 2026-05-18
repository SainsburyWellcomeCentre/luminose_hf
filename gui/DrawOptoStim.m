function DrawOptoStim(Params)
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes;
    cla(ax); hold(ax,'on');

    barColor   = [0.15 0.40 0.85];
    barEdge    = [0.55 0.75 1.00];
    textColor  = [1.00 1.00 1.00];
    pulseColor = [0.85 0.95 1.00];

    widthScale = 0.5;
    ypos   = 0.15;
    height = 0.30;
    pulseTop = 0.92;

    timingFields = {'CueTime','StimTime','ResponseTime','ErrorDelay','InterTrialInterval'};
    if all(isfield(Params, timingFields))
        totalTrial = Params.CueTime + Params.StimTime + Params.ResponseTime + ...
                     Params.ErrorDelay + Params.InterTrialInterval;
    elseif isfield(Params, 'ITImax')
        totalTrial = Params.ITImax;
    else
        totalTrial = 10;
    end
    scaledTotal = totalTrial * widthScale;

    rectangle(ax, 'Position', [0 ypos scaledTotal height], ...
        'FaceColor', barColor, 'EdgeColor', barEdge, 'LineWidth', 2);
    text(scaledTotal/2, ypos - 0.07, 'Single trial', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'Color', textColor, 'FontSize', 9, 'Parent', ax);

    if Params.TestPulsesType == 1
        freq = Params.SPfrequency;
    else
        freq = Params.PPfrequency;
    end

    if freq > 0
        dt      = 1 / freq;
        tEvents = 0:dt:totalTrial;
        for tEv = tEvents
            tScaled = tEv * widthScale;
            line(ax, [tScaled tScaled], [ypos + height  pulseTop], ...
                'Color', pulseColor, 'LineWidth', 3);
            plot(ax, tScaled, pulseTop, 'o', ...
                'MarkerFaceColor', pulseColor, 'MarkerEdgeColor', pulseColor, 'MarkerSize', 5);
        end
    end

    ax.XLim = [0 scaledTotal];
    ax.YLim = [0 1];
    axis(ax, 'off');
end
