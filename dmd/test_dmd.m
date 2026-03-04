luminose = LuminoseConstants();
dmdModel = DMDmodel(luminose.dmd);
dmdModel.pre_stored_pattern(...
                4, [1e+6, 1e+6, 1e+6, 1e+6], [0, 0, 0, 0], [1, 2, 3, 4], 1000);
dmdModel.start_pattern();