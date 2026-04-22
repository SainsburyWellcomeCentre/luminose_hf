function img = generateBottleImage(width, height, color, bgColor)
    % generateBottleImage  Creates an RGB image of a bottle shape
    % width, height: dimensions in pixels
    % color: [r g b] for the bottle
    % bgColor: [r g b] for the surrounding area (to simulate transparency)

    if nargin < 4, bgColor = [1 1 1]; end
    
    % Initialize with background color
    img = zeros(height, width, 3);
    for c = 1:3
        img(:,:,c) = bgColor(c);
    end
    
    % Define bottle proportions
    % Body: lower part
    bodyW = round(width * 0.7);
    bodyH = round(height * 0.6);
    bodyX = round((width - bodyW)/2);
    bodyY = round(height * 0.1); % Bottom margin
    
    % Neck: upper part
    neckW = round(width * 0.25);
    neckH = round(height * 0.25);
    neckX = round((width - neckW)/2);
    neckY = bodyY + bodyH;
    
    % Cap: very top
    capW = round(neckW * 1.2);
    capH = round(height * 0.05);
    capX = round((width - capW)/2);
    capY = neckY + neckH;
    
    % Fill bottle parts
    for c = 1:3
        % Body (rounded corners approximation)
        img(bodyY:bodyY+bodyH, bodyX:bodyX+bodyW, c) = color(c);
        % Neck
        img(neckY:neckY+neckH, neckX:neckX+neckW, c) = color(c);
        % Cap
        if capY+capH <= height
            img(capY:capY+capH, capX:capX+capW, c) = color(c) * 0.8; % Darker cap
        end
    end
    
    % Add a simple "shine" highlight
    shineX = bodyX + 2;
    shineW = 2;
    if shineX + shineW < width
        for c = 1:3
            highlight = color(c) + 0.2;
            if highlight > 1, highlight = 1; end
            img(bodyY+2:bodyY+bodyH-2, shineX:shineX+shineW, c) = highlight;
        end
    end
    
    % Flip vertically because uicontrol CData is often interpreted that way 
    % or depends on the coordinate system. Actually imshow/CData usually matches.
    img = flipud(img); 
end
