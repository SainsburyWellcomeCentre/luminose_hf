function olfactometer_hf_2AFC(code)
    global S luminose olfModel
    
    if isempty(olfModel)
        olfModel = OlfactometerModel(luminose.olfactometer);
    end
    
    %Define label and other parameters by SoftCode value
    switch code
        case 1
            odour_valves = S.GUI.valves_cue;
            duty_cycles = S.GUI.dutyCycles_cue;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_cue;
        case 2  % Trial Type Left
            odour_valves = S.GUI.valves_Left;
            duty_cycles = S.GUI.dutyCycles_Left;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_Left;
        case 3  % Trial Type Right
            odour_valves = S.GUI.valves_Right;
            duty_cycles = S.GUI.dutyCycles_Right;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_Right;
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
