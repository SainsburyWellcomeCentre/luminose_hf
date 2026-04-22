function olfactometer_hf_playground(code)

    global S luminose olfModel 
    
    if isempty(olfModel)
        olfModel = OlfactometerModel(luminose.olfactometer, true);
    end
    
    % Map softcode to GUI field suffix
    suffixes = {'cue', 'Left', 'Right'};
    if code > length(suffixes)
        disp(['Unknown SoftCode received: ' num2str(code)]);
        return;
    end
    suffix = suffixes{code};
    
    valvesField = ['valves_' suffix];
    dutyField = ['dutyCycles_' suffix];
    probsField = ['probs_' suffix];
    
    if ~isfield(S.GUI, valvesField)
        disp(['Field ' valvesField ' not found in S.GUI']);
        return;
    end
    
    odour_valves = S.GUI.(valvesField);
    
    % Handle random selection if probabilities are provided and there's more than one set
    if isfield(S.GUI, probsField) && length(S.GUI.(probsField)) > 1
        % Row-wise selection from matrix (if valvesField is a matrix)
        idx = randsample(size(odour_valves, 1), 1, true, S.GUI.(probsField));
        odour_valves = odour_valves(idx, :);
        if isfield(S.GUI, dutyField)
            duty_cycles = S.GUI.(dutyField)(idx, :);
        else
            duty_cycles = zeros(size(odour_valves));
        end
    else
        % Use as a single sequence (first row)
        odour_valves = odour_valves(1, :); 
        if isfield(S.GUI, dutyField)
            duty_cycles = S.GUI.(dutyField)(1, :);
        else
            duty_cycles = zeros(size(odour_valves));
        end
    end
    
    % Strip padding zeros (added by PadAndAppend in GUI sync)
    validIdx = odour_valves > 0;
    odour_valves = odour_valves(validIdx);
    duty_cycles = duty_cycles(validIdx);
    
    if isempty(odour_valves)
        disp('No odour valves selected for delivery.');
        return;
    end

    % If duty cycles are 0 or empty, look up from table based on chemicals
    if isempty(duty_cycles) || all(duty_cycles == 0)
        duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    end
    
    % Ensure duty_cycles and odour_valves are the same length
    if length(duty_cycles) < length(odour_valves)
        if isempty(duty_cycles)
            duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
        else
            duty_cycles(end+1:length(odour_valves)) = duty_cycles(end);
        end
    elseif length(duty_cycles) > length(odour_valves)
        duty_cycles = duty_cycles(1:length(odour_valves));
    end

    disp(['Delivering odour sequence for ' suffix ':']);
    disp(['Valves: ' mat2str(odour_valves)]);
    disp(['Duty cycles: ' mat2str(duty_cycles)]);

    % Run olfactometer sequence
    olfModel.play_valve_sequence(odour_valves, duty_cycles);

    % Log delivered odours for data tracking
    S.GUI.delivered_odours.(suffix) = odour_valves;
    S.GUI.delivered_dutyCycles.(suffix) = duty_cycles;
end
