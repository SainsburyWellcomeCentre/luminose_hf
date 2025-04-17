%% add to path
parentFolder = "C:\Users\harrislab";
addFolders = {'MATLAB', 'Bonsai', 'Hamamatsu', 'luminoseData', 'luminoseLib', 'luminose_hf'};
cellfun(@(f) addpath(genpath(fullfile(parentFolder, f))), addFolders);
savepath;

%% constants
% DMD
mode = 3; % pattern on the fly mode

%% filepaths
% camera acquisition
bonsaiPath = '"C:\Users\harrislab\AppData\Local\Bonsai\bonsai"';
workflowPath = '"C:\Users\harrislab\luminose_hf\bonsai\BehaviourCamerasAcquisition.bonsai"';
videoDataPath = 'C:\Users\harrislab\luminoseData\video';

% DMD images
imPath = parentFolder+'Documents\DLPimages\bullseye1920x1080_inv.bmp';

% bpod
protocolFolder = "C:\Users\harrislab\Documents\MATLAB\Bpod Local\Protocols\";
protocolFile = "testGoNogo.m";
behaviourDataPath = 'C:\Users\harrislab\luminoseData\behaviour';