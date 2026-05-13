function [firstIdx, nFrames] = generatePatternBMPs(spots, dmd_config, patternType, tickMs)
% generatePatternBMPs  Render a multi-spot pattern as a sequence of BMP frames.
%
%   [firstIdx, nFrames] = generatePatternBMPs(spots, dmd_config, patternType)
%   [firstIdx, nFrames] = generatePatternBMPs(spots, dmd_config, patternType, tickMs)
%
%   spots       - struct array with fields: x, y (DMD pixel coords), onset_ms, dur_ms
%   dmd_config  - luminose.dmd struct (spotSide, projectedDMDlength, patternsFolder)
%   patternType - 'cue', 'Left', or 'Right'
%   tickMs      - frame duration in ms (default 10)
%
%   Saves BMP frames to dmd_config.patternsFolder named:
%     designed_{patternType}_{yyyymmdd_HHMMSS}_f001.bmp, ..., f{N}.bmp
%   and a sidecar _meta.mat for later re-loading in the designer.
%
%   Returns firstIdx (1-based index into sorted *.bmp list of first frame)
%   and nFrames (total number of frames written).

    if nargin < 4 || isempty(tickMs)
        tickMs = 10;
    end

    patternsFolder = char(dmd_config.patternsFolder);
    if ~exist(patternsFolder, 'dir')
        mkdir(patternsFolder);
    end
    H = 768;
    W = 1024;

    totalDur = max([spots.onset_ms] + [spots.dur_ms]);
    nFrames  = ceil(totalDur / tickMs);

    r_px = round((dmd_config.spotSide / dmd_config.projectedDMDlength) * W / 2);
    r_px = max(r_px, 1);

    % Square mask (2r+1 × 2r+1, all true)
    diskMask = true(2*r_px+1, 2*r_px+1);
    maskH = size(diskMask, 1);
    maskW = size(diskMask, 2);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>
    prefix    = sprintf('designed_%s_%s', patternType, timestamp);

    for k = 0 : nFrames-1
        t      = k * tickMs;
        frame  = false(H, W);
        active = find(([spots.onset_ms] <= t) & (([spots.onset_ms] + [spots.dur_ms]) > t));
        for iS = active
            cx = round(spots(iS).x);
            cy = round(spots(iS).y);
            r1 = cy - r_px;  r2 = cy + r_px;
            c1 = cx - r_px;  c2 = cx + r_px;
            % Clip to frame bounds
            mr1 = 1; mr2 = maskH; mc1 = 1; mc2 = maskW;
            if r1 < 1,  mr1 = mr1 + (1 - r1);  r1 = 1;  end
            if r2 > H,  mr2 = mr2 - (r2 - H);  r2 = H;  end
            if c1 < 1,  mc1 = mc1 + (1 - c1);  c1 = 1;  end
            if c2 > W,  mc2 = mc2 - (c2 - W);  c2 = W;  end
            if r1 <= r2 && c1 <= c2
                frame(r1:r2, c1:c2) = frame(r1:r2, c1:c2) | diskMask(mr1:mr2, mc1:mc2);
            end
        end
        fname = fullfile(patternsFolder, sprintf('%s_f%03d.bmp', prefix, k+1));
        imwrite(uint8(frame) * 255, fname);
    end

    % Save sidecar metadata for reloading in PatternDesignerGUI
    metaFile = fullfile(patternsFolder, sprintf('%s_meta.mat', prefix));
    save(metaFile, 'spots', 'tickMs', 'timestamp', 'prefix');

    % Find 1-based index of first saved frame in the sorted BMP list
    files = dir(fullfile(patternsFolder, '*.bmp'));
    firstName = sprintf('%s_f001.bmp', prefix);
    firstIdx  = find(strcmp({files.name}, firstName), 1);
    if isempty(firstIdx)
        error('generatePatternBMPs: could not find %s in %s', firstName, patternsFolder);
    end
end
