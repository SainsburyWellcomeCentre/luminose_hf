olfactometer = LuminoseConstants.addOlfactometer();
unique_valves = [3:8, 11:16];
valves = reshape(repmat(unique_valves, 3, 1000), 1, []);
for i = 1:length(valves)
    valve = valves(i);
    olfModel = OlfactometerModel(olfactometer);
    olfModel.generate_valve_pattern(valve, [0.5], 'a');
    olfModel.play_valve_sequence(valve, [0.5], 'a');
end