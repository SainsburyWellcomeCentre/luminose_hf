function seq = buildDMDSlaveSequence(dmd, patternsFolder, imgIdx, illuminateTime_us)
% buildDMDSlaveSequence  Load one BMP frame and return a slave-mode sequence.
%
%   seq = buildDMDSlaveSequence(dmd, patternsFolder, imgIdx, illuminateTime_us)
%
%   dmd               - DMDController.DMD object (must be connected)
%   patternsFolder    - path to folder containing BMP pattern files
%   imgIdx            - 1-based index into the sorted BMP file list
%   illuminateTime_us - mirror-on time per trigger (microseconds)
%
%   In slave mode each external trigger pulse advances one frame.
%   This function loads a single frame so one BNC trigger = one complete stimulus.
%   Call dmd.device.projStart(seq) after to arm the DMD; it will then
%   wait for the hardware trigger on the ALP trigger input pin.

files = dir(fullfile(char(patternsFolder), '*.bmp'));
H = dmd.device.height;
W = dmd.device.width;

if imgIdx <= numel(files)
    img = imread(fullfile(char(patternsFolder), files(imgIdx).name));
    if ndims(img) == 3
        img = rgb2gray(img);
    end
    img = img > 127;
else
    warning('buildDMDSlaveSequence: index %d exceeds %d files in %s', ...
        imgIdx, numel(files), char(patternsFolder));
    img = false(H, W);
end

seq = dmd.device.allocSequence(1, 1);
seq.put(0, 1, img);
seq.setBinaryMode(true);
illuTime = round(illuminateTime_us);
seq.timing(illuTime, illuTime, 0, 0, 0);
seq.setRepeat(1);
end
