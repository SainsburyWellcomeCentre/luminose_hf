function launch_bonsai(bonsaiPath, workflowPath, videoDataPath)
%% launches a bonsai workflow

leftVideoFilename = 'CameraAcqLeft.avi';
rightVideoFilename = 'CameraAcqRight.avi';
leftDataFilename = 'CameraAcqLeft.frameData.bin';
rightDataFilename = 'CameraAcqRight.frameData.bin';
start = '"--start"';
noboot = '"--no-boot"';

leftvideoPath = ['-p:LeftVideo="' fullfile(videoDataPath, leftVideoFilename) '"'];
rightvideoPath = ['-p:RightVideo="' fullfile(videoDataPath, rightVideoFilename) '"'];

leftdataPath = ['-p:LeftFrameData="' fullfile(videoDataPath, leftDataFilename) '"'];
rightdataPath = ['-p:RightFrameData="' fullfile(videoDataPath, rightDataFilename) '"'];

command = [bonsaiPath ' ' workflowPath ' ' start ' ' leftvideoPath ' ' rightvideoPath ' ' leftdataPath ' ' rightdataPath ' ' noboot];
disp(command);
system(command);
