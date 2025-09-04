function patterns_dmd_goNogo(code)
    persistent dmdModel
    global dmd

    if isempty(dmdModel)
        dmdModel = DMDmodel(dmd);
    end

    patterns = load(dmd.patternsInfo);
    switch(code)
        case 1
            patternInfo = patterns.CSplus;
        case 2
            patternInfo = patterns.CSminus;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run pattern sequence
    dmdModel.deliver_pattern(patternInfo);
end