classdef CameraModel < handle
    % CameraModel  Image Acquisition Toolbox wrapper for Hamamatsu ORCA camera.
    %
    %   cam = CameraModel(luminose.camera)
    %
    %   Connects via the 'hamamatsu' imaq adaptor. Call cam.capture() to get
    %   an averaged uint16 frame. Call disconnect() when done.
    %
    %   NOTE: Run imaqhwinfo('hamamatsu') once to confirm adaptor is installed
    %   and check the exact ExposureTime property name on cam.vid.Source.

    properties
        adaptorName     string
        adaptorDllPath  string
        deviceID        double
        exposureTime_ms double
        nAverageFrames  double
        vid                     % videoinput handle
    end

    methods
        function self = CameraModel(constants)
            self.adaptorName     = constants.adaptorName;
            self.adaptorDllPath  = constants.adaptorDllPath;
            self.deviceID        = constants.deviceID;
            self.exposureTime_ms = constants.exposureTime_ms;
            self.nAverageFrames  = constants.nAverageFrames;

            % Register third-party adaptor DLL and reset imaq environment
            imaqregister(char(self.adaptorDllPath));
            imaqreset;

            self.vid = videoinput(char(self.adaptorName), self.deviceID);
            self.vid.FramesPerTrigger = 1;
            self.vid.TriggerRepeat    = Inf;
            triggerconfig(self.vid, 'immediate');

            self.setExposure(self.exposureTime_ms);
            start(self.vid);
        end

        function frame = capture(self)
            % capture  Acquire nAverageFrames and return their mean as uint16.
            acc = double(getsnapshot(self.vid));
            for k = 2:self.nAverageFrames
                acc = acc + double(getsnapshot(self.vid));
            end
            frame = uint16(acc / self.nAverageFrames);
        end

        function setExposure(self, ms)
            % setExposure  Set camera exposure time in milliseconds.
            %   Tries common Hamamatsu property names; edit if yours differs.
            self.exposureTime_ms = ms;
            src = self.vid.Source;
            if isprop(src, 'ExposureTime')
                src.ExposureTime = ms / 1000;
            elseif isprop(src, 'Exposure')
                src.Exposure = ms / 1000;
            else
                warning('CameraModel:UnknownExposureProp', ...
                    'Could not find exposure property. Check vid.Source properties.');
            end
        end

        function disconnect(self)
            % disconnect  Stop acquisition and release the videoinput object.
            if ~isempty(self.vid) && isvalid(self.vid)
                stop(self.vid);
                delete(self.vid);
            end
            self.vid = [];
        end
    end
end
