%% addpath
parentFolder = "C:\Users\harrislab";
addFolders = {'MATLAB', 'Bonsai', 'Hamamatsu', 'luminoseData', 'luminose_hf'};
cellfun(@(f) addpath(genpath(fullfile(parentFolder, f))), addFolders);
savepath;

%% constants
imPath = parentFolder+'Documents\DLPimages\bullseye1920x1080_inv.bmp';
mode = 3; % pattern on the fly mode

%% filepaths
bonsaiPath = '"C:\Users\harrislab\AppData\Local\Bonsai\bonsai"';
workflowPath = '"C:\Users\harrislab\luminose_hf\bonsai\BehaviourCamerasAcquisition.bonsai"';
videoDataPath = 'C:\Users\harrislab\luminoseData';
