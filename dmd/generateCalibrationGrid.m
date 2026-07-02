function img = generateCalibrationGrid(H, W, gap1, gap2)
% generateCalibrationGrid  Three 1-pixel horizontal and three 1-pixel
% vertical lines, centred in the image.
%
%   img = generateCalibrationGrid(H, W)
%   img = generateCalibrationGrid(H, W, gap1, gap2)
%
%   Draws exactly three horizontal lines and three vertical lines.
%   Consecutive lines are gap1 pixels apart, then gap2 pixels apart, so
%   one pair of adjacent lines is gap1 pixels apart and the other pair is
%   gap2 pixels apart.
%
%   Inputs
%     H, W   : image height and width in pixels
%     gap1   : pixel spacing between the first and second line (default 2)
%     gap2   : pixel spacing between the second and third line (default 3)
%
%   Output
%     img    : logical [H x W], true = bright (line) pixel

if nargin < 3, gap1 = 2; end
if nargin < 4, gap2 = 3; end

img  = false(H, W);
cRow = round(H / 2);
cCol = round(W / 2);

rows = cRow + [-gap1, 0, gap2];
cols = cCol + [-gap1, 0, gap2];

rows = rows(rows >= 1 & rows <= H);
cols = cols(cols >= 1 & cols <= W);

img(rows, :) = true;
img(:, cols) = true;
end
