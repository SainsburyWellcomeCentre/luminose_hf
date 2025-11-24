luminose = LuminoseConstants();
unique_valves = [3:8, 11:16];
valves = reshape(repmat(unique_valves, 1, 1000), 1, []);
for i = 1:length(valves)
    valve = valves(i);
    olfModel = OlfactometerModel(luminose.olfactometer);
    olfModel.generate_valve_pattern(valve, [1], 'test');
    olfModel.play_valve_sequence(valve, [1], 'test');
end