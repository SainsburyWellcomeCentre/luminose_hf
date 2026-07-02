classdef LaserModel < handle
    % LaserModel  Serial control for Coherent OBIS laser via SCPI commands.
    %
    %   laser = LaserModel(luminose.laser)
    %
    %   Connects to the OBIS remote on the configured COM port and sets
    %   USB/CWP control mode. Call disconnect() when done.

    properties
        port        string
        baudRate    double
        maxPower_mW double
        sp                  % serialport handle
    end

    methods
        function self = LaserModel(constants)
            self.port        = constants.port;
            self.baudRate    = constants.baudRate;
            self.maxPower_mW = constants.maxPower_mW;

            self.sp = serialport(char(self.port), self.baudRate);
            configureTerminator(self.sp, "CR/LF");
            self.sp.Timeout = 5;

            % Switch to USB (CWP) control mode
            writeline(self.sp, "SOURce:AM:INTernal CWP");
            pause(0.1);
        end

        function setPower(self, mW)
            % setPower  Set laser output power.
            %   laser.setPower(mW)  — value in milliwatts
            if mW < 0 || mW > self.maxPower_mW
                error('LaserModel:OutOfRange', ...
                    'Power %.3f mW is outside [0, %.3f] mW range.', mW, self.maxPower_mW);
            end
            watts = mW / 1000;
            writeline(self.sp, sprintf('SOURce:POWer:LEVel:IMMediate:AMPLitude %.6f', watts));
        end

        function setEnabled(self, tf)
            % setEnabled  Enable or disable laser emission.
            %   laser.setEnabled(true)   — emission on
            %   laser.setEnabled(false)  — emission off
            if tf
                writeline(self.sp, "SOURce:AM:STATe ON");
            else
                writeline(self.sp, "SOURce:AM:STATe OFF");
            end
        end

        function mW = getPower_mW(self)
            % getPower_mW  Query actual output power in milliwatts.
            writeline(self.sp, "SOURce:POWer:LEVel?");
            resp = readline(self.sp);
            mW = str2double(strtrim(resp)) * 1000;
        end

        function disconnect(self)
            % disconnect  Disable emission and close serial port.
            try, self.setEnabled(false); catch, end
            if ~isempty(self.sp) && isvalid(self.sp)
                delete(self.sp);
            end
            self.sp = [];
        end
    end
end
