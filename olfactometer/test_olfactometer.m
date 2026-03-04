luminose = LuminoseConstants();
% unique_valves = [3:8, 11:16];
unique_valves = 3;
valves = reshape(repmat(unique_valves, 1, 1), 1, []);
triggered = true;
for i = 1:length(valves)
    valve = valves(i);
    tic
    olfModel = OlfactometerModel(luminose.olfactometer, triggered);
    olfModel.play_valve_sequence(valve, [1]);
    toc
end
