function seconds = convert_timestamps(time)
% Convert camera timestamps from bonsai spinnaker to seconds
    cycle1 = bitand(bitshift(time, -12), hex2dec('1FFF'));
    cycle2 = bitand(bitshift(time, -25), hex2dec('7F'));
    seconds = double(cycle2) + double(cycle1) / 8000;
end