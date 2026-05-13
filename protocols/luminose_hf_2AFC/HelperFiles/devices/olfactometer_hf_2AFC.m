function olfactometer_hf_2AFC(code)

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

        case 2  % Left
            if length(S.GUI.probs_Left) > 1
                idx = randsample(size(S.GUI.valves_Left, 1), 1, true, S.GUI.probs_Left);
                odour_valves = S.GUI.valves_Left(idx, :);
                duty_cycles = S.GUI.dutyCycles_Left(idx, :);
            else
                odour_valves = S.GUI.valves_Left;
                duty_cycles = S.GUI.dutyCycles_Left;
            end
           
        case 3  % Right
            if length(S.GUI.probs_Right) > 1
                idx = randsample(size(S.GUI.valves_Right, 1), 1, true, S.GUI.probs_Right);
                odour_valves = S.GUI.valves_Right(idx, :);
                duty_cycles = S.GUI.dutyCycles_Right(idx, :);
            else
                odour_valves = S.GUI.valves_Right;
                duty_cycles = S.GUI.dutyCycles_Right;
            end
            
        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end
    
    if duty_cycles == 0
        duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    end
    % Run olfactometer sequence
    olfModel.play_valve_sequence(odour_valves, duty_cycles);

    types = {'cue', 'Left', 'Right'};
    S.GUI.delivered_odours.(types{code}) = odour_valves;
    S.GUI.delivered_dutyCycles.(types{code}) = duty_cycles;
end
