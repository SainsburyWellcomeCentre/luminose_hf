%% 
% calibrate_power  Record peak camera intensity for each laser power setting.
%
%   Sweeps through all rows in dmd/power_calibration.csv, captures a frame
%   at each power step, records the peak pixel value, and writes results back
%   into the intensity_at_camera column.
%
%   Warnings are printed if any frame is saturated (>95% of 65535).
%   A power-vs-intensity plot is shown on completion.

luminose = LuminoseConstants();
laser    = LaserModel(luminose.laser);
cam      = CameraModel(luminose.camera);

dmd = DMDController.DMD();
dmd.connect(0);
info = dmd.getInfo();
dmd.displayFrame(ones(double(info.height), double(info.width), 'uint8') * 255);
fprintf('DMD: all-white pattern displayed (%dx%d)\n', info.width, info.height);
pause(0.5);

calCsvPath = fullfile(char(luminose.f.luminose_hf), 'dmd', 'power_calibration.csv');
T = readtable(calCsvPath);
nSteps = height(T);

fprintf('Power calibration: %d steps\n', nSteps);
fprintf('CSV: %s\n\n', calCsvPath);

intensities  = zeros(nSteps, 1);
saturated    = false(nSteps, 1);
satThresh    = 0.95 * 65535;

laser.setEnabled(true);

for i = 1:nSteps
    laser.setPower(T.power_setting_mW(i));
    pause(0.3);   % allow power to stabilise

    frame = cam.capture();
    peak  = double(max(frame(:)));
    intensities(i)  = peak;
    saturated(i)    = peak > satThresh;

    flag = '';
    if saturated(i), flag = '  *** SATURATED ***'; end
    fprintf('  [%2d/%d] %6.1f mW  peak = %5d%s\n', ...
        i, nSteps, T.power_setting_mW(i), peak, flag);
end

laser.setEnabled(false);
dmd.halt();
dmd.disconnect();
laser.disconnect();
cam.disconnect();

%% Write results
T.intensity_at_camera = intensities;
writetable(T, calCsvPath);
fprintf('\nUpdated: %s\n', calCsvPath);

if any(saturated)
    fprintf('WARNING: %d step(s) saturated — reduce exposure or laser power.\n', sum(saturated));
end

%% Plot
outDir  = fullfile(char(luminose.f.luminoseData), 'calibration');
if ~exist(outDir, 'dir'), mkdir(outDir); end
stamp   = datestr(now, 'yyyymmdd_HHMMSS');
pngPath = fullfile(outDir, ['power_' stamp '.png']);
svgPath = fullfile(outDir, ['power_' stamp '.svg']);

fig = figure('Name', 'Power Calibration', 'NumberTitle', 'off', 'Position', [200 200 900 400]);

subplot(1, 2, 1);
validSample = T.power_at_sample_mW > 0;
plot(T.power_setting_mW(validSample), T.power_at_sample_mW(validSample), 'w.-', 'MarkerSize', 10, 'LineWidth', 1);
xlabel('Laser power setting (mW)'); ylabel('Power at sample (mW)');
title('Laser power vs power at sample');
grid on;

subplot(1, 2, 2);
validMask = T.power_at_sample_mW > 0 & intensities > 0 & ~saturated;
plot(T.power_at_sample_mW(validMask), intensities(validMask), 'w.-', 'MarkerSize', 10, 'LineWidth', 1);
hold on;
if any(saturated & validMask)
    plot(T.power_at_sample_mW(saturated & validMask), intensities(saturated & validMask), 'r.', 'MarkerSize', 14);
end
xlabel('Power at sample (mW)'); ylabel('Peak intensity (counts)');
title('Power at sample vs camera intensity');
grid on;

matPath = fullfile(outDir, ['power_' stamp '.mat']);

results.power_setting_mW   = T.power_setting_mW;
results.power_at_sample_mW = T.power_at_sample_mW;
results.intensity_at_camera = intensities;
results.saturated           = saturated;
results.timestamp           = stamp;
save(matPath, 'results');

exportgraphics(fig, pngPath, 'Resolution', 150);
print(fig, svgPath, '-dsvg');
fprintf('Saved:\n  MAT: %s\n  PNG: %s\n  SVG: %s\n', matPath, pngPath, svgPath);
