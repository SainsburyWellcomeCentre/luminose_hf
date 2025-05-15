function command = launch_bonsai(bonsaiPath, workflowPath, videoDataPath)
    %% launches a bonsai workflow asynchronously
    
    leftVideoFilename = 'CameraAcqLeft.avi';
    rightVideoFilename = 'CameraAcqRight.avi';
    bodyVideoFilename = 'CameraAcqBody.avi';
    
    leftDataFilename = 'CameraAcqLeft.frameData.bin';
    rightDataFilename = 'CameraAcqRight.frameData.bin';
    bodyDataFilename = 'CameraAcqBody.frameData.bin';
    
    startArg = '--start';
    noboot = '--no-boot';
    
    leftvideoPath = "-p:LeftVideo=" + fullfile(videoDataPath, leftVideoFilename);
    rightvideoPath = "-p:RightVideo=" + fullfile(videoDataPath, rightVideoFilename);
    bodyvideoPath = "-p:BodyVideo=" + fullfile(videoDataPath, bodyVideoFilename);
    
    leftdataPath = "-p:LeftFrameData=" + fullfile(videoDataPath, leftDataFilename);
    rightdataPath = "-p:RightFrameData=" + fullfile(videoDataPath, rightDataFilename);
    bodydataPath = "-p:BodyFrameData=" + fullfile(videoDataPath, bodyDataFilename);
    
    % Full Bonsai command
    bonsaiCommand = '"' + bonsaiPath + '" "' + workflowPath + '" ' + startArg + ' ' + ...
                    leftvideoPath + ' ' + rightvideoPath + ' ' + bodyvideoPath + ' ' + ...
                    leftdataPath + ' ' + rightdataPath + ' ' + bodydataPath + ' ' + noboot;
    
    % Final system command to launch asynchronously
    command = 'start "" ' + bonsaiCommand;
    disp(command);
    system(command);
