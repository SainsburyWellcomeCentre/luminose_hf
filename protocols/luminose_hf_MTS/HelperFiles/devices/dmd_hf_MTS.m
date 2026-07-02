function dmd_hf_MTS(code)
% dmd_hf_MTS  DMD soft-code handler for the match-to-sample protocol.
%
%   Soft-code mapping:
%     8  - cue pattern
%     9  - Template pattern
%    10  - Sample pattern
%    11  - blank (sent at GetResponse entry to turn off display)
%    12  - opto pattern
%
%   Each code builds (or reuses a cached) frame stack and displays it
%   immediately in MASTER mode — no external hardware trigger involved.
%   Code 9 (Template) fires at DeliverStimTemplate. On a Match trial, code 9
%   is re-sent at DeliverStimMatch to replay the exact same pattern as the
%   sample; on Non-match, code 10 (Sample) is sent instead. Code 11 parks
%   mirrors off.
%
%   Log: <tempdir>/dmd_hf_MTS_log.txt

    persistent dmd blankSeq cueSeq cueKey templateSeq templateKey sampleSeq sampleKey optoSeq optoKey

    global S luminose BpodSystem

    logFile = fullfile(char(tempdir), 'dmd_hf_MTS_log.txt');

    try

    C = DMDController.Constants;

    if isempty(dmd)
        if libisloaded('alp50'), unloadlibrary('alp50'); end
        dmd = DMDController.DMD();
        dmd.connect();
        dmd_log(logFile, 'DMD connected');
    end

    if code == 11
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

    switch code
        case 8,   typeName = 'cue';      cachedSeq = cueSeq;      cachedKey = cueKey;
        case 9,   typeName = 'Template'; cachedSeq = templateSeq; cachedKey = templateKey;
        case 10,  typeName = 'Sample';   cachedSeq = sampleSeq;   cachedKey = sampleKey;
        case 12,  typeName = 'opto';     cachedSeq = optoSeq;     cachedKey = optoKey;
        otherwise
            dmd_log(logFile, 'unknown code %d', code);
            return;
    end

    rowIdx = 1;
    if isfield(BpodSystem.PluginObjects, 'SelectedPatternRow') && ...
       isfield(BpodSystem.PluginObjects.SelectedPatternRow, typeName)
        rowIdx = BpodSystem.PluginObjects.SelectedPatternRow.(typeName);
    end
    nFVec    = S.GUI.(sprintf('patternNFrames_%s',  typeName));
    expVec   = S.GUI.(sprintf('patternExposure_%s', typeName));
    idx      = min(rowIdx, numel(nFVec));
    nF       = nFVec(idx);
    illuTime = expVec(idx);

    dmd_log(logFile, 'code=%d type=%s row=%d nF=%d illuTime=%.0fus', ...
        code, typeName, rowIdx, nF, illuTime);

    dmd.halt();

    design = getDesign(BpodSystem, typeName, rowIdx, luminose.dmd.patternsFolder);
    if isempty(design)
        dmd_log(logFile, 'no design found for %s row %d — skipping', typeName, rowIdx);
        return;
    end
    spots     = design.spots;
    tickMs    = design.tickMs;
    r_px      = design.r_px;
    hasRandom = any(~[spots.isFixed]);

    if ~hasRandom
        key = [rowIdx, nF, illuTime];
    else
        key = [];
    end

    if hasRandom || ~isequaln(cachedKey, key) || isempty(cachedSeq)
        dmd_log(logFile, 'building frame stack for %s row %d (%d spots)', typeName, rowIdx, numel(spots));
        devH = double(dmd.device.height);
        devW = double(dmd.device.width);
        margin = r_px + 1;
        fixed = [spots.isFixed];
        px = double([spots(fixed).x]);
        py = double([spots(fixed).y]);
        for i = 1:numel(spots)
            if ~spots(i).isFixed
                for attempt = 1:500
                    xt = randi([margin, devW - margin]);
                    yt = randi([margin, devH - margin]);
                    if isempty(px) || all(max(abs(px-xt), abs(py-yt)) > 2*r_px)
                        spots(i).x = xt; spots(i).y = yt;
                        px(end+1) = xt; py(end+1) = yt; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        frameStack = buildPatternFrameStack(spots, r_px, tickMs, devH, devW);
        dmd_log(logFile, 'frame stack built: %dx%dx%d', size(frameStack,1), size(frameStack,2), size(frameStack,3));
        if ~isempty(cachedSeq), delete(cachedSeq); end
        cachedSeq = allocFrameStack(dmd, frameStack, illuTime);
        % Always store the handle back (even for random-position patterns,
        % where key stays empty so it's rebuilt every call) so the next
        % call can find and delete it instead of leaking the DMD sequence.
        switch code
            case 8,  cueSeq      = cachedSeq; cueKey      = key;
            case 9,  templateSeq = cachedSeq; templateKey = key;
            case 10, sampleSeq   = cachedSeq; sampleKey   = key;
            case 12, optoSeq     = cachedSeq; optoKey     = key;
        end
    else
        dmd_log(logFile, 'using cached sequence for %s row %d', typeName, rowIdx);
    end

    cachedSeq.setRepeat(1);
    dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_MASTER);
    dmd.device.projStart(cachedSeq);
    dmd_log(logFile, 'displaying %s row %d in MASTER mode (immediate)', typeName, rowIdx);

    catch ME
        dmd_log(logFile, 'ERROR: %s  at %s line %d', ME.message, ME.stack(1).name, ME.stack(1).line);
    end
end

% -----------------------------------------------------------------------

function seq = allocFrameStack(dmd, frameStack, illuTime_us)
    nF  = size(frameStack, 3);
    seq = dmd.device.allocSequence(1, nF);
    for k = 1:nF, seq.put(k-1, 1, frameStack(:,:,k)); end
    seq.setBinaryMode(true);
    t = round(illuTime_us);
    seq.timing(t, t, 0, 0, 0);
    seq.setRepeat(1);
end

function design = getDesign(BpodSystem, typeName, rowIdx, patternsFolder)
    design = [];
    if isfield(BpodSystem.PluginObjects, 'PatternDesigns') && ...
       isfield(BpodSystem.PluginObjects.PatternDesigns, typeName) && ...
       rowIdx <= numel(BpodSystem.PluginObjects.PatternDesigns.(typeName)) && ...
       ~isempty(BpodSystem.PluginObjects.PatternDesigns.(typeName){rowIdx})
        design = BpodSystem.PluginObjects.PatternDesigns.(typeName){rowIdx};
        return
    end
    patternsFolder = char(patternsFolder);
    rowMetas   = dir(fullfile(patternsFolder, sprintf('designed_%s_r%d_*_meta.mat', typeName, rowIdx)));
    legacyMetas = [];
    if rowIdx == 1
        all_m = dir(fullfile(patternsFolder, sprintf('designed_%s_*_meta.mat', typeName)));
        isRow = arrayfun(@(m) ~isempty(regexp(m.name, sprintf('designed_%s_r\\d+_', typeName), 'once')), all_m);
        legacyMetas = all_m(~isRow);
    end
    metas = [rowMetas; legacyMetas];
    if isempty(metas), return; end
    [~, newest] = max([metas.datenum]);
    try
        m = load(fullfile(patternsFolder, metas(newest).name), 'spots', 'tickMs', 'r_px', 'nF');
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
