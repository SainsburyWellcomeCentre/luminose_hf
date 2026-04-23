function dmd_hf_goNogo(code)
% dmd_hf_goNogo  DMD soft-code handler for the goNogo protocol.
%
%   Called via parfeval from SoftCodeHandler at trial start.
%   Connects the DMD (once per session), sets slave mode, loads the
%   appropriate pattern frame, and calls projStart so the device waits
%   for the hardware BNC trigger that fires at cue/stim time.
%
%   Soft-code mapping  (codes <= 7 go to olfactometer handler):
%     8  - cue pattern    (imgIdx_cue,    exposure_cue)
%     9  - CS+ pattern    (imgIdx_CSplus, exposure_CSplus)
%    10  - CS- pattern    (imgIdx_CSminus, exposure_CSminus)

    persistent dmd cueSeq cueKey plusSeq plusKey minusSeq minusKey
    global S luminose
    C = DMDController.Constants;

    if isempty(dmd)
        dmd = DMDController.DMD();
        dmd.connect();
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_SLAVE);
        dmd.device.projControl(C.ALP_TRIGGER_EDGE, C.ALP_EDGE_RISING);
        fprintf('DMD connected in slave mode (goNogo).\n');
    end

    switch code
        case 8   % cue
            key = [S.GUI.imgIdx_cue(1), S.GUI.exposure_cue(1)];
            if ~isequaln(cueKey, key) || isempty(cueSeq)
                if ~isempty(cueSeq), delete(cueSeq); end
                cueSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_cue(1), S.GUI.exposure_cue(1));
                cueKey = key;
            end
            seq = cueSeq;

        case 9   % CS+
            key = [S.GUI.imgIdx_CSplus(1), S.GUI.exposure_CSplus(1)];
            if ~isequaln(plusKey, key) || isempty(plusSeq)
                if ~isempty(plusSeq), delete(plusSeq); end
                plusSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_CSplus(1), S.GUI.exposure_CSplus(1));
                plusKey = key;
            end
            seq = plusSeq;

        case 10  % CS-
            key = [S.GUI.imgIdx_CSminus(1), S.GUI.exposure_CSminus(1)];
            if ~isequaln(minusKey, key) || isempty(minusSeq)
                if ~isempty(minusSeq), delete(minusSeq); end
                minusSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_CSminus(1), S.GUI.exposure_CSminus(1));
                minusKey = key;
            end
            seq = minusSeq;

        otherwise
            fprintf('dmd_hf_goNogo: unknown code %d\n', code);
            return;
    end

    dmd.halt();
    dmd.device.projStart(seq);
end
