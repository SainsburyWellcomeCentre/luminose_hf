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
            patternFolder = fullfile(dmd.patternFolder, "pattern"+code);
        case 2
            patternInfo = patterns.CSminus;
            patternFolder = fullfile(dmd.patternFolder, "pattern"+code);
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run pattern sequence
    dmdModel.play_pattern(patternInfo, patternFolder);

end