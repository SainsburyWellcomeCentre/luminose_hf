function olfactometer_2AFC(code)
    persistent olfModel
    global S luminose  % olfactometer is a global object set in the protocol
    
    if isempty(olfModel)
        olfModel = OlfactometerModel(luminose.olfactometer);
    end
    
    %Define label and other parameters by SoftCode value
    switch code
        case 1  % Trial Type CS+
            odour_valves = S.GUI.odourCSplus_valves;
            duty_cycles = S.GUI.odourCSplus_dutyCycles;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.odourCSplus_label;
        case 2  % Trial Type CS-
            odour_valves = S.GUI.odourCSminus_valves;
            duty_cycles = S.GUI.odourCSminus_dutyCycles;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.odourCSminus_label;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
