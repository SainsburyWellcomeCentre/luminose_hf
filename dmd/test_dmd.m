luminose = LuminoseConstants();
dmdModel = DMDmodel(luminose.dmd);
% dmdModel.pre_stored_pattern(...
%                 4, [1e+6, 1e+6, 1e+6, 1e+6], [0, 0, 0, 0], [1, 2, 3, 4], 1000);
% dmdModel.start_pattern();
img_stack = dmdModel.generate_pattern(patterns.test);
patternsFilepath = "C:\Users\harrislab\luminose_hf\dmd\testimages";
dmdModel.save_images(img_stack, patternsFilepath);