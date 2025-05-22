function odours_olfactometer_goNogo(code)
    persistent olfModel
    global olfactometer  % olfactometer is a global object set in the protocol

    %Define label and other parameters by SoftCode value
    switch code
        case 1  % Trial Type CS+
            odour_valves = olfactometer.odourCSplus_valves;
            duty_cycles = olfactometer.odourCSplus_dutyCycles;
            label = olfactometer.odourCSplus_label;
        case 2  % Trial Type CS-
            odour_valves = olfactometer.odourCSminus_valves;
            duty_cycles = olfactometer.odourCSminus_dutyCycles;
            label = olfactometer.odourCSminus_label;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
