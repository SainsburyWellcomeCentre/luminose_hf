function FrameData = load_frame_data(videoFrameDataPath)
%% parse binary file containing frame data from bonsai
fid = fopen(videoFrameDataPath, 'rb');
if fid == -1
    error('cannot open frame data');
end
parsedData = fread(fid, inf, 'float64');
fclose(fid);

if mod(length(parsedData), 4) ~= 0
    error('Number of elements is not divisible by 4.');
end

videoFrameData = reshape(parsedData, 4, []);

%% timestamps: UTC ticks from BehaviorPC
timestamps = (videoFrameData(1, :) - videoFrameData(1, 1)) / 10000000;

%% embedded timestamps: camera timestamps
embeddedTimes = uncycle_timestamps(convert_timestamps(videoFrameData(2, :)));
embeddedTimes = embeddedTimes - embeddedTimes(1);

%% GPIO states of 4 pins
% The raw binary file contains uint32 values (saved as doubles) where the first 4 bits
% represent the state of each of the 4 GPIO pins. The array is expanded to an n x 4 array by
% shifting each bit to the end and checking whether it is 0 (low state) or 1 (high state).

gpioCol = videoFrameData(4, :);
nRows = length(gpioCol);
GPIOinStates = false(4, nRows);
% Extract GPIO bits from bits 31 to 28
for i = 1:4
    shiftAmount = 32 - i;  % shift by 31, 30, 29, 28
    GPIOinStates(i, :) = bitand(bitshift(gpioCol, -shiftAmount), 1) == 1;
end

%% Frame counter
FrameCounter = int32(videoFrameData(4, :) - videoFrameData(4, 1));

%% Save data in a structure
FrameData = struct;
FrameData.timestamps = timestamps;
FrameData.embeddedTimes = embeddedTimes;
FrameData.GPIOinStates = GPIOinStates;
FrameData.FrameCounter = FrameCounter;
