%% addpath
parentFolder = "C:\Users\harrislab\";
addFolders = {'MATLAB', 'Bonsai', 'Hamamatsu', 'LuminoseData'};
cellfun(@addpath, parentFolder+addFolders);

%% constants
imPath = parentFolder+'Documents\DLPimages\bullseye1920x1080_inv.bmp';
mode = 3; % pattern on the fly mode