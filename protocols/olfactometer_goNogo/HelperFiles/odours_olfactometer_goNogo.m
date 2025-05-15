function odours_olfactometer_goNogo(code)
    persistent olfModel
    global olfactometer  % olfactometer is a global object set in the protocol

    Define label and other parameters by SoftCode value
    switch code
        case 1  % Trial Type 0 (e.g., label "A")
            % odour_valves = olfactometer.odourAvalves;
            odour_valves = olfactometer.odourAvalves;
            duty_cycles = olfactometer.odourAdutyCycles;
            label = olfactometer.odourAlabel;
        case 2  % Trial Type 1 (e.g., label "B")
            odour_valves = olfactometer.odourBvalves;
            duty_cycles = olfactometer.odourBdutyCycles;
            label = olfactometer.odourBlabel;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
