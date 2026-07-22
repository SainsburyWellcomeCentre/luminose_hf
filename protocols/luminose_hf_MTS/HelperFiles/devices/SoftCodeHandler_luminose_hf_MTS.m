%% Softcode Handler
function SoftCodeHandler_luminose_hf_MTS(code)
    global S luminose BpodSystem
    if code <= 7
        % Resolve which valves/duty-cycles to deliver here, in the client
        % process, where S/BpodSystem are actually valid — a parfeval worker
        % has its own separate global workspace and cannot see them. Only
        % the resolved data (plus the olfactometer constants) is handed to
        % the worker, which does nothing but the blocking hardware call.
        [odour_valves, duty_cycles] = resolveOdourDelivery_hf_MTS(code, S, BpodSystem);
        if ~isempty(odour_valves)
            types = {'cue', 'Template', 'Sample'};
            S.GUI.delivered_odours.(types{code}) = odour_valves;
            S.GUI.delivered_dutyCycles.(types{code}) = duty_cycles;
            parfeval(@olfactometer_hf_MTS, 0, odour_valves, duty_cycles, luminose.olfactometer);
        end
    else
        dmd_hf_MTS(code);  % synchronous — libisloaded fails on thread workers
    end
end

function [odour_valves, duty_cycles] = resolveOdourDelivery_hf_MTS(code, S, BpodSystem)
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
            odour_valves = [];
            duty_cycles = [];
    end
end
