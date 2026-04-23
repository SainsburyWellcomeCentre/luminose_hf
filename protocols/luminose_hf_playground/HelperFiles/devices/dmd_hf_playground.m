function dmd_hf_playground(code)
% dmd_hf_playground  DMD soft-code handler for the playground protocol.
%
%   Called via parfeval from SoftCodeHandler at trial start.
%   Soft-code mapping:
%     8  - cue pattern   (imgIdx_cue,   exposure_cue)
%     9  - Left pattern  (imgIdx_Left,  exposure_Left)
%    10  - Right pattern (imgIdx_Right, exposure_Right)

    persistent dmd cueSeq cueKey leftSeq leftKey rightSeq rightKey
    global S luminose
    C = DMDController.Constants;

    if isempty(dmd)
        dmd = DMDController.DMD();
        dmd.connect();
        dmd.device.projControl(C.ALP_PROJ_MODE, C.ALP_SLAVE);
        dmd.device.projControl(C.ALP_TRIGGER_EDGE, C.ALP_EDGE_RISING);
        fprintf('DMD connected in slave mode (playground).\n');
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

        case 9   % Left
            key = [S.GUI.imgIdx_Left(1), S.GUI.exposure_Left(1)];
            if ~isequaln(leftKey, key) || isempty(leftSeq)
                if ~isempty(leftSeq), delete(leftSeq); end
                leftSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_Left(1), S.GUI.exposure_Left(1));
                leftKey = key;
            end
            seq = leftSeq;

        case 10  % Right
            key = [S.GUI.imgIdx_Right(1), S.GUI.exposure_Right(1)];
            if ~isequaln(rightKey, key) || isempty(rightSeq)
                if ~isempty(rightSeq), delete(rightSeq); end
                rightSeq = buildDMDSlaveSequence(dmd, luminose.dmd.patternsFolder, ...
                    S.GUI.imgIdx_Right(1), S.GUI.exposure_Right(1));
                rightKey = key;
            end
            seq = rightSeq;

        otherwise
            fprintf('dmd_hf_playground: unknown code %d\n', code);
            return;
    end

    dmd.halt();
    dmd.device.projStart(seq);
end
