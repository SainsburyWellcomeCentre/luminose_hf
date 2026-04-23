function varargout = LuminoseParameterGUI_hf_goNogo(varargin)
% BpodParameterGUI('init', ParamStruct) - initializes a GUI with edit boxes for every field in subfield ParamStruct.GUI
% BpodParameterGUI('sync', ParamStruct) - updates the GUI with fields of
%       ParamStruct.GUI, if they have not been changed by the user. 
%       Returns a param struct. Fields in the GUI sub-struct are read from the UI.

    global BpodSystem
    Op = varargin{1};
    Params = varargin{2};
    Op = lower(Op);
    
    % Define color scheme
    COLORS.background = [0.95 0.95 0.97];
    COLORS.panelBg = [1 1 1];
    COLORS.tabBg = [0.98 0.98 1];
    COLORS.accentCS_plus = [0.2 0.5 0.8];
    COLORS.accentCS_minus = [0.8 0.4 0.2];
    COLORS.accentCue = [0.4 0.7 0.4];
    COLORS.accentTrial = [0.6 0.4 0.7];
    COLORS.textDark = [0.2 0.2 0.2];

    % Parameters to lock after START is pressed
    LOCKED_PARAMS = { ...
        'TrainingLevel', ...
        'maxTrials', ...
        'muBarcodeDur', ...
        'sigmaBarcodeDur', ...
        'SoundSamplingRate', ...
        'ResponseType', ...
        'VariableITI', 'InterTrialInterval', 'MaxITI', ...
        'Ephys', 'EphysType', 'EphysCoords', ...
        'EEG', 'EEGchannels', 'EMGchannels', ...
        'Drug', 'DrugType', 'DrugDose' ...
    };
    
    switch Op
        case 'init'
            ParamNames = fieldnames(Params.GUI);
            nParams = length(ParamNames);
            BpodSystem.GUIData.ParameterGUI.ParamNames = cell(1,nParams);
            BpodSystem.GUIData.ParameterGUI.nParams = nParams;
            BpodSystem.GUIHandles.ParameterGUI.Labels = zeros(1,nParams);
            BpodSystem.GUIHandles.ParameterGUI.Params = zeros(1,nParams);
            BpodSystem.GUIData.ParameterGUI.LastParamValues = cell(1,nParams);
            BpodSystem.GUIData.ParameterGUI.PanelParams = struct;
            BpodSystem.GUIData.ParameterGUI.ParamIndexByName = struct;
            BpodSystem.GUIData.ParameterGUI.PanelStyles = struct;
            BpodSystem.GUIData.ParameterGUI.LockedParams = LOCKED_PARAMS;
            BpodSystem.GUIData.ParameterGUI.ProtocolSuffix = 'goNogo';
    
            if isfield(Params, 'GUIMeta')
                Meta = Params.GUIMeta;
            else
                Meta = struct;
            end
            BpodSystem.GUIData.ParameterGUI.LatestGUIParams = Params.GUI;
            BpodSystem.GUIData.ParameterGUI.LatestMeta = Meta;
            
            % Handle hidden parameters
            hiddenParams = {};
            if ~isempty(fieldnames(Meta))
                metaNames = fieldnames(Meta);
                for iMeta = 1:numel(metaNames)
                    if isstruct(Meta.(metaNames{iMeta})) && isfield(Meta.(metaNames{iMeta}), 'Hidden') && Meta.(metaNames{iMeta}).Hidden
                        hiddenParams{end+1} = metaNames{iMeta}; %#ok<AGROW>
                    end
                end
            end

            if isfield(Params, 'GUIPanels')
                Panels = Params.GUIPanels;
                PanelNames = fieldnames(Panels);
                nPanels = length(PanelNames);
                paramNames = fieldnames(Params.GUI);
                nParameters = length(paramNames);
                paramsInPanels = {}; 
                for i = 1:nPanels
                    paramsInPanels = [paramsInPanels Panels.(PanelNames{i})];
                end
                paramsInDefaultPanel = {};
                for i = 1:nParameters
                    if ismember(paramNames{i}, hiddenParams)
                        continue
                    end
                    if ~strcmp(paramNames{i}, paramsInPanels)
                        paramsInDefaultPanel = [paramsInDefaultPanel paramNames{i}];
                    end
                end
                if ~isempty(paramsInDefaultPanel)
                    Panels.Parameters = cell(1,length(paramsInDefaultPanel));
                    for i = 1:length(paramsInDefaultPanel)
                        Panels.Parameters{i} = paramsInDefaultPanel{i};
                    end
                    PanelNames{nPanels+1} = 'Parameters';
                end
                nPanels = length(PanelNames);
            else
                Panels = struct;
                Panels.Parameters = ParamNames;
                PanelNames = {'Parameters'};
                nPanels = 1;
            end
            
            if isfield(Params, 'GUITabs')
                Tabs = Params.GUITabs;            
            else
                Tabs = struct;
                Tabs.Parameters = PanelNames;
            end
            TabNames = fieldnames(Tabs);
            nTabs = length(TabNames);
            
            Params = Params.GUI;
            PanelNames = PanelNames(end:-1:1);
            GUIHeight = 900;
            MaxVPos = 0;
            MaxHPos = 0;
            BpodSystem.ProtocolFigures.ParameterGUI = figure('Position', [50 50 450 GUIHeight],'name','Luminose','numbertitle','off', 'MenuBar', 'none', 'Resize', 'on');
            BpodSystem.GUIHandles.ParameterGUI.Tabs.TabGroup = uitabgroup(BpodSystem.ProtocolFigures.ParameterGUI);
            ParamNum = 1;
            for t = 1:nTabs
                VPos = 15;
                HPos = 15;
                ThisTabPanelNames = Tabs.(TabNames{t});
                nPanels = length(ThisTabPanelNames);
                if contains(lower(TabNames{t}),'csplus')
                    tabColor = COLORS.accentCS_plus;
                elseif contains(lower(TabNames{t}),'csminus')
                    tabColor = COLORS.accentCS_minus;
                elseif contains(lower(TabNames{t}),'cue')
                    tabColor = COLORS.accentCue;
                elseif contains(lower(TabNames{t}),'trial')
                    tabColor = COLORS.accentTrial;
                else
                    tabColor = [0.5 0.5 0.6];
                end
    
                BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t}) = uitab('title',TabNames{t},'BackgroundColor',COLORS.tabBg);
                htab = BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t});
    
                for p = 1:nPanels
                    ThisPanelParamNames = Panels.(ThisTabPanelNames{p});
                    ThisPanelParamNames = ThisPanelParamNames(~ismember(ThisPanelParamNames, hiddenParams));
                    if isempty(ThisPanelParamNames)
                        continue
                    end
                    BpodSystem.GUIData.ParameterGUI.PanelParams.(ThisTabPanelNames{p}) = ThisPanelParamNames;
                    ThisPanelParamNames = ThisPanelParamNames(end:-1:1);
                    nParams = length(ThisPanelParamNames);
                    paramHeight = 35;      
                    panelPadding = 28;      
                    ThisPanelHeight = nParams * paramHeight + panelPadding;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}) = uipanel(htab,...
                        'title',sprintf('  %s  ',ThisTabPanelNames{p}),'FontSize',12,'FontWeight','Bold',...
                        'ForegroundColor',tabColor,'BackgroundColor',COLORS.panelBg,'Units','Pixels',...
                        'Position',[HPos VPos 455 ThisPanelHeight],'BorderType','line','HighlightColor',tabColor,...
                        'BorderWidth',2,'ShadowColor',[0.8 0.8 0.8]);
                    BpodSystem.GUIData.ParameterGUI.PanelStyles.(ThisTabPanelNames{p}) = struct( ...
                        'ForegroundColor', tabColor, ...
                        'BackgroundColor', COLORS.panelBg, ...
                        'HighlightColor', tabColor, ...
                        'ShadowColor', [0.8 0.8 0.8]);
    
                    InPanelPos = 15;
                    for i = 1:nParams
                        ThisParamName = ThisPanelParamNames{i};
                        ThisParam = Params.(ThisParamName);
                        BpodSystem.GUIData.ParameterGUI.ParamNames{ParamNum} = ThisParamName;
                        BpodSystem.GUIData.ParameterGUI.ParamIndexByName.(ThisParamName) = ParamNum;
                        if ischar(ThisParam)
                            BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = NaN;
                        else
                            BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = ThisParam;
                        end
                        
                        % Determine style and string
                        ThisParamStyle = 'edit';
                        ThisParamString = '';
                        if isfield(Meta, ThisParamName) && isstruct(Meta.(ThisParamName))
                            if isfield(Meta.(ThisParamName), 'Style')
                                ThisParamStyle = Meta.(ThisParamName).Style;
                            end
                            if isfield(Meta.(ThisParamName), 'String')
                                ThisParamString = Meta.(ThisParamName).String;
                            end
                        end

                        % Label logic
                        if isfield(Meta, ThisParamName) && isfield(Meta.(ThisParamName), 'Label')
                            labelStr = Meta.(ThisParamName).Label;
                        else
                            underscorePos = strfind(ThisParamName,'_');
                            if isempty(underscorePos)
                                labelStr = ThisParamName;
                            else
                                labelStr = ThisParamName(1:underscorePos(1)-1);
                            end
                            labelStr = strrep(labelStr,'_',' ');
                        end
    
                        BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum) = uicontrol(htab,...
                            'Style','text','String',labelStr,'Position',[HPos+15 VPos+InPanelPos 215 28],...
                            'FontWeight','normal','FontSize',11,'BackgroundColor',COLORS.panelBg,...
                            'ForegroundColor',COLORS.textDark,'FontName','Segoe UI','HorizontalAlignment','Left');
    
                        callbackFunc = @(~,~) HandleRealTimeSync('goNogo');

                        switch lower(ThisParamStyle)
                            case 'edit'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 1;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'edit', 'String', mat2str(ThisParam), 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', callbackFunc);
                            case 'edittext'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 8;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'edit', 'String', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', callbackFunc);
                            case 'text'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 2;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'text', 'String', num2str(ThisParam), 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'checkbox'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 3;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'checkbox', 'Value', ThisParam, 'String', '   (check to activate)', 'Position', [HPos+220 VPos+InPanelPos+4 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', callbackFunc);
                            case 'popupmenu'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 4;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'popupmenu', 'String', ThisParamString, 'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', callbackFunc);
                            case 'togglebutton'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 5;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'togglebutton', 'String', ThisParamString, 'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', callbackFunc);
                            case 'pushbutton'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 6;
                                if isfield(Meta, ThisParamName) && isfield(Meta.(ThisParamName), 'Callback')
                                    cbFn  = Meta.(ThisParamName).Callback;
                                    cbArg = '';
                                    if isfield(Meta.(ThisParamName), 'CallbackArg')
                                        cbArg = Meta.(ThisParamName).CallbackArg;
                                    end
                                    thisCallback = @(~,~) feval(cbFn, cbArg);
                                else
                                    thisCallback = callbackFunc;
                                end
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'pushbutton', 'String', ThisParamString,...
                                    'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12,...
                                    'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center', 'Callback', thisCallback);
                            case 'table'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 7;
                                columnNames = fieldnames(Params.(ThisParamName));
                                if isfield(Meta.(ThisParamName),'ColumnLabel')
                                    columnLabel = Meta.(ThisParamName).ColumnLabel;
                                else
                                    columnLabel = columnNames;
                                end
                                tableData = [];
                                for iTableCol = 1:numel(columnNames)
                                    tableData = [tableData, Params.(ThisParamName).(columnNames{iTableCol})];
                                end
                                htable = uitable(htab,'data',tableData,'columnname',columnLabel,...
                                    'ColumnEditable',true(1,numel(columnLabel)), 'FontSize', 12, 'CellEditCallback', callbackFunc);
                                htable.Position([3 4]) = htable.Extent([3 4]);
                                htable.Position([1 2]) = [HPos+220 VPos+InPanelPos+2];
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = htable;
                                ThisPanelHeight = ThisPanelHeight + (htable.Position(4)-25);
                                BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}).Position(4) = ThisPanelHeight;
                                BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = htable.Data;
                            case 'odour_selector'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 9; 
                                matrixValves = ThisParam; 
                                probParam = Meta.(ThisParamName).ProbParam;
                                dutyParam = Meta.(ThisParamName).DutyParam;
                                vectorProbs = Params.(probParam);
                                matrixDuty = Params.(dutyParam);
                                
                                selectorHeight = 260;
                                selectorPanel = uipanel(htab, 'Units', 'pixels', ...
                                    'Position', [HPos+10 VPos+InPanelPos 435 selectorHeight], ...
                                    'BackgroundColor', COLORS.panelBg, 'BorderType', 'none');
                                
                                mapping = getOdourMapping();
                                bottleButtons = zeros(1, 16);
                                if ~isempty(matrixValves)
                                    initialVRow = matrixValves(1, :);
                                else
                                    initialVRow = [];
                                end
                                
                                for iBottle = 1:16
                                    row = ceil(iBottle/8);
                                    col = mod(iBottle-1, 8) + 1;
                                    btnPos = [10 + (col-1)*53, selectorHeight - 55 - (row-1)*55, 45, 50];
                                    chemical = mapping(iBottle).Name;
                                    notes = mapping(iBottle).Notes;
                                    tooltip = sprintf('Valve %d: %s\nChems: %s\nNotes: %s', iBottle, chemical, mapping(iBottle).Chemicals, notes);
                                    isAir = ismember(iBottle, [1, 2, 9, 10, 14]);
                                    
                                    isSelected = ismember(iBottle, initialVRow);
                                    btnColor = [0.9 0.9 0.9];
                                    if isSelected, btnColor = tabColor; end
                                    if isAir && ~isSelected, btnColor = [0.95 0.95 1.0]; end
                                    
                                    img = generateBottleImage(btnPos(3)-10, btnPos(4)-10, btnColor, COLORS.panelBg);
                                    bottleButtons(iBottle) = uicontrol(selectorPanel, 'Style', 'pushbutton', ...
                                        'String', '', 'Position', btnPos, ... 
                                        'CData', img, 'BackgroundColor', COLORS.panelBg, 'TooltipString', tooltip, ...
                                        'UserData', struct('Valve', iBottle, 'TabColor', tabColor, 'IsAir', isAir), ...
                                        'Callback', @(src, ~) OdourBottleClicked(src, ParamNum));
                                end
                                
                                nOptions = size(matrixValves, 1);
                                tableData = cell(nOptions, 3);
                                for iOpt = 1:nOptions
                                    vRow = matrixValves(iOpt, :);
                                    vRow = vRow(vRow > 0); 
                                    dRow = matrixDuty(iOpt, :);
                                    dRow = dRow(1:length(vRow));
                                    tableData{iOpt, 1} = vectorProbs(iOpt);
                                    tableData{iOpt, 2} = num2str(vRow);
                                    tableData{iOpt, 3} = num2str(dRow);
                                end
                                
                                otable = uitable(selectorPanel, 'Data', tableData, ...
                                    'ColumnName', {'Prob', 'Valves', 'DutyCycles'}, ...
                                    'ColumnWidth', {50, 160, 160}, 'ColumnEditable', [true, true, true], ...
                                    'ColumnFormat', {'numeric', 'char', 'char'}, ...
                                    'Position', [5 10 385 125], 'FontSize', 10, 'CellEditCallback', callbackFunc);
                                
                                set(otable, 'CellSelectionCallback', @(src, ev) OdourTableSelectionChanged(src, ev, bottleButtons));
                                
                                uicontrol(selectorPanel, 'Style', 'pushbutton', 'String', '+', ...
                                    'Position', [395 90 32 32], 'FontSize', 14, 'FontWeight', 'bold', ...
                                    'Callback', @(~, ~) OdourAddRow(otable, 'goNogo'));
                                uicontrol(selectorPanel, 'Style', 'pushbutton', 'String', '-', ...
                                    'Position', [395 50 32 32], 'FontSize', 14, 'FontWeight', 'bold', ...
                                    'Callback', @(~, ~) OdourRemoveRow(otable, 'goNogo'));

                                selectorData = struct('Buttons', bottleButtons, 'Table', otable, ...
                                    'ParamName', ThisParamName, 'ProbParam', probParam, 'DutyParam', dutyParam, ...
                                    'Mapping', mapping, 'ActiveRow', 1);
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = otable; 
                                set(otable, 'UserData', selectorData);
                                
                                ThisPanelHeight = ThisPanelHeight + selectorHeight - 25;
                                BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}).Position(4) = ThisPanelHeight;
                                InPanelPos = InPanelPos + selectorHeight - 35;
                                BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = tableData;
                            otherwise
                                error('Invalid parameter style specified.');
                        end
                        InPanelPos = InPanelPos + paramHeight;
                        ParamNum = ParamNum + 1;
                    end
                    Wrap = 0;
                    if p < nPanels
                        NextPanelParams = Panels.(ThisTabPanelNames{p+1});
                        NextPanelSize = (length(NextPanelParams)*45) + 5;
                        if VPos + ThisPanelHeight + 45 + NextPanelSize > GUIHeight
                            Wrap = 1;
                        end
                    end
                    VPos = VPos + ThisPanelHeight + 15;
                    if Wrap
                        HPos = HPos + 450;
                        if VPos > MaxVPos, MaxVPos = VPos; end
                        VPos = 15;
                    else
                        if VPos > MaxVPos, MaxVPos = VPos; end
                    end
                    if HPos > MaxHPos, MaxHPos = HPos; end
                end        

                if contains(lower(TabNames{t}),'trial')
                    BpodSystem.GUIHandles.ParameterGUI.StartButton = uicontrol(htab, ...
                        'Style', 'pushbutton', 'String', 'START', ...
                        'Position', [15 VPos 455 50], 'FontSize', 16, 'FontWeight', 'Bold', ...
                        'BackgroundColor', [0.2 0.7 0.3], 'ForegroundColor', 'white', ...
                        'FontName', 'Segoe UI', 'Callback', @(~,~) HandleGoNogoStartButton(LOCKED_PARAMS));
                    VPos = VPos + 60;
                end
                if contains(lower(TabNames{t}),'trial')
                    panelName = 'logo'; ThisPanelHeight = 125;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title','','FontSize',12,'FontWeight','Bold','ForegroundColor',COLORS.accentTrial,...
                        'BackgroundColor',COLORS.panelBg,'Units','Pixels','Position',[HPos VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',COLORS.accentTrial,'BorderWidth',2);
                    BpodSystem.GUIHandles.ParameterGUI.ImageAxes = axes('Parent',BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName),...
                        'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
                    DisplayPNGImage();
                    VPos = VPos + ThisPanelHeight + 15;
                end
                if contains(lower(TabNames{t}),'task')
                    panelName = 'TrialStructure'; ThisPanelHeight = 90;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title',sprintf('  %s  ',panelName),'FontSize',12,'FontWeight','Bold','ForegroundColor',COLORS.accentTrial,...
                        'BackgroundColor',COLORS.panelBg,'Units','Pixels','Position',[HPos VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',COLORS.accentTrial,'BorderWidth',2);
                    BpodSystem.GUIHandles.ParameterGUI.TrialStructureAxes = axes('Parent',BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName),...
                        'Units','normalized','Position',[0.08 0.15 0.9 0.7],'Box','on','Color',COLORS.panelBg);
                    DrawTrialStructure(Params, Meta);
                    VPos = VPos + ThisPanelHeight + 15;
                end
                if any(contains(lower(TabNames{t}), {'cue','csplus','csminus'}))
                    panelName = sprintf('%s_StimulusIndicators', TabNames{t}); ThisPanelHeight = 70;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title',' Stimulus Type ','FontSize',11,'FontWeight','Bold','ForegroundColor',tabColor,...
                        'BackgroundColor',COLORS.panelBg,'Units','Pixels','Position',[15 VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',tabColor,'BorderWidth',2);
                    boxWidth = 80; spacing = 20; x0 = 25;
                    for iBox = 1:4
                        x = x0 + (iBox-1)*(boxWidth+spacing);
                        bgColor = [0.9 0.9 0.9];
                        switch lower(TabNames{t})
                            case 'cue', selIdx = Params.CueType; stimLabels = Meta.CueType.String;
                            case 'csplus', selIdx = Params.CSplusType; stimLabels = Meta.CSplusType.String;
                            case 'csminus', selIdx = Params.CSminusType; stimLabels = Meta.CSminusType.String;
                            otherwise, selIdx = 0; stimLabels = {};
                        end
                        if iBox == selIdx, bgColor = tabColor; end
                        BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(TabNames{t})(iBox) = uipanel(BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName), ...
                            'Units','pixels','Position',[x 15 boxWidth 30], 'BackgroundColor', bgColor, 'BorderType','line','BorderWidth',1);
                        uicontrol('Parent',BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(TabNames{t})(iBox), 'Style','text','String',stimLabels{iBox}, ...
                            'Units','normalized','Position',[0 0 1 1], 'BackgroundColor',bgColor,'ForegroundColor',COLORS.textDark, ...
                            'FontWeight','Bold','FontSize',10,'HorizontalAlignment','center');
                    end
                end
                if strcmpi(TabNames{t}, 'OptoStim')
                    panelName = 'OptoStimPreview'; panelHeight = 120;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab, 'title', '  OptoStim Preview  ', ...
                        'FontSize', 12, 'FontWeight', 'Bold', 'ForegroundColor', tabColor, 'BackgroundColor', COLORS.panelBg, ...
                        'Units', 'Pixels', 'Position', [15 VPos 455 panelHeight], 'BorderType', 'line', 'HighlightColor', tabColor, 'BorderWidth', 2);
                    BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes = axes('Parent', BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName), ...
                        'Units', 'normalized', 'Position', [0.08 0.2 0.9 0.65], 'Box', 'on', 'Color', COLORS.panelBg);
                    hold(BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes, 'on');
                    DrawOptoStim(Params);
                    VPos = VPos + panelHeight + 15;
                end
                set(BpodSystem.ProtocolFigures.ParameterGUI,'Position',[1760 400 MaxHPos+500 min(MaxVPos+120,GUIHeight)]);
            end
            nCreatedParams = ParamNum - 1;
            BpodSystem.GUIData.ParameterGUI.nParams = nCreatedParams;
            BpodSystem.GUIData.ParameterGUI.ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames(1:nCreatedParams);
            BpodSystem.GUIHandles.ParameterGUI.Labels = BpodSystem.GUIHandles.ParameterGUI.Labels(1:nCreatedParams);
            BpodSystem.GUIHandles.ParameterGUI.Params = BpodSystem.GUIHandles.ParameterGUI.Params(1:nCreatedParams);
            BpodSystem.GUIData.ParameterGUI.LastParamValues = BpodSystem.GUIData.ParameterGUI.LastParamValues(1:nCreatedParams);
            BpodSystem.GUIData.ParameterGUI.Styles = BpodSystem.GUIData.ParameterGUI.Styles(1:nCreatedParams);
            UpdateRelevantPanels(Params, Meta);
        case 'sync'
            ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
            nParams = BpodSystem.GUIData.ParameterGUI.nParams;
            for p = 1:nParams
                ThisParamName = ParamNames{p};
                ThisParamStyle = BpodSystem.GUIData.ParameterGUI.Styles(p);
                ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params(p);
                ThisParamLastValue = BpodSystem.GUIData.ParameterGUI.LastParamValues{p};
                ThisParamCurrentValue = Params.GUI.(ThisParamName);
                switch ThisParamStyle
                    case 1 
                        GUIParam = str2num(get(ThisParamHandle, 'String'));
                        if ~isequal(single(GUIParam), single(ThisParamLastValue)), Params.GUI.(ThisParamName) = GUIParam;
                        elseif ~isequal(single(ThisParamCurrentValue), single(ThisParamLastValue)), set(ThisParamHandle, 'String', num2str(ThisParamCurrentValue)); end
                    case 2 
                        GUIParam = ThisParamCurrentValue; Text = GUIParam; if ~ischar(Text), Text = num2str(Text); end
                        set(ThisParamHandle, 'String', Text);
                    case 3 
                        GUIParam = get(ThisParamHandle, 'Value');
                        if ~isequal(GUIParam, ThisParamLastValue), Params.GUI.(ThisParamName) = GUIParam;
                        elseif ~isequal(ThisParamCurrentValue, ThisParamLastValue), set(ThisParamHandle, 'Value', ThisParamCurrentValue); end
                    case 4 
                        GUIParam = get(ThisParamHandle, 'Value');
                        if ~isequal(GUIParam, ThisParamLastValue), Params.GUI.(ThisParamName) = GUIParam;
                        elseif ~isequal(ThisParamCurrentValue, ThisParamLastValue), set(ThisParamHandle, 'Value', ThisParamCurrentValue); end
                    case 6
                        GUIParam = ThisParamCurrentValue;
                    case 9
                        tableData = get(ThisParamHandle, 'Data');
                        selectorData = get(ThisParamHandle, 'UserData');
                        nRows = size(tableData, 1);
                        valvesMatrix = []; probsVector = zeros(nRows, 1); dutyMatrix = [];
                        for iR = 1:nRows
                            probsVector(iR) = tableData{iR, 1};
                            vRow = str2num(tableData{iR, 2}); dRow = str2num(tableData{iR, 3});
                            if isempty(vRow), vRow = 0; end
                            if isempty(dRow), dRow = 1; end
                            valvesMatrix = PadAndAppend(valvesMatrix, vRow);
                            dutyMatrix = PadAndAppend(dutyMatrix, dRow);
                        end
                        Params.GUI.(ThisParamName) = valvesMatrix;
                        Params.GUI.(selectorData.ProbParam) = probsVector;
                        Params.GUI.(selectorData.DutyParam) = dutyMatrix;
                end
                if ~isequal(ThisParamStyle, 5), BpodSystem.GUIData.ParameterGUI.LastParamValues{p} = Params.GUI.(ThisParamName); end
            end
            % Update StimTime based on the longest CS+/CS- odour sequence.
            syncMeta = struct;
            if isfield(Params, 'GUIMeta')
                syncMeta = Params.GUIMeta;
            elseif isfield(BpodSystem.GUIData, 'ParameterGUI') && ...
                   isfield(BpodSystem.GUIData.ParameterGUI, 'LatestMeta')
                syncMeta = BpodSystem.GUIData.ParameterGUI.LatestMeta;
            end

            isOdourSelection = false;
            maxSequenceLength = 1;
            if isfield(syncMeta, 'CSplusType') && isfield(syncMeta.CSplusType, 'String') && ...
               numel(syncMeta.CSplusType.String) >= Params.GUI.CSplusType
                currentPlusType = syncMeta.CSplusType.String{Params.GUI.CSplusType};
                isOdourSelection = isOdourSelection || strcmp(currentPlusType, 'Odour');
                if strcmp(currentPlusType, 'Odour') && isfield(Params.GUI, 'valves_CSplus')
                    seqLens = sum(Params.GUI.valves_CSplus > 0, 2);
                    if ~isempty(seqLens), maxSequenceLength = max(maxSequenceLength, max(seqLens)); end
                end
            end
            if isfield(syncMeta, 'CSminusType') && isfield(syncMeta.CSminusType, 'String') && ...
               numel(syncMeta.CSminusType.String) >= Params.GUI.CSminusType
                currentMinusType = syncMeta.CSminusType.String{Params.GUI.CSminusType};
                isOdourSelection = isOdourSelection || strcmp(currentMinusType, 'Odour');
                if strcmp(currentMinusType, 'Odour') && isfield(Params.GUI, 'valves_CSminus')
                    seqLens = sum(Params.GUI.valves_CSminus > 0, 2);
                    if ~isempty(seqLens), maxSequenceLength = max(maxSequenceLength, max(seqLens)); end
                end
            end

            if isOdourSelection
                odourSlotTime = 1.002; % preSequenceTime + pulseTime + postSequenceTime
                Params.GUI.StimTime = maxSequenceLength * odourSlotTime;
                if isfield(BpodSystem.GUIData.ParameterGUI, 'ParamIndexByName') && ...
                   isfield(BpodSystem.GUIData.ParameterGUI.ParamIndexByName, 'StimTime')
                    stimIdx = BpodSystem.GUIData.ParameterGUI.ParamIndexByName.StimTime;
                    hStim = BpodSystem.GUIHandles.ParameterGUI.Params(stimIdx);
                    if ishandle(hStim), set(hStim, 'String', num2str(Params.GUI.StimTime)); end
                    BpodSystem.GUIData.ParameterGUI.LastParamValues{stimIdx} = Params.GUI.StimTime;
                end
            end

            BpodSystem.GUIData.ParameterGUI.LatestGUIParams = Params.GUI;
            BpodSystem.GUIData.ParameterGUI.LatestMeta = syncMeta;
            if ~isempty(fieldnames(syncMeta))
                UpdateRelevantPanels(Params.GUI, syncMeta);
                if isfield(BpodSystem.GUIHandles.ParameterGUI, 'TrialStructureAxes'), DrawTrialStructure(Params.GUI, syncMeta); end
            end
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'OptoStimAxes'), DrawOptoStim(Params.GUI); end
    end
    if verLessThan('MATLAB', '8.4'), drawnow; end
    varargout{1} = Params;
end

function HandleRealTimeSync(suffix)
    global BpodSystem
    % Only sync in real-time if START hasn't been pressed
    startPressed = isappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed') && ...
        getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed');
    
    if ~startPressed
        syncFunc = str2func(sprintf('LuminoseParameterGUI_hf_%s', suffix));
        syncFunc('sync', struct('GUI', BpodSystem.GUIData.ParameterGUI.LatestGUIParams, 'GUIMeta', BpodSystem.GUIData.ParameterGUI.LatestMeta));
    end
end

function m = PadAndAppend(m, row)
    if isempty(m), m = row; return; end
    nColsM = size(m, 2); nColsR = length(row);
    if nColsM < nColsR, m = [m, zeros(size(m,1), nColsR-nColsM)];
    elseif nColsR < nColsM, row = [row, zeros(1, nColsM-nColsR)]; end
    m = [m; row];
end

function OdourTableSelectionChanged(src, ev, bottleButtons)
    if isempty(ev.Indices), return; end
    rowIdx = ev.Indices(1, 1);
    data = get(src, 'UserData'); data.ActiveRow = rowIdx; set(src, 'UserData', data);
    tableData = get(src, 'Data'); vRow = str2num(tableData{rowIdx, 2});
    for iB = 1:16
        btn = bottleButtons(iB); btnData = get(btn, 'UserData');
        isSelected = ismember(iB, vRow);
        btnColor = [0.9 0.9 0.9]; if isSelected, btnColor = btnData.TabColor; end
        if btnData.IsAir && ~isSelected, btnColor = [0.95 0.95 1.0]; end
        pos = get(btn, 'Position'); img = generateBottleImage(pos(3)-10, pos(4)-10, btnColor, [1 1 1]);
        set(btn, 'CData', img);
    end
end

function OdourAddRow(htable, suffix)
    data = get(htable, 'Data');
    newRow = {0, '0', '1'};
    set(htable, 'Data', [data; newRow]);
    selectorData = get(htable, 'UserData');
    selectorData.ActiveRow = size(data, 1) + 1;
    set(htable, 'UserData', selectorData);
    HandleRealTimeSync(suffix);
end

function OdourRemoveRow(htable, suffix)
    data = get(htable, 'Data');
    if size(data, 1) > 1
        data(end, :) = [];
        set(htable, 'Data', data);
        selectorData = get(htable, 'UserData');
        selectorData.ActiveRow = min(selectorData.ActiveRow, size(data, 1));
        set(htable, 'UserData', selectorData);
        HandleRealTimeSync(suffix);
    end
end

function UpdateRelevantPanels(Params, Meta)
    global BpodSystem

    COLORS.accentCS_plus = [0.2 0.5 0.8];
    COLORS.accentCS_minus = [0.8 0.4 0.2];
    COLORS.accentCue = [0.4 0.7 0.4];

    panelStates = struct( ...
        'Light_cue', false, 'Sound_cue', false, 'Odour_cue', false, 'Pattern_cue', false, ...
        'Light_CSplus', false, 'Sound_CSplus', false, 'Odour_CSplus', false, 'Pattern_CSplus', false, ...
        'Light_CSminus', false, 'Sound_CSminus', false, 'Odour_CSminus', false, 'Pattern_CSminus', false, ...
        'MaskLED', false, 'SinglePulse', false, 'PairedPulse', false, ...
        'DrugSpecs', logical(Params.Drug), 'EEGSpecs', logical(Params.EEG), 'EphysSpecs', logical(Params.Ephys));

    if isfield(Meta, 'CueType')
        cueType = Meta.CueType.String{Params.CueType};
        panelStates.(sprintf('%s_cue', cueType)) = true;
    end
    if isfield(Meta, 'CSplusType')
        plusType = Meta.CSplusType.String{Params.CSplusType};
        panelStates.(sprintf('%s_CSplus', plusType)) = true;
    end
    if isfield(Meta, 'CSminusType')
        minusType = Meta.CSminusType.String{Params.CSminusType};
        panelStates.(sprintf('%s_CSminus', minusType)) = true;
    end

    if logical(Params.TestPulses)
        panelStates.MaskLED = true;
        if isfield(Meta, 'TestPulsesType')
            pulseType = Meta.TestPulsesType.String{Params.TestPulsesType};
            panelStates.(pulseType) = true;
        end
    end

    panelNames = fieldnames(panelStates);
    for iPanel = 1:numel(panelNames)
        SetPanelEnabled(panelNames{iPanel}, panelStates.(panelNames{iPanel}));
    end

    tabs = {'Cue', 'CSplus', 'CSminus'};
    for iTab = 1:numel(tabs)
        tabName = tabs{iTab};
        if isfield(BpodSystem.GUIHandles.ParameterGUI, 'StimIndicators') && ...
           isfield(BpodSystem.GUIHandles.ParameterGUI.StimIndicators, tabName)
            
            switch lower(tabName)
                case 'cue', selIdx = Params.CueType; tabColor = COLORS.accentCue;
                case 'csplus', selIdx = Params.CSplusType; tabColor = COLORS.accentCS_plus;
                case 'csminus', selIdx = Params.CSminusType; tabColor = COLORS.accentCS_minus;
            end
            
            indicators = BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(tabName);
            for iInd = 1:numel(indicators)
                hInd = indicators(iInd);
                if iInd == selIdx, bgColor = tabColor; else bgColor = [0.9 0.9 0.9]; end
                set(hInd, 'BackgroundColor', bgColor);
                set(findall(hInd, 'Type', 'uicontrol'), 'BackgroundColor', bgColor);
            end
        end
    end
end

function HandleGoNogoStartButton(lockedParams)
    global BpodSystem
    StartButtonPressed(lockedParams);
    if isfield(BpodSystem.GUIData, 'ParameterGUI') && ...
            isfield(BpodSystem.GUIData.ParameterGUI, 'LatestGUIParams') && ...
            isfield(BpodSystem.GUIData.ParameterGUI, 'LatestMeta')
        UpdateRelevantPanels(BpodSystem.GUIData.ParameterGUI.LatestGUIParams, ...
            BpodSystem.GUIData.ParameterGUI.LatestMeta);
    end
end

function SetPanelEnabled(panelName, isEnabled)
    global BpodSystem
    if ~isfield(BpodSystem.GUIHandles.ParameterGUI.Panels, panelName), return; end
    panelHandle = BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName);
    if ~ishandle(panelHandle), return; end
    startPressed = isappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed') && ...
        getappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed');

    style = BpodSystem.GUIData.ParameterGUI.PanelStyles.(panelName);
    if isEnabled
        fgColor = style.ForegroundColor; bgColor = style.BackgroundColor;
        hiColor = style.HighlightColor; shadowColor = style.ShadowColor;
        textColor = [0.2 0.2 0.2]; inputBg = [1 1 1];
    else
        fgColor = [0.65 0.65 0.65]; bgColor = [0.95 0.95 0.95];
        hiColor = [0.82 0.82 0.82]; shadowColor = [0.9 0.9 0.9];
        textColor = [0.55 0.55 0.55]; inputBg = [0.94 0.94 0.94];
    end

    set(panelHandle, 'ForegroundColor', fgColor, 'BackgroundColor', bgColor, ...
        'HighlightColor', hiColor, 'ShadowColor', shadowColor);

    if isfield(BpodSystem.GUIData.ParameterGUI.PanelParams, panelName)
        paramNames = BpodSystem.GUIData.ParameterGUI.PanelParams.(panelName);
        for iParam = 1:numel(paramNames)
            paramName = paramNames{iParam};
            if ~isfield(BpodSystem.GUIData.ParameterGUI.ParamIndexByName, paramName), continue; end
            paramIdx = BpodSystem.GUIData.ParameterGUI.ParamIndexByName.(paramName);
            if ishandle(BpodSystem.GUIHandles.ParameterGUI.Labels(paramIdx))
                set(BpodSystem.GUIHandles.ParameterGUI.Labels(paramIdx), 'ForegroundColor', textColor);
            end
            if ishandle(BpodSystem.GUIHandles.ParameterGUI.Params(paramIdx))
                allowEnable = ~(startPressed && isEnabled && ...
                    any(strcmp(paramName, BpodSystem.GUIData.ParameterGUI.LockedParams)));
                SetControlEnabled(BpodSystem.GUIHandles.ParameterGUI.Params(paramIdx), isEnabled, inputBg, textColor, allowEnable);
            end
        end
    end
    childHandles = findall(panelHandle);
    for iChild = 1:numel(childHandles)
        allowEnable = ~(startPressed && isEnabled);
        SetControlEnabled(childHandles(iChild), isEnabled, inputBg, textColor, allowEnable);
    end
end

function SetControlEnabled(h, isEnabled, bgColor, textColor, allowEnable)
    if ~ishandle(h), return; end
    if isprop(h, 'Enable')
        if isEnabled && allowEnable, set(h, 'Enable', 'on'); elseif ~isEnabled, set(h, 'Enable', 'off'); end
    end
    if isprop(h, 'BackgroundColor'), try set(h, 'BackgroundColor', bgColor); catch; end; end
    if isprop(h, 'ForegroundColor'), try set(h, 'ForegroundColor', textColor); catch; end; end
end

function DisplayPNGImage()
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.ImageAxes;
    imagePath = fullfile(BpodSystem.Path.ProtocolFolder, '..', 'logo.png');
    if exist(imagePath, 'file')
        img = imread(imagePath); imshow(img, 'Parent', ax); axis(ax, 'off');
    else
        cla(ax); text(0.5, 0.5, 'Image not found', 'Parent', ax, 'HorizontalAlignment', 'center');
        axis(ax, 'off');
    end
end

function DrawTrialStructure(Params, Meta)
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.TrialStructureAxes;
    cla(ax); hold(ax,'on');

    cueTime = Params.CueTime; cueType = Meta.CueType.String{Params.CueType};
    stimTime = Params.StimTime; stimType = strcat(Meta.CSplusType.String{Params.CSplusType}, '/', Meta.CSminusType.String{Params.CSminusType});
    responseTime = Params.ResponseTime; errorDelay = Params.ErrorDelay; iti = Params.InterTrialInterval;
    itiType = 'Fixed'; if Params.VariableITI, itiType = 'Variable'; end

    blocks = {'Cue','Stim','Response','Reward/Error','ITI'};
    blockNames = {cueType, stimType, 'Lick spout', 'Water/Noise', itiType};
    colors = [0.4 0.7 0.4; 0.2 0.5 0.8; 0.8 0.8 0.2; 0.8 0.4 0.2; 0.6 0.6 0.6];
    ypos = 0.4; height = 0.4; t = 0;
    blockTimes = [cueTime, stimTime, responseTime, errorDelay, iti];
    for i = 1:length(blocks)
        rectangle(ax,'Position',[t ypos blockTimes(i) height], 'FaceColor', colors(i,:), 'EdgeColor','k');
        text(t + blockTimes(i)/2, ypos+height*1.4, blocks{i}, 'HorizontalAlignment','center','Parent',ax);
        text(t + blockTimes(i)/2, ypos+height/2, string(blockTimes(i))+'s', 'HorizontalAlignment','center','Parent',ax);
        text(t + blockTimes(i)/2, ypos-height*0.6, blockNames{i}, 'HorizontalAlignment','center', 'Rotation', 25,'Parent',ax);
        t = t + blockTimes(i);
    end
    ax.XLim = [0 t]; ax.YLim = [0 1]; axis(ax,'off');
end

function DrawOptoStim(Params)
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes;
    cla(ax); hold(ax,'on');
    widthScale = 0.5; ypos = 0.3; height = 0.4;
    totalTrial = Params.CueTime + Params.StimTime + Params.ResponseTime + Params.ErrorDelay + Params.InterTrialInterval;
    scaledTotal = totalTrial * widthScale;
    rectangle(ax, 'Position', [0 ypos scaledTotal height], 'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0 0 0]);
    if Params.TestPulsesType == 1, freq = Params.SPfrequency; duration = Params.SPduration; amplitude = Params.SPamplitude; symbol = '*';
    else freq = Params.PPfrequency; duration = Params.PPduration; amplitude = Params.PPamplitude; symbol = '**'; end
    if freq > 0
        dt = 1 / freq; tEvents = 0:dt:totalTrial; color = [0 0 max(min(amplitude,1),0)];
        for tEv = tEvents, tScaled = tEv * widthScale;
            text(ax, tScaled, ypos + height + 0.05, symbol, 'Color', color, 'FontSize', 10 + 8 * (duration / 1000), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
    end
    ax.XLim = [0 scaledTotal]; ax.YLim = [0 1]; axis(ax, 'off');
end
