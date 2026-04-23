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
    
    % Push the updated odour-table state into the cached GUI params immediately.
    nRows = size(currentData, 1);
    valvesMatrix = [];
    probsVector = zeros(nRows, 1);
    dutyMatrix = [];
    for iR = 1:nRows
        probsVector(iR) = currentData{iR, 1};
        valvesRow = str2num(currentData{iR, 2}); %#ok<ST2NM>
        dutyRow = str2num(currentData{iR, 3}); %#ok<ST2NM>
        if isempty(valvesRow), valvesRow = 0; end
        if isempty(dutyRow), dutyRow = 1; end
        valvesMatrix = padAndAppend(valvesMatrix, valvesRow);
        dutyMatrix = padAndAppend(dutyMatrix, dutyRow);
    end

    if isfield(BpodSystem.GUIData, 'ParameterGUI') && ...
       isfield(BpodSystem.GUIData.ParameterGUI, 'LatestGUIParams')
        BpodSystem.GUIData.ParameterGUI.LatestGUIParams.(selectorData.ParamName) = valvesMatrix;
        BpodSystem.GUIData.ParameterGUI.LatestGUIParams.(selectorData.ProbParam) = probsVector;
        BpodSystem.GUIData.ParameterGUI.LatestGUIParams.(selectorData.DutyParam) = dutyMatrix;
    end

    % Only sync in real-time if START hasn't been pressed
    startPressed = isappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed') && ...
        getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed');

    if ~startPressed
        suffix = BpodSystem.GUIData.ParameterGUI.ProtocolSuffix;
        syncFunc = str2func(sprintf('LuminoseParameterGUI_hf_%s', suffix));
        syncFunc('sync', struct('GUI', BpodSystem.GUIData.ParameterGUI.LatestGUIParams, 'GUIMeta', BpodSystem.GUIData.ParameterGUI.LatestMeta));
    end
end

function m = padAndAppend(m, row)
    if isempty(m), m = row; return; end
    nColsM = size(m, 2);
    nColsR = length(row);
    if nColsM < nColsR
        m = [m, zeros(size(m, 1), nColsR - nColsM)];
    elseif nColsR < nColsM
        row = [row, zeros(1, nColsM - nColsR)];
    end
    m = [m; row];
end
