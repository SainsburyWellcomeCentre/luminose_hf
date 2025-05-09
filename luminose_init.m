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

bpod();

