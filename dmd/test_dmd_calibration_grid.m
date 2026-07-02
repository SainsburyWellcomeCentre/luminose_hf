% test_dmd_calibration_grid  Display a 3x3 calibration line grid on the DMD.
%
%   Three horizontal and three 1-pixel-wide vertical lines, centred in
%   the image. Consecutive lines are gap1 pixels apart, then gap2 pixels
%   apart.
%
%   Adjust gap1 and gap2 below to change the pattern spacing.

gap1 = 2;    % pixel spacing between the first and second line
gap2 = 3;    % pixel spacing between the second and third line

%% Connect
dmd = DMDController.DMD();
dmd.connect(0);

info = dmd.getInfo();
W = double(info.width);    % 2560
H = double(info.height);   % 1600
fprintf('DMD resolution: %d x %d\n', W, H);

%% Generate and display
img = generateCalibrationGrid(H, W, gap1, gap2);

% Count lines for reference
nHoriz = sum(any(img, 2));   % rows that contain at least one lit pixel
nVert  = sum(any(img, 1));   % cols
fprintf('Pattern: %d horizontal lines, %d vertical lines\n', nHoriz, nVert);

dmd.displayFrame(img);
fprintf('Displaying calibration grid. Press Enter to stop.\n');
input('');

%% Cleanup
dmd.halt();
dmd.disconnect();
