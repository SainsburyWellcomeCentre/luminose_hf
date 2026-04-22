function varargout = LuminoseParameterGUI_hf_playground(varargin)
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
    
            if isfield(Params, 'GUIMeta')
                Meta = Params.GUIMeta;
            else
                Meta = struct;
            end
            if isfield(Params, 'GUIPanels')
                Panels = Params.GUIPanels;
                PanelNames = fieldnames(Panels);
                nPanels = length(PanelNames);
                paramNames = fieldnames(Params.GUI);
                nParameters = length(paramNames);
                paramPanels = zeros(1,nParameters);
                paramsInPanels = {}; 
                for i = 1:nPanels
                    paramsInPanels = [paramsInPanels Panels.(PanelNames{i})];
                end
                paramsInDefaultPanel = {};
                for i = 1:nParameters
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
                if contains(lower(TabNames{t}),'left')
                    tabColor = COLORS.accentCS_plus;
                elseif contains(lower(TabNames{t}),'right')
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
    
                    InPanelPos = 15;
                    for i = 1:nParams
                        ThisParamName = ThisPanelParamNames{i};
                        ThisParam = Params.(ThisParamName);
                        BpodSystem.GUIData.ParameterGUI.ParamNames{ParamNum} = ThisParamName;
                        if ischar(ThisParam)
                            BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = NaN;
                        else
                            BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = ThisParam;
                        end
                        if isfield(Meta, ThisParamName)
                            if isstruct(Meta.(ThisParamName))
                                if isfield(Meta.(ThisParamName), 'Style')
                                    ThisParamStyle = Meta.(ThisParamName).Style;
                                    if isfield(Meta.(ThisParamName), 'String')
                                        ThisParamString = Meta.(ThisParamName).String;
                                    else
                                        ThisParamString = '';
                                    end
                                else
                                    error(['Style not specified for parameter ' ThisParamName '.'])
                                end
                            else
                                error(['GUIMeta entry for ' ThisParamName ' must be a struct.'])
                            end
                        else
                            ThisParamStyle = 'edit';
                            ThisParamValue = NaN;
                        end
                        underscorePos = strfind(ThisParamName,'_');
                        if isempty(underscorePos)
                            labelStr = ThisParamName;
                        else
                            labelStr = ThisParamName(1:underscorePos(1)-1);
                        end
                        labelStr = strrep(labelStr,'_',' ');
    
                        BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum) = uicontrol(htab,...
                            'Style','text','String',labelStr,'Position',[HPos+15 VPos+InPanelPos 215 28],...
                            'FontWeight','normal','FontSize',11,'BackgroundColor',COLORS.panelBg,...
                            'ForegroundColor',COLORS.textDark,'FontName','Segoe UI','HorizontalAlignment','Left');
    
                        switch lower(ThisParamStyle)
                            case 'edit'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 1;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'edit', 'String', mat2str(ThisParam), 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'edittext'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 8;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'edit', 'String', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'text'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 2;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'text', 'String', num2str(ThisParam), 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'checkbox'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 3;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'checkbox', 'Value', ThisParam, 'String', '   (check to activate)', 'Position', [HPos+220 VPos+InPanelPos+4 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'popupmenu'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 4;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'popupmenu', 'String', ThisParamString, 'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'togglebutton'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 5;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'togglebutton', 'String', ThisParamString, 'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                            case 'pushbutton'
                                BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 6;
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'pushbutton', 'String', ThisParamString,...
                                    'Value', ThisParam, 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12,...
                                    'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
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
                                    'ColumnEditable',true(1,numel(columnLabel)), 'FontSize', 12);
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
                                
                                % Increased height for better spacing
                                selectorHeight = 260;
                                selectorPanel = uipanel(htab, 'Units', 'pixels', ...
                                    'Position', [HPos+10 VPos+InPanelPos 435 selectorHeight], ...
                                    'BackgroundColor', COLORS.panelBg, 'BorderType', 'none');
                                
                                mapping = getOdourMapping();
                                bottleButtons = zeros(1, 16);
                                % Determine which bottles to highlight (initial selection is first row)
                                if ~isempty(matrixValves)
                                    initialVRow = matrixValves(1, :);
                                else
                                    initialVRow = [];
                                end
                                
                                for iBottle = 1:16
                                    row = ceil(iBottle/8);
                                    col = mod(iBottle-1, 8) + 1;
                                    % Positions adjusted for new selectorHeight
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
                                
                                % Wider table and better column distribution
                                otable = uitable(selectorPanel, 'Data', tableData, ...
                                    'ColumnName', {'Prob', 'Valves', 'DutyCycles'}, ...
                                    'ColumnWidth', {50, 160, 160}, 'ColumnEditable', [true, true, true], ...
                                    'Position', [5 10 385 125], 'FontSize', 10);
                                set(otable, 'CellSelectionCallback', @(src, ev) OdourTableSelectionChanged(src, ev, bottleButtons));
                                
                                % Repositioned +/- buttons to the right of the wider table
                                uicontrol(selectorPanel, 'Style', 'pushbutton', 'String', '+', ...
                                    'Position', [395 90 32 32], 'FontSize', 14, 'FontWeight', 'bold', ...
                                    'Callback', @(~, ~) OdourAddRow(otable));
                                uicontrol(selectorPanel, 'Style', 'pushbutton', 'String', '-', ...
                                    'Position', [395 50 32 32], 'FontSize', 14, 'FontWeight', 'bold', ...
                                    'Callback', @(~, ~) OdourRemoveRow(otable));

                                selectorData = struct('Buttons', bottleButtons, 'Table', otable, ...
                                    'ProbParam', probParam, 'DutyParam', dutyParam, 'Mapping', mapping, 'ActiveRow', 1);
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
                        'FontName', 'Segoe UI', 'Callback', @(~,~) StartButtonPressed(LOCKED_PARAMS));
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
                if any(contains(lower(TabNames{t}), {'cue','left','right'}))
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
                            case 'left', selIdx = Params.LeftType; stimLabels = Meta.LeftType.String;
                            case 'right', selIdx = Params.RightType; stimLabels = Meta.RightType.String;
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
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'TrialStructureAxes'), DrawTrialStructure(Params.GUI, Params.GUIMeta); end
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'OptoStimAxes'), DrawOptoStim(Params.GUI); end
    end
    if verLessThan('MATLAB', '8.4'), drawnow; end
    varargout{1} = Params;
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

function OdourAddRow(htable)
    data = get(htable, 'Data');
    newRow = {0, '0', '1'};
    set(htable, 'Data', [data; newRow]);
end

function OdourRemoveRow(htable)
    data = get(htable, 'Data');
    if size(data, 1) > 1
        data(end, :) = [];
        set(htable, 'Data', data);
    end
end
