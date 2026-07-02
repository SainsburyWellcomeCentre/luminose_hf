classdef ZaberModel < handle
    % ZaberModel  Zaber stage control via Zaber Motion Library (ASCII protocol).
    %
    %   zaber = ZaberModel(luminose.zaber)
    %
    %   Requires the Zaber Motion Library for MATLAB to be on the MATLAB path.
    %   Install from: https://software.zaber.com/motion-library/docs/guides/install/matlab
    %
    %   All positions are in micrometres. Movements block until complete.
    %   Call disconnect() when done.

    properties
        port        string
        axisIndex   double
        conn                % zaber.motion.ascii.Connection
        axis                % axis handle
    end

    methods
        function self = ZaberModel(constants)
            self.port      = constants.port;
            self.axisIndex = constants.axisIndex;

            import zaber.motion.ascii.Connection
            self.conn = Connection.openSerialPort(char(self.port));

            try
                devices = self.conn.detectDevices();
                if numel(devices) == 0
                    error('ZaberModel:NoDevice', 'No Zaber devices found on %s.', self.port);
                end
                device = devices(1);
                self.axis = device.getAxis(self.axisIndex);
            catch e
                try; self.conn.close(); catch; end
                self.conn = [];
                rethrow(e);
            end
        end

        function moveAbsolute(self, pos_um)
            % moveAbsolute  Move to absolute Z position in micrometres (blocking).
            import zaber.motion.Units
            self.axis.moveAbsolute(pos_um, Units.LengthMicrometres);
        end

        function moveRelative(self, delta_um)
            % moveRelative  Move relative to current position in micrometres (blocking).
            import zaber.motion.Units
            self.axis.moveRelative(delta_um, Units.LengthMicrometres);
        end

        function pos_um = getPosition_um(self)
            % getPosition_um  Return current Z position in micrometres.
            import zaber.motion.Units
            pos_um = self.axis.getPosition(Units.LengthMicrometres);
        end

        function disconnect(self)
            % disconnect  Close connection to Zaber controller.
            if ~isempty(self.conn)
                self.conn.close();
            end
            self.conn = [];
            self.axis = [];
        end
    end
end
