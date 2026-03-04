function dmd_hf_2AFC(code)
    persistent dmdModel
    global S luminose

    if isempty(dmdModel)
        dmdModel = DMDmodel(luminose.dmd);
    end

    patterns = load(S.GUI.patternsInfo);
    switch(code)
        case 8
            patternInfo = patterns.CSplus;
        case 9
            patternInfo = patterns.CSminus;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run pattern sequence
    dmdModel.deliver_pattern(patternInfo);
end