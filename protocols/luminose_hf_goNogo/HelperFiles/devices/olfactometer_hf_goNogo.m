function olfactometer_hf_goNogo(code)

    global S luminose olfModel 
    
    if isempty(olfModel)
        olfModel = OlfactometerModel(luminose.olfactometer, true);
    end
    
    % Define label and other parameters by SoftCode value
    switch code
        case 1  % Cue
            if length(S.GUI.probs_cue) > 1
                idx = randsample(size(S.GUI.valves_cue, 1), 1, true, S.GUI.probs_cue);
                odour_valves = S.GUI.valves_cue(idx, :);
                duty_cycles = S.GUI.dutyCycles_cue(idx, :);
            else
                odour_valves = S.GUI.valves_cue;
                duty_cycles = S.GUI.dutyCycles_cue;
            end

        case 2  % CS+
            if length(S.GUI.probs_CSplus) > 1
                idx = randsample(size(S.GUI.valves_CSplus, 1), 1, true, S.GUI.probs_CSplus);
                odour_valves = S.GUI.valves_CSplus(idx, :);
                duty_cycles = S.GUI.dutyCycles_CSplus(idx, :);
            else
                odour_valves = S.GUI.valves_CSplus;
                duty_cycles = S.GUI.dutyCycles_CSplus;
            end
           
        case 3  % CS-
            v = [11, 16]; p = [0.5, 0.5]; dc = [1, 1];
            idx = randsample(1:numel(v), 1, true, p);
            odour_valves = v(idx);
            duty_cycles = dc(idx);
            
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end
    
    if duty_cycles == 0
        duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    end
    disp(odour_valves);
    % Run olfactometer sequence
    olfModel.play_valve_sequence(odour_valves, duty_cycles);

    S.GUI.delivered_odours = odour_valves;
    S.GUI.delivered_dutyCycles = duty_cycles;
end
