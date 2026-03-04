luminose = LuminoseConstants();
unique_valves = [3:8, 11:16];
valves = reshape(repmat(unique_valves, 1, 1000), 1, []);
triggered = false;
for i = 1:length(valves)
    valve = valves(i);
    olfModel = OlfactometerModel(luminose.olfactometer, triggered);
    olfModel.play_valve_sequence(valve, [1]);
end
