function olfactometer_hf_goNogo(code)

    global S luminose olfModel 
    
    if isempty(olfModel)
        olfModel = OlfactometerModel(luminose.olfactometer);
    end
    
    % %Define label and other parameters by SoftCode value
    % switch code
    %     case 1  % Cue
    %         odour_valves = S.GUI.valves_cue;
    %         duty_cycles = S.GUI.dutyCycles_cue;
    %         if duty_cycles == 0
    %             duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    %         end
    %         label = S.GUI.label_cue;
    %     case 2  % CS+
    %         odour_valves = S.GUI.current_valves_CSplus;
    %         duty_cycles = S.GUI.current_dutyCycles_CSplus;
    %         if duty_cycles == 0
    %             duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    %         end
    %         label = S.GUI.label_CSplus;
    %     case 3  % CS-
    %         odour_valves = S.GUI.current_valves_CSminus;
    %         duty_cycles = S.GUI.current_dutyCycles_CSminus;
    %         if duty_cycles == 0
    %             duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    %         end
    %         label = S.GUI.label_CSminus;
    %     otherwise
    %         disp(['Unknown SoftCode received: ' num2str(code)]);
    %         return;
    % end
    switch code
        case 1
            odour_valves = S.GUI.valves_cue;
            duty_cycles = S.GUI.dutyCycles_cue;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_cue;
        case 2
            odour_valves = S.GUI.valves_CSplus;
            duty_cycles = S.GUI.dutyCycles_CSplus;
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_CSplus;
        case 3
            odour_valves = [11];
            duty_cycles = [1];
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_CSminus;
        case 4
            odour_valves = [12];
            duty_cycles = [1];
            if duty_cycles == 0
                duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
            end
            label = S.GUI.label_CSminus;
    end
    % Run olfactometer sequence
    olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
    olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
end
