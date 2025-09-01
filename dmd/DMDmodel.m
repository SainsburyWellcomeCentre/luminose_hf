classdef DMDmodel < handle
    properties
        mode
        testImagePath
        DMD

        dmdWidth % width of DMD array in mm
        dmdLength % length of DMD array in mm
        numPixel_dmdLength % number of pixels along length of DMD
        numPixel_dmdWidth % number of pixels along width of DMD
        pixelSide % length of one side of square pixel 
        pixelArea % area of pixel
        
        projectedDMDwidth % width of projected image of DMD array in mm
        projectedDMDlength % length of projected image of DMD array in mm
        scalingFactor % magnification of the image of the DMD array
        spatialResolution % length of one side of projected pixel in mm
        spotSide % length of one side of square illuminated spot in mm
        spotArea % area of square illuminated spot
        numPixel_spotSide % number of pixels along one side of square illuminated spot
        numPixel_spotArea % number of pixels in the area of square illuminated spot
        numSpots_width % number of spots along width of DMD array
        numSpots_length % number of spots along length of DMD array
        numTotalSpots % total number of spots
        
        patternInfo % struct containing fields: xpos_activatedSpots, ypos_activatedSpots, time_activatedSpots, dur_activatedSpots with num_activatedSpots entries
        durationPattern % duration of entire pattern in s
        samplingratePattern
        framesPattern

    end
    
    methods
        function self = DMDmodel(dmd)
            self.mode = dmd.mode;
            self.testImagePath = dmd.testImagePath;
            self.projectedDMDlength = dmd.projectedDMDlength;
            self.spotSide = dmd.spotSide;
            self.durationPattern = dmd.durationPattern;
            
            self.dmdLength = 14.5152;
            self.dmdWidth = 8.1648;
            self.numPixel_dmdLength = 1920;
            self.numPixel_dmdWidth = 1080;
            self.samplingratePattern = 10000;

            self.pixelSide = self.dmdLength / self.numPixel_dmdLength;
            self.pixelArea = self.pixelSide ^ 2;
            self.scalingFactor = self.projectedDMDlength / self.dmdLength;
            self.projectedDMDwidth = self.scalingFactor * self.dmdWidth;
            self.spatialResolution = self.scalingFactor * self.pixelSide;
            self.spotArea = self.spotSide ^ 2;
            self.numPixel_spotSide = round(self.spotSide / self.spatialResolution);
            self.numPixel_spotArea = round(self.numPixel_spotSide ^ 2);
            self.numSpots_width = round(self.projectedDMDwidth / self.spotSide);
            self.numSpots_length = round(self.projectedDMDlength / self.spotSide);
            self.numTotalSpots = self.numSpots_width * self.numSpots_length;
  
            self.framesPattern = self.samplingratePattern * self.durationPattern;

            % self.DMD = DMD('debug', 1);
            % self.DMD.setMode(self.mode);
            % disp(self.DMD.fwVersion);
            % disp(self.DMD.status);

        end

        function img_stack = generate_pattern(self, patternInfo)
            img_stack = false(self.numPixel_dmdWidth, self.numPixel_dmdLength, self.framesPattern);
            half_size = floor(self.numPixel_spotSide / 2);

            for ch = 1:patternInfo.N_channels
                x_center = patternInfo.xpositions(ch);  
                y_center = patternInfo.ypositions(ch); 
                x_range = (x_center - half_size):(x_center + half_size);
                y_range = (y_center - half_size):(y_center + half_size);
                
                % Ensure ranges are within image bounds
                valid_x = x_range > 0 & x_range <= self.numPixel_dmdLength;
                assert(all(valid_x), sprintf("channel %d x-position %d out of bounds for number of pixels in spot side %0.2f", ch, x_center, self.numPixel_spotSide));
                valid_y = y_range > 0 & y_range <= self.numPixel_dmdWidth;
                assert(all(valid_y), sprintf("channel %d y-position %d out of bounds for number of pixels in spot side %0.2f", ch, y_center, self.numPixel_spotSide));

                start_time = patternInfo.activation_time(ch);  % list of activation start times
                assert(start_time>0, sprintf("channel %d activation time %0.2f ms out of bounds for pattern time %0.2f ms", ch, start_time, self.durationPattern));
                start_idx = round(start_time * self.samplingratePattern);
                duration_frames = round(patternInfo.activation_duration(ch) * self.samplingratePattern);
                end_idx = min(start_idx + duration_frames - 1, self.framesPattern);
                
                % Insert spot into image at time t
                img_stack(y_range, x_range, start_idx:end_idx) = true;

            end
        end
        
        function save_video(self, img_stack, filepath)
            v = VideoWriter(filepath, 'Grayscale AVI');
            v.FrameRate = self.samplingratePattern;
            open(v);
            writeVideo(v, uint8(img_stack)*255);
            close(v);
        end
        
        function save_patterns(self, img_stack, patternsFilepath)
            [H, W, N] = size(img_stack);
            frames_2D = reshape(img_stack, [], N)';  % size [N x H*W]
            [unique_frames, ~, idx_map] = unique(frames_2D, 'rows');
            % Reshape back to 3D stack
            n_unique = size(unique_frames, 1);
            patterns = reshape(unique_frames', H, W, n_unique);

            for k = 1:size(patterns, 3)
                imwrite(patterns(:, :, k), sprintf('%s_%03d.bmp', patternsFilepath, k));
            end
        end

        function deliver_pattern(self)
            
    end
end
