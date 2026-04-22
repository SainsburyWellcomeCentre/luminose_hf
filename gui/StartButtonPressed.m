function StartButtonPressed(lockedParams)
    % StartButtonPressed  Handles disabling GUI elements and updating button status
    global BpodSystem

    % Signal that start was pressed
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', true);

    % Disable each locked parameter's GUI control
    paramNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
    for i = 1:length(paramNames)
        if any(strcmp(paramNames{i}, lockedParams))
            if iscell(BpodSystem.GUIHandles.ParameterGUI.Params)
                h = BpodSystem.GUIHandles.ParameterGUI.Params{i};
            else
                h = BpodSystem.GUIHandles.ParameterGUI.Params(i);
            end
            try
                set(h, 'Enable', 'off');
            catch
            end
        end
    end

    % Relabel the START button — keep Enable 'on' so ForegroundColor is visible
    set(BpodSystem.GUIHandles.ParameterGUI.StartButton, ...
        'String', '● RUNNING', ...
        'BackgroundColor', [0.15 0.55 0.25], ...
        'ForegroundColor', [1 1 0.4], ...
        'FontSize', 16, ...
        'Enable', 'on', ...
        'Callback', @(~,~) []);
end
