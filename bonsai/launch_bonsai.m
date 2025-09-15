function launch_bonsai(bonsaiPath, workflowPath, videoDataPath, filePrefix)
    %% launches a bonsai workflow asynchronously
    
    leftVideoFilename = strcat(filePrefix, '_CameraAcqLeft.avi');
    rightVideoFilename = strcat(filePrefix, '_CameraAcqRight.avi');
    bodyVideoFilename = strcat(filePrefix, '_CameraAcqBody.avi');
    
    leftDataFilename = strcat(filePrefix, '_CameraAcqLeft.frameData.bin');
    rightDataFilename = strcat(filePrefix, '_CameraAcqRight.frameData.bin');
    bodyDataFilename = strcat(filePrefix, '_CameraAcqBody.frameData.bin');
    
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
