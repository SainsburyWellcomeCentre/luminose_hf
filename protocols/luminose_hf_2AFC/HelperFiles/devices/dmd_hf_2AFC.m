function dmd_hf_2AFC(code)
% dmd_hf_2AFC  DMD soft-code handler for the 2AFC protocol.
%
%   Soft-code mapping:
%     8  - cue pattern   (imgIdx_cue,   exposure_cue,  nFrames_cue)
%     9  - Left pattern  (imgIdx_Left,  exposure_Left, nFrames_Left)
%    10  - Right pattern (imgIdx_Right, exposure_Right,nFrames_Right)
%
%   nFrames == 1: single BMP, slave mode (BNC trigger).
%   nFrames  > 1: designed pattern, in-memory generation.
%                 Random spots get new positions each trial; all-fixed cached.

    persistent dmd cueSeq cueKey leftSeq leftKey rightSeq rightKey
    global S luminose BpodSystem
    C = DMDController.Constants;

    if isempty(dmd)
        dmd = DMDController.DMD();
        dmd.connect();
        fprintf('DMD connected (2AFC).\n');
    end

    switch code
        case 8,   typeName = 'cue';
        case 9,   typeName = 'Left';
        case 10,  typeName = 'Right';
        otherwise
            fprintf('dmd_hf_2AFC: unknown code %d\n', code);
            return;
    end

    nF       = S.GUI.(sprintf('nFrames_%s',  typeName));
    illuTime = S.GUI.(sprintf('exposure_%s', typeName));
    imgIdx   = S.GUI.(sprintf('imgIdx_%s',   typeName));

    dmd.halt();

    if nF == 1
        key = [imgIdx, illuTime];
        [cachedSeq, cachedKey] = getCache(code, cueKey, cueSeq, leftKey, leftSeq, rightKey, rightSeq);
        if ~isequaln(cachedKey, key) || isempty(cachedSeq)
            if ~isempty(cachedSeq), delete(cachedSeq); end
            cachedSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, imgIdx, illuTime);
            [cueSeq, cueKey, leftSeq, leftKey, rightSeq, rightKey] = ...
                setCache(code, cachedSeq, key, cueSeq, cueKey, leftSeq, leftKey, rightSeq, rightKey);
        end
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_SLAVE);
        dmd.device.projControl(C.ALP_TRIGGER_EDGE, C.ALP_EDGE_RISING);
        dmd.device.projStart(cachedSeq);
    else
        design = getDesign(BpodSystem, typeName, luminose.dmd.patternsFolder);
        if isempty(design)
            fprintf('dmd_hf_2AFC: no pattern design found for %s\n', typeName);
            return;
        end
        spots  = design.spots;
        tickMs = design.tickMs;
        r_px   = design.r_px;
        hasRandom = any(~[spots.isFixed]);
        if ~hasRandom
            key = [imgIdx, nF, illuTime];
            [cachedSeq, cachedKey] = getCache(code, cueKey, cueSeq, leftKey, leftSeq, rightKey, rightSeq);
        else
            key = []; cachedSeq = []; cachedKey = [];
        end
        if ~isequaln(cachedKey, key) || isempty(cachedSeq)
            margin = r_px + 1;
            for i = 1:numel(spots)
                if ~spots(i).isFixed
                    spots(i).x = randi([margin, 2560 - margin]);
                    spots(i).y = randi([margin, 1600 - margin]);
                end
            end
            frameStack = buildPatternFrameStack(spots, r_px, tickMs);
            if ~isempty(cachedSeq), delete(cachedSeq); end
            cachedSeq = allocFrameStack(dmd, frameStack, illuTime);
            if ~hasRandom
                [cueSeq, cueKey, leftSeq, leftKey, rightSeq, rightKey] = ...
                    setCache(code, cachedSeq, key, cueSeq, cueKey, leftSeq, leftKey, rightSeq, rightKey);
            end
        end
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_MASTER);
        dmd.startFinite(cachedSeq, 1);
    end
end

function seq = allocFrameStack(dmd, frameStack, illuTime_us)
    nF  = size(frameStack, 3);
    seq = dmd.device.allocSequence(1, nF);
    for k = 1:nF, seq.put(k-1, 1, frameStack(:,:,k)); end
    seq.setBinaryMode(true);
    t = round(illuTime_us); seq.timing(t, t, 0, 0, 0); seq.setRepeat(1);
end

function design = getDesign(BpodSystem, typeName, patternsFolder)
    design = [];
    if isfield(BpodSystem, 'PluginObjects') && ...
       isfield(BpodSystem.PluginObjects, 'PatternDesign') && ...
       isfield(BpodSystem.PluginObjects.PatternDesign, typeName)
        design = BpodSystem.PluginObjects.PatternDesign.(typeName); return
    end
    patternsFolder = char(patternsFolder);
    metas = dir(fullfile(patternsFolder, sprintf('designed_%s_*_meta.mat', typeName)));
    if isempty(metas), return; end
    [~, newest] = max([metas.datenum]);
    try
        m = load(fullfile(patternsFolder, metas(newest).name), 'spots', 'tickMs', 'r_px');
        for i = 1:numel(m.spots)
            if ~isfield(m.spots(i), 'isFixed'), m.spots(i).isFixed = true; end
        end
        design = struct('spots', m.spots, 'tickMs', m.tickMs, 'r_px', m.r_px);
    catch, end
end

function [seq, key] = getCache(code, cueKey, cueSeq, leftKey, leftSeq, rightKey, rightSeq)
    switch code
        case 8,  seq = cueSeq;   key = cueKey;
        case 9,  seq = leftSeq;  key = leftKey;
        case 10, seq = rightSeq; key = rightKey;
        otherwise, seq = []; key = [];
    end
end

function [cueSeq,cueKey,leftSeq,leftKey,rightSeq,rightKey] = ...
        setCache(code,seq,key,cueSeq,cueKey,leftSeq,leftKey,rightSeq,rightKey)
    switch code
        case 8,  cueSeq  = seq; cueKey  = key;
        case 9,  leftSeq = seq; leftKey = key;
        case 10, rightSeq= seq; rightKey= key;
    end
end
