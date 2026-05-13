function dmd_hf_playground(code)
% dmd_hf_playground  DMD soft-code handler for the playground protocol.
%
%   Soft-code mapping:
%     8  - cue pattern   (checkerboard)
%     9  - Left pattern  (checkerboard)
%    10  - Right pattern (concentric rings)
%    11  - blank (called at GetResponse entry to turn off display)
%
%   All errors and status messages are written to:
%     <tempdir>/dmd_hf_playground_log.txt

    persistent dmd blankSeq cueSeq cueKey leftSeq leftKey rightSeq rightKey

    global S

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
    dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_SLAVE);
    dmd.device.control(C.ALP_TRIGGER_EDGE, C.ALP_EDGE_RISING);
    dmd.device.projStart(cachedSeq);
    dmd_log(logFile, 'armed in SLAVE mode for %s — waiting for PWM2 trigger', typeName);

    catch ME
        dmd_log(logFile, 'ERROR: %s  at %s line %d', ME.message, ME.stack(1).name, ME.stack(1).line);
    end
end

% -----------------------------------------------------------------------

function dmd_log(logFile, fmt, varargin)
    fid = fopen(logFile, 'a');
    if fid < 0, return; end
    fprintf(fid, '[%s] ', datestr(now, 'HH:MM:SS'));
    fprintf(fid, fmt, varargin{:});
    fprintf(fid, '\n');
    fclose(fid);
end
