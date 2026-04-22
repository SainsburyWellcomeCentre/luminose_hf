function DrawOptoStim(Params)
    % DrawOptoStim  Visualizes the optogenetic stimulation pattern in the GUI
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes;
    cla(ax); hold(ax,'on');

    widthScale = 0.5;
    ypos = 0.3; 
    height = 0.4;
    totalTrial = Params.CueTime + Params.StimTime + Params.ResponseTime + ...
                 Params.ErrorDelay + Params.InterTrialInterval;
    scaledTotal = totalTrial * widthScale;

    rectangle(ax, 'Position', [0 ypos scaledTotal height], ...
        'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0 0 0]);
    text(scaledTotal/2, height*1.5, 'Single trial', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'Parent',ax);

    if Params.TestPulsesType == 1
        freq = Params.SPfrequency;
        duration = Params.SPduration;
        amplitude = Params.SPamplitude;
        symbol = '*';
    else
        freq = Params.PPfrequency;
        duration = Params.PPduration;
        amplitude = Params.PPamplitude;
        symbol = '**';
    end

    if freq > 0
        dt = 1 / freq;
        tEvents = 0:dt:totalTrial;
        color = [0 0 max(min(amplitude,1),0)];

        for tEv = tEvents
            tScaled = tEv * widthScale;
            text(ax, tScaled, ypos + height + 0.05, symbol, ...
                 'Color', color, ...
                 'FontSize', 10 + 8 * (duration / 1000), ...
                 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'bottom');
        end
    end

    ax.XLim = [0 scaledTotal];
    ax.YLim = [0 1];
    axis(ax, 'off');
end
