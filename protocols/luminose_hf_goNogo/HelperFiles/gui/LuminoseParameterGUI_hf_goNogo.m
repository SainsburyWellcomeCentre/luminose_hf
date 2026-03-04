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
        'VariableITI', ...
        'TestPulsesType', ...
        'Ephys', 'EphysType', 'EphysCoords', ...
        'EEG', 'EEGchannels', 'EMGchannels', ...
        'Drug', 'DrugType', 'DrugDose'
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
                % Find any params not assigned a panel and assign to
                % new 'Parameters' panel
                paramsInPanels = {}; 
                for i = 1:nPanels
                    paramsInPanels = [paramsInPanels Panels.(PanelNames{i})];
                end
                paramsInDefaultPanel = {};
                
                for i = 1:nParameters
                    if ~any(strcmp(paramNames{i}, paramsInPanels))
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
                % Determine tab color
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
                    ThisPanelParamNames = ThisPanelParamNames(end:-1:1);
                    nParams = length(ThisPanelParamNames);
                    paramHeight = 35;      % height of each parameter row
                    panelPadding = 28;      % optional small padding at top
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
                        % Label
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
                                BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = uicontrol(htab,'Style', 'edit', 'String', num2str(ThisParam), 'Position', [HPos+220 VPos+InPanelPos+2 200 25], 'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
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
                            case 'togglebutton' % INCOMPLETE
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
                                BpodSystem.GUIHandles.ParameterGUI.Params{ParamNum} = htable;
                                ThisPanelHeight = ThisPanelHeight + (htable.Position(4)-25);
                                BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}).Position(4) = ThisPanelHeight;
                                BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = htable.Data;
                            otherwise
                                error('Invalid parameter style specified. Valid parameters are: ''edit'', ''text'', ''checkbox'', ''popupmenu'', ''togglebutton'', ''pushbutton''');
                        end
                        InPanelPos = InPanelPos + paramHeight;
                        ParamNum = ParamNum + 1;
                    end
                    % Check next panel to see if it will fit, otherwise start new column
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
                        if VPos > MaxVPos
                            MaxVPos = VPos;
                        end
                        VPos = 15;
                    else
                        if VPos > MaxVPos
                            MaxVPos = VPos;
                        end
                    end
                    if HPos > MaxHPos
                        MaxHPos = HPos;
                    end
                end                  
                
                % --- Start Button ---
                if contains(lower(TabNames{t}),'trial')
                    BpodSystem.GUIHandles.ParameterGUI.StartButton = uicontrol(htab, ...
                        'Style', 'pushbutton', ...
                        'String', 'START', ...
                        'Position', [15 VPos 455 50], ...
                        'FontSize', 16, 'FontWeight', 'Bold', ...
                        'BackgroundColor', [0.2 0.7 0.3], ...
                        'ForegroundColor', 'white', ...
                        'FontName', 'Segoe UI', ...
                        'Callback', @(~,~) StartButtonPressed(LOCKED_PARAMS));
                    VPos = VPos + 60;
                end

                % ---Logo Display Panel ---
                if contains(lower(TabNames{t}),'trial')
                    panelName = 'logo';
                    ThisPanelHeight = 250;  % Adjust height as needed
                    
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title',sprintf(''),'FontSize',12,'FontWeight','Bold',...
                        'ForegroundColor',COLORS.accentTrial,'BackgroundColor',COLORS.panelBg,...
                        'Units','Pixels','Position',[HPos VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',COLORS.accentTrial,'BorderWidth',2,'ShadowColor',[0.8 0.8 0.8]);
                    
                    BpodSystem.GUIHandles.ParameterGUI.ImageAxes = axes('Parent',...
                        BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName),...
                        'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
                    
                    % Display the PNG image
                    DisplayPNGImage();
                    
                    VPos = VPos + ThisPanelHeight + 15;
                end
                % --- Trial Structure Panel ---
                if contains(lower(TabNames{t}),'task')
                    panelName = 'TrialStructure';
                    ThisPanelHeight = 90;
                
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title',sprintf('  %s  ',panelName),'FontSize',12,'FontWeight','Bold',...
                        'ForegroundColor',COLORS.accentTrial,'BackgroundColor',COLORS.panelBg,...
                        'Units','Pixels','Position',[HPos VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',COLORS.accentTrial,'BorderWidth',2,'ShadowColor',[0.8 0.8 0.8]);
                    BpodSystem.GUIHandles.ParameterGUI.TrialStructureAxes = axes('Parent',...
                        BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName),...
                        'Units','normalized','Position',[0.08 0.15 0.9 0.7],...
                        'Box','on','XColor',[0.3 0.3 0.3],'YColor','none','Color',COLORS.panelBg);
                    DrawTrialStructure(Params, Meta);
    
                    VPos = VPos + ThisPanelHeight + 15;
                end
                % --- Stimulus indicators ---
                if any(contains(lower(TabNames{t}), {'cue','csplus','csminus'}))
                    panelName = sprintf('%s_StimulusIndicators', TabNames{t});
                    ThisPanelHeight = 70;
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab,...
                        'title',' Stimulus Type ','FontSize',11,'FontWeight','Bold',...
                        'ForegroundColor',tabColor,'BackgroundColor',COLORS.panelBg,...
                        'Units','Pixels','Position',[15 VPos 455 ThisPanelHeight],...
                        'BorderType','line','HighlightColor',tabColor,'BorderWidth',2);
    
                    % Create four boxes + labels
                    boxWidth = 80;
                    spacing = 20;
                    x0 = 25;
                    for iBox = 1:4
                        x = x0 + (iBox-1)*(boxWidth+spacing);
                        % Default gray
                        bgColor = [0.9 0.9 0.9];
                        
                        % Determine selected index for this tab
                        switch lower(TabNames{t})
                            case 'cue'
                                selIdx = Params.CueType;
                                stimLabels = Meta.CueType.String;
                            case 'csplus'
                                selIdx = Params.CSplusType;
                                stimLabels = Meta.CSplusType.String;
                            case 'csminus'
                                selIdx = Params.CSminusType;
                                stimLabels = Meta.CSminusType.String;
                            otherwise
                                selIdx = 0;
                                stimLabels = {};
                        end
                        
                        % If this box is the selected type, color it with the tab color
                        if iBox == selIdx
                            bgColor = tabColor;
                        end
                        
                        BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(TabNames{t})(iBox) = ...
                            uipanel(BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName), ...
                            'Units','pixels','Position',[x 15 boxWidth 30], ...
                            'BackgroundColor', bgColor, 'BorderType','line', ...
                            'HighlightColor',[0.6 0.6 0.6], 'BorderWidth',1);
                        
                        uicontrol('Parent',BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(TabNames{t})(iBox), ...
                            'Style','text','String',stimLabels{iBox}, ...
                            'Units','normalized','Position',[0 0 1 1], ...
                            'BackgroundColor',bgColor,'ForegroundColor',[0.2 0.2 0.2], ...
                            'FontName','Segoe UI','FontWeight','Bold','FontSize',10, ...
                            'HorizontalAlignment','center');
                    end
    
                end
                % --- OptoStim Visualization Panel ---
                if strcmpi(TabNames{t}, 'OptoStim')
                    panelName = 'OptoStimPreview';
                    panelHeight = 120; % adjust as needed
                
                    % Create panel styled like others
                    BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName) = uipanel(htab, ...
                        'title', '  OptoStim Preview  ', ...
                        'FontSize', 12, 'FontWeight', 'Bold', ...
                        'ForegroundColor', tabColor, ...
                        'BackgroundColor', COLORS.panelBg, ...
                        'Units', 'Pixels', ...
                        'Position', [15 VPos 455 panelHeight], ...
                        'BorderType', 'line', ...
                        'HighlightColor', tabColor, ...
                        'BorderWidth', 2, ...
                        'ShadowColor', [0.8 0.8 0.8]);
                
                    % Create axes inside the panel
                    BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes = axes('Parent', ...
                        BpodSystem.GUIHandles.ParameterGUI.Panels.(panelName), ...
                        'Units', 'normalized', ...
                        'Position', [0.08 0.2 0.9 0.65], ...
                        'Box', 'on', ...
                        'XColor', [0.3 0.3 0.3], 'YColor', 'none', ...
                        'Color', COLORS.panelBg);
                    hold(BpodSystem.GUIHandles.ParameterGUI.OptoStimAxes, 'on');
                    DrawOptoStim(Params);
                
                    % Update layout tracking
                    VPos = VPos + panelHeight + 15;
                end


                set(BpodSystem.ProtocolFigures.ParameterGUI,'Position',[1760 520 MaxHPos+500 min(MaxVPos+120,GUIHeight)]);
            end
        case 'sync'
            ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
            nParams = BpodSystem.GUIData.ParameterGUI.nParams;
            for p = 1:nParams
                ThisParamName = ParamNames{p};
                ThisParamStyle = BpodSystem.GUIData.ParameterGUI.Styles(p);
                ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params(p);
                ThisParamLastValue = BpodSystem.GUIData.ParameterGUI.LastParamValues{p};
                ThisParamCurrentValue = Params.GUI.(ThisParamName); % Use single precision to avoid problems with ==
                switch ThisParamStyle
                    case 1 % Edit
                        GUIParam = str2double(get(ThisParamHandle, 'String'));
                        if single(GUIParam) ~= single(ThisParamLastValue)
                            Params.GUI.(ThisParamName) = GUIParam;
                        elseif single(ThisParamCurrentValue) ~= single(ThisParamLastValue)
                            set(ThisParamHandle, 'String', num2str(ThisParamCurrentValue));
                        end
                    case 2 % Text
                        GUIParam = ThisParamCurrentValue;
                        Text = GUIParam;
                        if ~ischar(Text)
                            Text = num2str(Text);
                        end
                        set(ThisParamHandle, 'String', Text);
                    case 3 % Checkbox
                        GUIParam = get(ThisParamHandle, 'Value');
                        if GUIParam ~= ThisParamLastValue
                            Params.GUI.(ThisParamName) = GUIParam;
                        elseif ThisParamCurrentValue ~= ThisParamLastValue
                            set(ThisParamHandle, 'Value', ThisParamCurrentValue);
                        end
                    case 4 % Popupmenu
                        GUIParam = get(ThisParamHandle, 'Value');
                        if GUIParam ~= ThisParamLastValue
                            Params.GUI.(ThisParamName) = GUIParam;
                        elseif ThisParamCurrentValue ~= ThisParamLastValue
                            set(ThisParamHandle, 'Value', ThisParamCurrentValue);
                        end
                end
                if ThisParamStyle ~= 5
                    BpodSystem.GUIData.ParameterGUI.LastParamValues{p} = Params.GUI.(ThisParamName);
                end
            end
            Meta = Params.GUIMeta;
                
            % Update Trial Structure diagram
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'TrialStructureAxes')
                DrawTrialStructure(Params.GUI, Meta);
            end
            
            % Update OptoStim preview
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'OptoStimAxes')
                DrawOptoStim(Params.GUI);
            end
            
            % Update Stimulus Indicators
            if isfield(BpodSystem.GUIHandles.ParameterGUI, 'StimIndicators')
                tabNames = fieldnames(BpodSystem.GUIHandles.ParameterGUI.StimIndicators);
                COLORS.accentCS_plus = [0.2 0.5 0.8];
                COLORS.accentCS_minus = [0.8 0.4 0.2];
                COLORS.accentCue = [0.4 0.7 0.4];
                
                for iTab = 1:length(tabNames)
                    tabName = tabNames{iTab};
                    
                    % Determine which parameter and color scheme to use
                    switch lower(tabName)
                        case 'cue'
                            selIdx = Params.GUI.CueType;
                            tabColor = COLORS.accentCue;
                            stimLabels = Meta.CueType.String;
                        case 'csplus'
                            selIdx = Params.GUI.CSplusType;
                            tabColor = COLORS.accentCS_plus;
                            stimLabels = Meta.CSplusType.String;
                        case 'csminus'
                            selIdx = Params.GUI.CSminusType;
                            tabColor = COLORS.accentCS_minus;
                            stimLabels = Meta.CSminusType.String;
                        otherwise
                            continue;
                    end
                    
                    % Update each indicator box
                    for iBox = 1:4
                        if iBox == selIdx
                            bgColor = tabColor;
                        else
                            bgColor = [0.9 0.9 0.9];
                        end
                        set(BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(tabName)(iBox), ...
                            'BackgroundColor', bgColor);
                        % Update text color
                        children = get(BpodSystem.GUIHandles.ParameterGUI.StimIndicators.(tabName)(iBox), 'Children');
                        if ~isempty(children)
                            set(children(1), 'BackgroundColor', bgColor);
                        end
                    end
                end
            end

        otherwise
        error('ParameterGUI must be called with a valid op code: ''init'' or ''sync''');
    end
    if verLessThan('MATLAB', '8.4')
        drawnow;
    end
    varargout{1} = Params;
end

function StartButtonPressed(lockedParams)
    global BpodSystem

    % Signal that start was pressed
    setappdata(BpodSystem.ProtocolFigures.ParameterGUI, 'StartPressed', true);

    % Disable each locked parameter's GUI control
    paramNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
    for i = 1:length(paramNames)
        if any(strcmp(paramNames{i}, lockedParams))
            % Handles can be numeric array or cell array (for tables)
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

    % Grey out and relabel the START button
    set(BpodSystem.GUIHandles.ParameterGUI.StartButton, ...
        'String', '● RUNNING', ...
        'BackgroundColor', [0.15 0.55 0.25], ...
        'ForegroundColor', [1 1 0.4], ...
        'FontSize', 16, ...
        'Enable', 'on', ...
        'Callback', @(~,~) []);
end

function DisplayPNGImage()
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.ImageAxes;
    
    % Define the path to your PNG file
    imagePath = fullfile(BpodSystem.Path.ProtocolFolder, '..', 'logo.png');

    % Check if file exists
    if exist(imagePath, 'file')
        img = imread(imagePath);
        imshow(img, 'Parent', ax);
        axis(ax, 'off');
    else
        cla(ax);
        text(0.5, 0.5, {'Image not found:', imagePath, '', 'Please place your PNG file in the correct location'}, ...
            'Parent', ax, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 10, ...
            'Color', [0.8 0.2 0.2], ...
            'Interpreter', 'none');
        axis(ax, 'off');
        ax.XLim = [0 1];
        ax.YLim = [0 1];
    end
end

function DrawTrialStructure(Params, Meta)
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.TrialStructureAxes;
    cla(ax);
    hold(ax,'on');

    cueTime = Params.CueTime;
    cueType = Meta.CueType.String{Params.CueType};
    stimTime = Params.StimTime;
    stimType = strcat(Meta.CSplusType.String{Params.CSplusType}, '/', Meta.CSminusType.String{Params.CSminusType});
    responseTime = Params.ResponseTime;
    errorDelay = Params.ErrorDelay;
    iti = Params.InterTrialInterval;
    itiVariable = Params.VariableITI;
    if itiVariable
        itiType = 'Variable';
    else
        itiType = 'Fixed';
    end

    blocks = {'Cue','Stim','Response','Reward/Error','ITI'};
    blockNames = {cueType, stimType, 'Lick spout', strcat('Water/','Noise'), itiType};
    colors = [0.4 0.7 0.4;
              0.2 0.5 0.8;
              0.8 0.8 0.2;
              0.8 0.4 0.2;
              0.6 0.6 0.6];
    ypos = 0.4;
    height = 0.4;

    t = 0;
    blockTimes = [cueTime, stimTime, responseTime, errorDelay, iti];
    
    for i = 1:length(blocks)
        rectangle(ax,'Position',[t ypos blockTimes(i) height], ...
            'FaceColor', colors(i,:), 'EdgeColor','k');
        text(t + blockTimes(i) - blockTimes(i)*0.5, ypos+height*1.4, blocks{i}, ...
            'HorizontalAlignment','center','VerticalAlignment','middle','Parent',ax);
        text(t + blockTimes(i) - blockTimes(i)*0.5, ypos+height/2, string(blockTimes(i))+'s', ...
            'HorizontalAlignment','center','VerticalAlignment','middle','Parent',ax);
        text(t + blockTimes(i) - blockTimes(i)*0.5, ypos-height*0.6, blockNames{i}, ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'Rotation', 25,'Parent',ax);
        t = t + blockTimes(i);
    end

    ax.XLim = [0 t];
    ax.YLim = [0 1];
    ax.XTick = [];
    ax.YTick = [];
    hold(ax,'on');
    axis(ax,'off');
end

function DrawOptoStim(Params)
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