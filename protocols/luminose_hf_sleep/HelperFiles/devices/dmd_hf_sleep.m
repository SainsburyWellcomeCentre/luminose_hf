function dmd_hf_sleep(code)
% dmd_hf_sleep  DMD soft-code handler for the sleep protocol.
%
%   Called via parfeval from SoftCodeHandler at trial start (when TestPulses enabled).
%   Soft-code mapping:
%     9  - CS+ / trial type 1 pattern (imgIdx_CSplus, exposure_CSplus)
%    10  - CS- / trial type 2 pattern (imgIdx_CSminus, exposure_CSminus)

    persistent dmd plusSeq plusKey minusSeq minusKey
    global S luminose
    C = DMDController.Constants;

    if isempty(dmd)
        dmd = DMDController.DMD();
        dmd.connect();
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_SLAVE);
        dmd.device.projControl(C.ALP_TRIGGER_EDGE, C.ALP_EDGE_RISING);
        fprintf('DMD connected in slave mode (sleep).\n');
    end

    switch code
        case 9   % CS+ / trial type 1
            key = [S.GUI.imgIdx_CSplus(1), S.GUI.exposure_CSplus(1)];
            if ~isequaln(plusKey, key) || isempty(plusSeq)
                if ~isempty(plusSeq), delete(plusSeq); end
                plusSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_CSplus(1), S.GUI.exposure_CSplus(1));
                plusKey = key;
            end
            seq = plusSeq;

        case 10  % CS- / trial type 2
            key = [S.GUI.imgIdx_CSminus(1), S.GUI.exposure_CSminus(1)];
            if ~isequaln(minusKey, key) || isempty(minusSeq)
                if ~isempty(minusSeq), delete(minusSeq); end
                minusSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_CSminus(1), S.GUI.exposure_CSminus(1));
                minusKey = key;
            end
            seq = minusSeq;

        otherwise
            fprintf('dmd_hf_sleep: unknown code %d\n', code);
            return;
    end

    dmd.halt();
    dmd.device.projStart(seq);
end
