luminose = LuminoseConstants();
unique_valves = [3:8, 11:16];
% unique_valves = [14];
valves = reshape(repmat(unique_valves, 3, 100), 1, []);
triggered = true;

olfModel = OlfactometerModel(luminose.olfactometer, triggered);
for i = 1:length(valves)
    valve = valves(i);
    tic
    olfModel.play_valve_sequence(valve, [1]);
    toc
end
