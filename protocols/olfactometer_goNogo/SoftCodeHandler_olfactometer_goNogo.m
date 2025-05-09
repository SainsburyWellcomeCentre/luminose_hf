function SoftCodeHandler(code)
    persistent olfModel

    if isempty(olfModel)
        % Initialize olfactometer model only once
        global olfactometer  % Assuming 'olfactometer' is a global object you've set elsewhere
        olfModel = OlfactometerModel(olfactometer);
    end

    % Define label and other parameters by SoftCode value
    switch code
        case 1  % Trial Type 0 (e.g., label "A")
            odour_valves = [3, 4, 5, 6];
            duty_cycles = [0.05, 0.05, 0.05, 0.05];
            label = 'A';
        case 2  % Trial Type 1 (e.g., label "B")
            odour_valves = [3, 4, 5, 6];
            duty_cycles = [0.05, 0.05, 0.05, 0.05];
            label = 'B';
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
