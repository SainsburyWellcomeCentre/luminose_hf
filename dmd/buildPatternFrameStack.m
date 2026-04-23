function frameStack = buildPatternFrameStack(spots, r_px, tickMs)
% buildPatternFrameStack  Render spot definitions into a logical frame stack.
%
%   frameStack = buildPatternFrameStack(spots, r_px, tickMs)
%
%   spots    - struct array: x, y (DMD pixels), onset_ms, dur_ms
%              isFixed is ignored here; caller randomises random spots first.
%   r_px     - spot half-width in pixels (square side = 2*r_px+1)
%   tickMs   - frame duration in ms
%
%   Returns logical(1600, 2560, nFrames).

    H = 1600;
    W = 2560;

    totalDur   = max([spots.onset_ms] + [spots.dur_ms]);
    nFrames    = ceil(totalDur / tickMs);
    frameStack = false(H, W, nFrames);

    for k = 0 : nFrames-1
        t      = k * tickMs;
        active = find(([spots.onset_ms] <= t) & (([spots.onset_ms] + [spots.dur_ms]) > t));
        for iS = active
            cx = round(spots(iS).x);
            cy = round(spots(iS).y);
            r1 = max(1, cy - r_px);  r2 = min(H, cy + r_px);
            c1 = max(1, cx - r_px);  c2 = min(W, cx + r_px);
            frameStack(r1:r2, c1:c2, k+1) = true;
        end
    end
end
