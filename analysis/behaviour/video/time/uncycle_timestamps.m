function unwrapped = uncycle_timestamps(time)
    % Unwrap converted seconds from bonsai spinnaker timestamps
    cycles = [false, diff(time) < 0];
    cycleindex = cumsum(cycles);
    unwrapped = time + cycleindex * 128;
end