% luminose_init.m — Luminose experiment setup

% Add folders and save path
folders = LuminoseConstants.addFolders();

% Load experiment configuration structs
bpod = LuminoseConstants.addBpod();
olfactometer = LuminoseConstants.addOlfactometer();
dmd = LuminoseConstants.addDMD();
bonsai = LuminoseConstants.addBonsai();

% Display confirmation
disp('Luminose experiment initialized:');
disp("=====  Folders =====");
disp(folders);
disp("=====  Bpod =====");
disp(bpod);
disp("=====  Olfactometer =====");
disp(olfactometer);
disp("=====  DMD =====");
disp(dmd);
disp("=====  Bonsai =====");
disp(bonsai);

% Run Olfactometer
olfModel = OlfactometerModel(olfactometer);
odour_valves = [3, 4, 5, 6];           % example valve numbers
duty_cycles = [0.05, 0.05, 0.05, 0.05];        % example duty cycles (50%)
label = "A";                     % single character label (optional)

valve_pattern = olfModel.generate_valve_pattern(odour_valves, duty_cycles, label);
olfModel.play_valve_sequence(odour_valves, duty_cycles, label);
