function dmd_hf_goNogo(code)
    global S luminose dmdModel

    if isempty(dmdModel)
        dmdModel = DMDmodel(luminose.dmd);
    end

    switch(code)
        case 8
            dmdModel.pre_stored_pattern(...
                S.GUI.Nimages_cue, S.GUI.exposure_cue, S.GUI.dark_cue, S.GUI.imgIdx_cue, S.GUI.repeat_cue);
        case 9
            % dmdModel.pre_stored_pattern(...
            %     S.GUI.Nimages_CSplus, S.GUI.exposure_CSplus, S.GUI.dark_CSplus, S.GUI.imgIdx_CSplus, S.GUI.repeat_CSplus);
            dmdModel.pattern_on_the_fly(...
                S.GUI.Nimages_CSplus, S.GUI.exposure_CSplus, S.GUI.dark_CSplus, S.GUI.imgIdx_CSplus, S.GUI.repeat_CSplus);
        case 10
            dmdModel.pre_stored_pattern(...
                S.GUI.Nimages_CSminus, S.GUI.exposure_CSminus, S.GUI.dark_CSminus, S.GUI.imgIdx_CSminus, S.GUI.repeat_CSminus);
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end
    
    % Run pattern sequence
    dmdModel.start_pattern();
end