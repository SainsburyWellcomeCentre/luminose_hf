function DisplayPNGImage()
    % DisplayPNGImage  Displays the project logo in the specified GUI axes
    global BpodSystem
    ax = BpodSystem.GUIHandles.ParameterGUI.ImageAxes;
    
    % Find repository root path
    guiPath = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(guiPath);
    imagePath = fullfile(repoRoot, 'logo.png');

    if exist(imagePath, 'file')
        img = imread(imagePath);
        imshow(img, 'Parent', ax);
        axis(ax, 'off');
    else
        cla(ax);
        text(0.5, 0.5, {'Image not found:', imagePath, '', 'Please place your PNG file in the correct location'}, ...
            'Parent', ax, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 10, ...
            'Color', [0.8 0.2 0.2], ...
            'Interpreter', 'none');
        axis(ax, 'off');
        ax.XLim = [0 1];
        ax.YLim = [0 1];
    end
end
