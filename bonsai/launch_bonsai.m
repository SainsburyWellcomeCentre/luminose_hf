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
    
    % extra "" in the command needed for interpreting filepaths with spaces
    leftvideoPath = "-p LeftVideo=""" + fullfile(videoDataPath, leftVideoFilename) + """";
    leftvideoSuffix = "-p LeftVideoSuffix=""" + "None" + """";
    rightvideoPath = "-p RightVideo=""" + fullfile(videoDataPath, rightVideoFilename) + """";
    rightvideoSuffix = "-p RightVideoSuffix=""" + "None" + """";
    bodyvideoPath = "-p BodyVideo=""" + fullfile(videoDataPath, bodyVideoFilename) + """";
    bodyvideoSuffix = "-p BodyVideoSuffix=""" + "None" + """";
    
    leftdataPath = "-p LeftFrameData=""" + fullfile(videoDataPath, leftDataFilename) + """";
    leftdataSuffix = "-p LeftFrameSuffix=""" + "None" + """";
    rightdataPath = "-p RightFrameData=""" + fullfile(videoDataPath, rightDataFilename) + """";
    rightdataSuffix = "-p RightFrameSuffix=""" + "None" + """";
    bodydataPath = "-p BodyFrameData=""" + fullfile(videoDataPath, bodyDataFilename) + """";
    bodydataSuffix = "-p BodyFrameSuffix=""" + "None" + """";

    % Full Bonsai command
    bonsaiCommand = bonsaiPath + '" "' + workflowPath + '" ' + startArg + ' ' + ...
                leftvideoPath + ' ' + leftvideoSuffix + ' ' + rightvideoPath + ' ' + ...
                rightvideoSuffix + ' ' + bodyvideoPath + ' ' + bodyvideoSuffix + ' ' + ...
                leftdataPath + ' ' + leftdataSuffix + ' ' + rightdataPath + ' ' + ...
                rightdataSuffix + ' ' + bodydataPath + ' ' + bodydataSuffix + ' ' + noboot;
    
    % Final system command to launch asynchronously
    command = 'start "" "' + bonsaiCommand;
    disp(command);
    system(command);
