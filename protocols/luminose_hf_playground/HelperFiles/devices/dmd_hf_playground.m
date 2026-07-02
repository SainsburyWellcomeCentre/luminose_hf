function dmd_hf_playground(code)
% dmd_hf_playground  DMD soft-code handler for the playground protocol.
%
%   Soft-code mapping:
%     8  - cue pattern   (checkerboard)
%     9  - Left pattern  (checkerboard)
%    10  - Right pattern (concentric rings)
%    11  - blank (called at GetResponse entry to turn off display)
%
%   Codes 8/9/10 build (or reuse a cached) frame stack and display it
%   immediately in MASTER mode — no external hardware trigger involved.
%
%   All errors and status messages are written to:
%     <tempdir>/dmd_hf_playground_log.txt

    persistent dmd blankSeq cueSeq cueKey leftSeq leftKey rightSeq rightKey optoSeq optoKey lastOptoCallTic

    global S luminose BpodSystem

    logFile = fullfile(char(tempdir), 'dmd_hf_playground_log.txt');

    try

    C = DMDController.Constants;

    if isempty(dmd)
        if libisloaded('alp50'), unloadlibrary('alp50'); end
        dmd = DMDController.DMD();
        dmd.connect();
        dmd_log(logFile, 'DMD connected');
    end

    if code == 11
        % In ALP binary mode mirrors hold last position even after halt.
        % Project an all-zeros frame in MASTER mode to park them off.
        dmd.halt();
        if isempty(blankSeq)
            W = double(dmd.device.width);
            H = double(dmd.device.height);
            blankSeq = dmd.device.allocSequence(1, 1);
            blankSeq.put(0, 1, zeros(H, W, 'uint8'));
            blankSeq.setBinaryMode(true);
            blankSeq.timing(100000, 100000, 0, 0, 0);
            blankSeq.setRepeat(1);
        end
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_MASTER);
        dmd.device.projStart(blankSeq);
        dmd_log(logFile, 'DMD blanked');
        return;
    end

    if code == 12
        % Debounce: drop calls that arrive faster than 50ms to prevent queued-event floods.
        if ~isempty(lastOptoCallTic) && toc(lastOptoCallTic) < 0.05
            return;
        end
        lastOptoCallTic = tic;

        % Opto pattern: fire immediately in MASTER mode on each soft-code.
        rowIdx = 1;
        if isfield(BpodSystem.PluginObjects, 'SelectedPatternRow') && ...
           isfield(BpodSystem.PluginObjects.SelectedPatternRow, 'opto')
            rowIdx = BpodSystem.PluginObjects.SelectedPatternRow.opto;
        end
        expVec   = S.GUI.patternExposure_opto;
        illuTime = round(expVec(min(rowIdx, numel(expVec))));
        nFVec    = S.GUI.patternNFrames_opto;
        nF       = nFVec(min(rowIdx, numel(nFVec)));
        key12    = [rowIdx, nF, illuTime];
        if ~isequaln(optoKey, key12) || isempty(optoSeq)
            design = loadOptoDesign(BpodSystem, 'opto', luminose.dmd.patternsFolder, rowIdx);
            if isempty(design)
                dmd_log(logFile, 'no opto design for row %d — skipping', rowIdx);
                return;
            end
            W = double(dmd.device.width); H = double(dmd.device.height);
            spots  = design.spots; r_px = design.r_px; tickMs = design.tickMs;
            margin = r_px + 1;
            fixed  = [spots.isFixed]; px = double([spots(fixed).x]); py = double([spots(fixed).y]);
            for i = 1:numel(spots)
                if ~spots(i).isFixed
                    for attempt = 1:500
                        xt = randi([margin, W-margin]); yt = randi([margin, H-margin]);
                        if isempty(px) || all(max(abs(px-xt), abs(py-yt)) > 2*r_px)
                            spots(i).x = xt; spots(i).y = yt;
                            px(end+1) = xt; py(end+1) = yt; %#ok<AGROW>
                            break;
                        end
                    end
                end
            end
            frameStack = buildPatternFrameStack(spots, r_px, tickMs, H, W);
            if ~isempty(optoSeq), delete(optoSeq); end
            nFr = size(frameStack, 3);
            optoSeq = dmd.device.allocSequence(1, nFr);
            for k = 1:nFr, optoSeq.put(k-1, 1, frameStack(:,:,k)); end
            optoSeq.setBinaryMode(true);
            optoSeq.timing(illuTime, illuTime, 0, 0, 0);
            optoSeq.setRepeat(1);
            optoKey = key12;
            dmd_log(logFile, 'built opto row %d: %d frames, illuTime=%dus', rowIdx, nFr, illuTime);
        end
        dmd.halt();
        optoSeq.setRepeat(1);
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_MASTER);
        dmd.device.projStart(optoSeq);
        dmd_log(logFile, 'opto flash row %d (MASTER)', rowIdx);
        return;
    end

    switch code
        case 8,   typeName = 'cue';   cachedSeq = cueSeq;   cachedKey = cueKey;
        case 9,   typeName = 'Left';  cachedSeq = leftSeq;  cachedKey = leftKey;
        case 10,  typeName = 'Right'; cachedSeq = rightSeq; cachedKey = rightKey;
        otherwise
            dmd_log(logFile, 'unknown code %d', code);
            return;
    end

    illuTime_us = round(S.GUI.StimTime * 1e6);
    key = illuTime_us;

    dmd.halt();

    if ~isequaln(cachedKey, key) || isempty(cachedSeq)
        W = double(dmd.device.width);
        H = double(dmd.device.height);
        [xx, yy] = meshgrid(1:W, 1:H);

        switch code
            case {8, 9}  % cue and Left: checkerboard
                blockSize = 64;
                pat = logical(mod(floor((xx-1)/blockSize) + floor((yy-1)/blockSize), 2));
            case 10      % Right: concentric rings
                r = sqrt((xx - W/2).^2 + (yy - H/2).^2);
                pat = logical(mod(floor(r / 50), 2));
        end

        if ~isempty(cachedSeq), delete(cachedSeq); end
        seq = dmd.device.allocSequence(1, 1);
        seq.put(0, 1, uint8(pat) * 255);
        seq.setBinaryMode(true);
        seq.timing(illuTime_us, 100000, 0, 0, 0);
        seq.setRepeat(1);
        cachedSeq = seq;

        switch code
            case 8,  cueSeq   = cachedSeq; cueKey   = key;
            case 9,  leftSeq  = cachedSeq; leftKey  = key;
            case 10, rightSeq = cachedSeq; rightKey = key;
        end
        dmd_log(logFile, 'built %s pattern (%dx%d illuTime=%dus)', typeName, H, W, illuTime_us);
    else
        dmd_log(logFile, 'using cached %s pattern', typeName);
    end

    cachedSeq.setRepeat(1);
    dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_MASTER);
    dmd.device.projStart(cachedSeq);
    dmd_log(logFile, 'displaying %s in MASTER mode (immediate)', typeName);

    catch ME
        dmd_log(logFile, 'ERROR: %s  at %s line %d', ME.message, ME.stack(1).name, ME.stack(1).line);
    end
end

% -----------------------------------------------------------------------

function design = loadOptoDesign(BpodSystem, typeName, patternsFolder, rowIdx)
    design = [];
    try
        pd = BpodSystem.PluginObjects.PatternDesigns;
        if isfield(pd, typeName) && numel(pd.(typeName)) >= rowIdx && ...
           ~isempty(pd.(typeName){rowIdx}) && isfield(pd.(typeName){rowIdx}, 'spots')
            design = pd.(typeName){rowIdx};
            return;
        end
    catch
    end
    patternsFolder = char(patternsFolder);
    metas = dir(fullfile(patternsFolder, sprintf('designed_%s_r%d_*_meta.mat', typeName, rowIdx)));
    if isempty(metas) && rowIdx == 1
        all_m = dir(fullfile(patternsFolder, sprintf('designed_%s_*_meta.mat', typeName)));
        isRow = arrayfun(@(m) ~isempty(regexp(m.name, sprintf('designed_%s_r\\d+_', typeName), 'once')), all_m);
        metas = all_m(~isRow);
    end
    if isempty(metas), return; end
    [~, newest] = max([metas.datenum]);
    try
        m = load(fullfile(patternsFolder, metas(newest).name), 'spots', 'tickMs', 'r_px', 'nF');
        if ~isfield(m, 'spots') || ~isfield(m, 'tickMs'), return; end
        for i = 1:numel(m.spots)
            if ~isfield(m.spots(i), 'isFixed'), m.spots(i).isFixed = true; end
        end
        nF = 1; if isfield(m, 'nF'), nF = m.nF; end
        design = struct('spots', m.spots, 'tickMs', m.tickMs, 'r_px', m.r_px, 'nF', nF);
    catch
    end
end

function dmd_log(logFile, fmt, varargin)
    fid = fopen(logFile, 'a');
    if fid < 0, return; end
    fprintf(fid, '[%s] ', datestr(now, 'HH:MM:SS'));
    fprintf(fid, fmt, varargin{:});
    fprintf(fid, '\n');
    fclose(fid);
end
