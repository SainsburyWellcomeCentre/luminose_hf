function olfactometer_hf_MTS(code)

    global S luminose olfModel BpodSystem

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

        case 2  % Template — row index drawn ahead of time in PrepareStateMachine
            % (buildTemplateAction), so the same row gets replayed on Match
            % trials when this code fires a second time during Delay.
            idx = BpodSystem.PluginObjects.SelectedOdourRow.Template;
            odour_valves = S.GUI.valves_Template(idx, :);
            duty_cycles = S.GUI.dutyCycles_Template(idx, :);

        case 3  % Sample — row index drawn in PrepareStateMachine
            % (buildSampleAction) from the Sample rows checked for the
            % trial's template row.
            idx = BpodSystem.PluginObjects.SelectedOdourRow.Sample;
            odour_valves = S.GUI.valves_Sample(idx, :);
            duty_cycles = S.GUI.dutyCycles_Sample(idx, :);

        otherwise
            disp(['Unknown SoftCode received: ' num2str(code)]);
            return;
    end

    if duty_cycles == 0
        duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    end
    % Run olfactometer sequence
    olfModel.play_valve_sequence(odour_valves, duty_cycles);

    types = {'cue', 'Template', 'Sample'};
    S.GUI.delivered_odours.(types{code}) = odour_valves;
    S.GUI.delivered_dutyCycles.(types{code}) = duty_cycles;
end
