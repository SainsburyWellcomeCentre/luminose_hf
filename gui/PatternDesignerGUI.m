function PatternDesignerGUI(patternType)
% PatternDesignerGUI  Interactive DMD spot-pattern designer.
%
%   PatternDesignerGUI(patternType)  — patternType: 'cue', 'Left', or 'Right'
%
%   Click canvas to place square spots.  Each spot has onset, duration (ms)
%   and a Fixed/Random toggle.  Fixed spots stay at the drawn position every
%   trial; Random spots get a new uniform-random position each trial.
%   Press "Save Pattern" to store the design and update S.GUI.

    global S luminose BpodSystem

    DMD_W = 2560;
    DMD_H = 1600;
    SCALE = 4;
    CAN_W = DMD_W / SCALE;   % 640
    CAN_H = DMD_H / SCALE;   % 400

    r_px   = round((luminose.dmd.spotSide / luminose.dmd.projectedDMDlength) * DMD_W / 2);
    r_px   = max(r_px, 1);
    r_disp = max(r_px / SCALE, 1);

    SPOT_COLORS = [ ...
        0.2  0.6  1.0; ...
        1.0  0.4  0.2; ...
        0.3  0.85 0.3; ...
        1.0  0.9  0.1; ...
        0.8  0.2  0.8; ...
        0.1  0.9  0.9; ...
        1.0  0.5  0.7; ...
        0.6  0.4  1.0];

    % --- Background image ---
    dmdFolder = fileparts(char(luminose.dmd.patternsFolder));
    bgFile    = fullfile(dmdFolder, 'canvas_background.png');
    bgImage   = loadOrGenerateBG(bgFile, CAN_W, CAN_H);

    % --- State ---
    spots = struct('x', {}, 'y', {}, 'onset_ms', {}, 'dur_ms', {}, 'isFixed', {});

    existingFrames = S.GUI.(sprintf('nFrames_%s', patternType));
    if existingFrames > 1
        existingIdx = S.GUI.(sprintf('imgIdx_%s', patternType));
        spots = tryLoadMeta(luminose.dmd.patternsFolder, patternType, existingIdx);
    end

    % --- Figure ---
    fig = figure('Name', sprintf('Pattern Designer — %s', patternType), ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'Resize', 'off', ...
        'Position', [80 80 1130 680], ...
        'Color', [0.13 0.13 0.15], ...
        'CloseRequestFcn', @onClose);

    % --- Canvas ---
    axCanvas = axes('Parent', fig, ...
        'Units', 'pixels', 'Position', [15 15 CAN_W CAN_H], ...
        'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0 CAN_W], 'YLim', [0 CAN_H], 'YDir', 'reverse', ...
        'NextPlot', 'replacechildren', 'PickableParts', 'all', 'HitTest', 'on', ...
        'ButtonDownFcn', @onCanvasClick);

    % --- Controls ---
    PX = CAN_W + 25;
    PW = 465;

    uicontrol(fig, 'Style', 'text', 'String', 'PLACEMENT', ...
        'Position', [PX 640 PW 22], 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.8 0.8 0.8], ...
        'HorizontalAlignment', 'left');

    uicontrol(fig, 'Style', 'text', 'String', 'nSpots', ...
        'Position', [PX 610 70 22], 'FontSize', 10, ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.75 0.75 0.75], ...
        'HorizontalAlignment', 'left');
    hNSpots = uicontrol(fig, 'Style', 'edit', 'String', '3', ...
        'Position', [PX+75 610 45 24], 'FontSize', 11, ...
        'BackgroundColor', [0.22 0.22 0.25], 'ForegroundColor', [1 1 1]);

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Randomize Positions', ...
        'Position', [PX+130 608 160 28], 'FontSize', 10, ...
        'BackgroundColor', [0.2 0.45 0.7], 'ForegroundColor', [1 1 1], ...
        'Callback', @onRandomize);
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Clear All', ...
        'Position', [PX+300 608 145 28], 'FontSize', 10, ...
        'BackgroundColor', [0.5 0.2 0.2], 'ForegroundColor', [1 1 1], ...
        'Callback', @onClearAll);

    uicontrol(fig, 'Style', 'text', 'String', 'SPOTS', ...
        'Position', [PX 575 PW 22], 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.8 0.8 0.8], ...
        'HorizontalAlignment', 'left');

    hTable = uitable(fig, ...
        'Position', [PX 340 PW 230], ...
        'ColumnName', {'#', 'X (px)', 'Y (px)', 'Onset (ms)', 'Dur (ms)', 'Type'}, ...
        'ColumnWidth', {28, 68, 68, 82, 68, 90}, ...
        'ColumnEditable', [false true true true true true], ...
        'ColumnFormat', {'numeric','numeric','numeric','numeric','numeric',{'Fixed','Random'}}, ...
        'Data', {}, ...
        'FontSize', 11, ...
        'BackgroundColor', [0.2 0.2 0.22; 0.17 0.17 0.19], ...
        'ForegroundColor', [0.9 0.9 0.9], ...
        'CellEditCallback', @onTableEdit);

    uicontrol(fig, 'Style', 'text', 'String', 'TIMELINE', ...
        'Position', [PX 310 PW 22], 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.8 0.8 0.8], ...
        'HorizontalAlignment', 'left');

    axTimeline = axes('Parent', fig, ...
        'Units', 'pixels', 'Position', [PX 185 PW 118], ...
        'Color', [0.16 0.16 0.18], 'XColor', [0.6 0.6 0.6], 'YColor', 'none', ...
        'NextPlot', 'replacechildren', 'FontSize', 9);
    xlabel(axTimeline, 'Time (ms)', 'Color', [0.6 0.6 0.6], 'FontSize', 9);

    uicontrol(fig, 'Style', 'text', 'String', 'Tick (ms)', ...
        'Position', [PX 153 70 22], 'FontSize', 10, ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.75 0.75 0.75], ...
        'HorizontalAlignment', 'left');
    hTickMs = uicontrol(fig, 'Style', 'edit', 'String', '10', ...
        'Position', [PX+75 153 45 24], 'FontSize', 11, ...
        'BackgroundColor', [0.22 0.22 0.25], 'ForegroundColor', [1 1 1]);
    uicontrol(fig, 'Style', 'text', 'String', 'Frame duration for sequence', ...
        'Position', [PX+130 153 PW-130 22], 'FontSize', 9, ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.55 0.55 0.55], ...
        'HorizontalAlignment', 'left');

    uicontrol(fig, 'Style', 'text', ...
        'String', sprintf('Spot half-width: %d px  (config: spotSide=%.2fm)  — solid=Fixed, dashed=Random', ...
            r_px, luminose.dmd.spotSide), ...
        'Position', [PX 127 PW 22], 'FontSize', 9, ...
        'BackgroundColor', [0.13 0.13 0.15], 'ForegroundColor', [0.5 0.5 0.5], ...
        'HorizontalAlignment', 'left');

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save Pattern', ...
        'Position', [PX 15 215 50], 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.15 0.55 0.25], 'ForegroundColor', [1 1 0.4], ...
        'Callback', @onSave);
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cancel', ...
        'Position', [PX+235 15 210 50], 'FontSize', 14, ...
        'BackgroundColor', [0.35 0.35 0.38], 'ForegroundColor', [0.9 0.9 0.9], ...
        'Callback', @(~,~) delete(fig));

    refreshCanvas();
    refreshTimeline();
    syncTableFromSpots();

    % ---------------------------------------------------------------
    % Callbacks
    % ---------------------------------------------------------------

    function onCanvasClick(~, ~)
        pt = axCanvas.CurrentPoint(1, 1:2);
        if strcmp(get(fig, 'SelectionType'), 'normal')
            nMax = round(str2double(get(hNSpots, 'String')));
            if isnan(nMax) || nMax < 1, nMax = 3; end
            if numel(spots) >= nMax, return; end
            xDMD = max(1, min(DMD_W, round(pt(1) * SCALE)));
            yDMD = max(1, min(DMD_H, round(pt(2) * SCALE)));
            newSpot.x        = xDMD;
            newSpot.y        = yDMD;
            newSpot.onset_ms = 0;
            newSpot.dur_ms   = 100;
            newSpot.isFixed  = true;
            spots(end+1) = newSpot;
        else
            removeNearestSpot(pt(1), pt(2));
        end
        syncTableFromSpots();
        refreshCanvas();
        refreshTimeline();
    end

    function onTableEdit(~, ev)
        r   = ev.Indices(1);
        c   = ev.Indices(2);
        val = ev.NewData;
        switch c
            case 2
                if isnumeric(val) && ~isnan(val)
                    spots(r).x = round(max(1, min(DMD_W, val)));
                end
            case 3
                if isnumeric(val) && ~isnan(val)
                    spots(r).y = round(max(1, min(DMD_H, val)));
                end
            case 4
                if isnumeric(val) && ~isnan(val)
                    spots(r).onset_ms = max(0, val);
                end
            case 5
                if isnumeric(val) && ~isnan(val)
                    spots(r).dur_ms = max(1, val);
                end
            case 6
                spots(r).isFixed = strcmp(val, 'Fixed');
        end
        syncTableFromSpots();
        refreshCanvas();
        refreshTimeline();
    end

    function onRandomize(~, ~)
        n = round(str2double(get(hNSpots, 'String')));
        if isnan(n) || n < 1, n = 3; end
        margin   = r_px + 1;
        newSpots = struct('x',{},'y',{},'onset_ms',{},'dur_ms',{},'isFixed',{});
        for i = 1:n
            newSpots(i).x        = randi([margin, DMD_W - margin]);
            newSpots(i).y        = randi([margin, DMD_H - margin]);
            newSpots(i).onset_ms = 0;
            newSpots(i).dur_ms   = 100;
            newSpots(i).isFixed  = true;
        end
        spots = newSpots;
        syncTableFromSpots();
        refreshCanvas();
        refreshTimeline();
    end

    function onClearAll(~, ~)
        spots = struct('x',{},'y',{},'onset_ms',{},'dur_ms',{},'isFixed',{});
        set(hTable, 'Data', {});
        refreshCanvas();
        refreshTimeline();
    end

    function onSave(~, ~)
        if isempty(spots)
            msgbox('Place at least one spot before saving.', 'No spots', 'warn');
            return
        end
        if any([spots.dur_ms] <= 0)
            msgbox('All spots must have Duration > 0.', 'Invalid duration', 'warn');
            return
        end
        tickMs = str2double(get(hTickMs, 'String'));
        if isnan(tickMs) || tickMs <= 0
            msgbox('Tick (ms) must be a positive number.', 'Invalid tick', 'warn');
            return
        end
        totalDur = max([spots.onset_ms] + [spots.dur_ms]);
        nF       = ceil(totalDur / tickMs);

        % Store design in BpodSystem for the DMD handler
        if ~isfield(BpodSystem, 'PluginObjects') || ~isstruct(BpodSystem.PluginObjects)
            BpodSystem.PluginObjects = struct();
        end
        if ~isfield(BpodSystem.PluginObjects, 'PatternDesign')
            BpodSystem.PluginObjects.PatternDesign = struct();
        end
        BpodSystem.PluginObjects.PatternDesign.(patternType) = struct( ...
            'spots', spots, 'tickMs', tickMs, 'r_px', r_px);

        % Save sidecar .mat so the design survives a MATLAB restart
        patternsFolder = char(luminose.dmd.patternsFolder);
        if ~exist(patternsFolder, 'dir'), mkdir(patternsFolder); end
        timestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>
        prefix    = sprintf('designed_%s_%s', patternType, timestamp);
        metaFile  = fullfile(patternsFolder, sprintf('%s_meta.mat', prefix));
        save(metaFile, 'spots', 'tickMs', 'r_px', 'timestamp', 'prefix');

        % Update S.GUI  (imgIdx = 0 signals "use in-memory generation")
        S.GUI.(sprintf('imgIdx_%s',   patternType)) = 0;
        S.GUI.(sprintf('nFrames_%s',  patternType)) = nF;
        S.GUI.(sprintf('exposure_%s', patternType)) = tickMs * 1000;

        hasRandom = any(~[spots.isFixed]);
        typeStr   = 'all fixed';
        if hasRandom, typeStr = 'includes random spots'; end
        msgbox(sprintf('%d frames, tick=%gms, %s.\nS.GUI updated.', nF, tickMs, typeStr), ...
            'Pattern saved', 'help');
        delete(fig);
    end

    function onClose(~, ~)
        delete(fig);
    end

    % ---------------------------------------------------------------
    % Helpers
    % ---------------------------------------------------------------

    function removeNearestSpot(xDisp, yDisp)
        if isempty(spots), return; end
        dists = sqrt(([spots.x]/SCALE - xDisp).^2 + ([spots.y]/SCALE - yDisp).^2);
        [minD, idx] = min(dists);
        if minD <= r_disp * 1.5
            spots(idx) = [];
        end
    end

    function syncTableFromSpots()
        n    = numel(spots);
        data = cell(n, 6);
        for i = 1:n
            data{i,1} = i;
            data{i,2} = spots(i).x;
            data{i,3} = spots(i).y;
            data{i,4} = spots(i).onset_ms;
            data{i,5} = spots(i).dur_ms;
            if spots(i).isFixed
                data{i,6} = 'Fixed';
            else
                data{i,6} = 'Random';
            end
        end
        set(hTable, 'Data', data);
    end

    function refreshCanvas()
        cla(axCanvas);
        hImg = imagesc(axCanvas, [0 CAN_W], [0 CAN_H], bgImage);
        set(hImg, 'HitTest', 'off', 'PickableParts', 'none');
        colormap(axCanvas, gray);
        set(axCanvas, 'YDir', 'reverse', 'XLim', [0 CAN_W], 'YLim', [0 CAN_H], ...
            'XColor', 'none', 'YColor', 'none');
        hold(axCanvas, 'on');
        for i = 1:numel(spots)
            cx  = spots(i).x / SCALE;
            cy  = spots(i).y / SCALE;
            col = SPOT_COLORS(mod(i-1, size(SPOT_COLORS,1))+1, :);
            if spots(i).isFixed
                % Solid border
                hr = rectangle(axCanvas, ...
                    'Position', [cx-r_disp, cy-r_disp, 2*r_disp, 2*r_disp], ...
                    'FaceColor', [col 0.45], 'EdgeColor', col, 'LineWidth', 2);
                set(hr, 'HitTest', 'off', 'PickableParts', 'none');
            else
                % Dashed border (drawn as 4 line segments) + lighter fill
                hr = rectangle(axCanvas, ...
                    'Position', [cx-r_disp, cy-r_disp, 2*r_disp, 2*r_disp], ...
                    'FaceColor', [col 0.20], 'EdgeColor', 'none');
                set(hr, 'HitTest', 'off', 'PickableParts', 'none');
                xs = [cx-r_disp cx+r_disp cx+r_disp cx-r_disp cx-r_disp];
                ys = [cy-r_disp cy-r_disp cy+r_disp cy+r_disp cy-r_disp];
                hl = plot(axCanvas, xs, ys, '--', 'Color', col, 'LineWidth', 1.8);
                set(hl, 'HitTest', 'off', 'PickableParts', 'none');
            end
            ht = text(axCanvas, cx, cy, num2str(i), 'Color', [1 1 1], 'FontSize', 9, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontWeight', 'bold');
            set(ht, 'HitTest', 'off', 'PickableParts', 'none');
        end
        set(axCanvas, 'NextPlot', 'replacechildren', 'ButtonDownFcn', @onCanvasClick);
    end

    function refreshTimeline()
        cla(axTimeline);
        if isempty(spots), return; end
        n        = numel(spots);
        totalDur = max([spots.onset_ms] + [spots.dur_ms]);
        hold(axTimeline, 'on');
        for i = 1:n
            col = SPOT_COLORS(mod(i-1, size(SPOT_COLORS,1))+1, :);
            yi  = n - i + 1;
            ls  = '-';
            if ~spots(i).isFixed, ls = '--'; end
            rectangle(axTimeline, 'Position', [spots(i).onset_ms, yi-0.4, spots(i).dur_ms, 0.8], ...
                'FaceColor', col, 'EdgeColor', col*0.7, 'LineWidth', 0.8, 'LineStyle', ls);
            text(axTimeline, spots(i).onset_ms + spots(i).dur_ms/2, yi, num2str(i), ...
                'Color', [1 1 1], 'FontSize', 8, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontWeight', 'bold');
        end
        set(axTimeline, 'XLim', [0 totalDur*1.05+1], 'YLim', [0 n+1]);
        xlabel(axTimeline, 'Time (ms)', 'Color', [0.6 0.6 0.6], 'FontSize', 9);
        hold(axTimeline, 'off');
    end

end

% -----------------------------------------------------------------------
% Background image
% -----------------------------------------------------------------------
function img = loadOrGenerateBG(bgFile, W, H)
    if exist(bgFile, 'file')
        raw = imread(bgFile);
        if size(raw, 3) == 3, raw = rgb2gray(raw); end
        if size(raw,1) ~= H || size(raw,2) ~= W, raw = imresize(raw, [H W]); end
        img = raw;
        return
    end
    rng(0);
    img = uint8(randn(H, W) * 6 + 12);
    for k = 1:120
        cx = randi(W); cy = randi(H); r = randi([4 18]); val = randi([60 230]);
        x1=max(1,cx-r*3); x2=min(W,cx+r*3); y1=max(1,cy-r*3); y2=min(H,cy+r*3);
        [gx,gy] = meshgrid(x1:x2, y1:y2);
        blob = uint8(val * exp(-((gx-cx).^2+(gy-cy).^2)/(2*r^2)));
        img(y1:y2,x1:x2) = max(img(y1:y2,x1:x2), blob);
    end
    for k = 1:60
        x1=randi(W); y1=randi(H); ang=rand*2*pi; len=randi([20 120]);
        x2=round(x1+len*cos(ang)); y2=round(y1+len*sin(ang));
        nPts=max(abs(x2-x1),abs(y2-y1))+1;
        xs=round(linspace(x1,x2,nPts)); ys=round(linspace(y1,y2,nPts));
        keep=xs>=1&xs<=W&ys>=1&ys<=H;
        idx=sub2ind([H W],ys(keep),xs(keep));
        img(idx)=min(255,double(img(idx))+randi([15 45]));
    end
    imwrite(img, bgFile);
end

% -----------------------------------------------------------------------
% Pre-populate from sidecar meta file
% -----------------------------------------------------------------------
function spots = tryLoadMeta(patternsFolder, patternType, imgIdx)
    spots = struct('x',{},'y',{},'onset_ms',{},'dur_ms',{},'isFixed',{});
    patternsFolder = char(patternsFolder);
    % imgIdx=0 means designed pattern — find most recent meta for this type
    if imgIdx == 0
        metas = dir(fullfile(patternsFolder, sprintf('designed_%s_*_meta.mat', patternType)));
        if isempty(metas), return; end
        [~, newest] = max([metas.datenum]);
        metaFile = fullfile(patternsFolder, metas(newest).name);
    else
        files = dir(fullfile(patternsFolder, '*.bmp'));
        if imgIdx < 1 || imgIdx > numel(files), return; end
        tok = regexp(files(imgIdx).name, ...
            sprintf('^(designed_%s_\\d{8}_\\d{6})_f\\d+\\.bmp$', patternType), 'tokens');
        if isempty(tok), return; end
        metaFile = fullfile(patternsFolder, sprintf('%s_meta.mat', tok{1}{1}));
        if ~exist(metaFile, 'file'), return; end
    end
    try
        m = load(metaFile, 'spots');
        % Ensure isFixed field exists (back-compat with older meta files)
        for i = 1:numel(m.spots)
            if ~isfield(m.spots(i), 'isFixed')
                m.spots(i).isFixed = true;
            end
        end
        spots = m.spots;
    catch
    end
end
