function OdourBottleClicked(src, paramNum)
    % OdourBottleClicked  Callback for matrix-based odour selection
    global BpodSystem
    data = get(src, 'UserData');
    v = data.Valve;
    % Prevent selection of clean air valves
    if ismember(v, [1, 2, 9, 10])
        return;
    end
    tabColor = data.TabColor;
    panelBg = [1 1 1];
    
    % Get the table and its current data
    htable = BpodSystem.GUIHandles.ParameterGUI.Params(paramNum);
    selectorData = get(htable, 'UserData');
    currentData = get(htable, 'Data');
    
    % Get the active row (selected in table)
    activeRow = selectorData.ActiveRow;
    if activeRow > size(currentData, 1)
        activeRow = size(currentData, 1);
        selectorData.ActiveRow = activeRow;
    end
    
    % Parse existing valves in this row
    vRow = str2num(currentData{activeRow, 2});
    dRow = str2num(currentData{activeRow, 3});
    
    % If last valve clicked is the same, remove it (undo)
    if ~isempty(vRow) && vRow(end) == v
        vRow(end) = [];
        if length(dRow) > length(vRow), dRow(end) = []; end
    else
        % Add to sequence
        vRow = [vRow, v];
        % Default duty cycle = 1 for new valve
        if length(dRow) < length(vRow), dRow = [dRow, 1]; end
    end
    
    % Update table data
    currentData{activeRow, 2} = num2str(vRow);
    currentData{activeRow, 3} = num2str(dRow);
    set(htable, 'Data', currentData);
    
    % Refresh all buttons in this rack to show current sequence
    for iBtn = 1:16
        hBtn = selectorData.Buttons(iBtn);
        hData = get(hBtn, 'UserData');
        isSelected = ismember(hData.Valve, vRow);
        
        btnColor = [0.9 0.9 0.9];
        if isSelected, btnColor = tabColor; end
        if hData.IsAir && ~isSelected, btnColor = [0.95 0.95 1.0]; end
        
        pos = get(hBtn, 'Position');
        img = generateBottleImage(pos(3)-10, pos(4)-10, btnColor, panelBg);
        set(hBtn, 'CData', img, 'BackgroundColor', panelBg);
    end
    
    set(htable, 'UserData', selectorData);
end
