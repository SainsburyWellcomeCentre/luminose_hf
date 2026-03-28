%%
luminose = LuminoseConstants();
plot_distance_matrix(luminose.olfactometer.distanceFile, luminose.olfactometer.odourChemicalsFile);
plot_point_map(luminose.olfactometer.mapFile, luminose.olfactometer.odourChemicalsFile);

%%
function plot_distance_matrix(distance_file, odour_chemicals_file)

    data = readmatrix(distance_file);
    chemTable = readtable(odour_chemicals_file, 'FileType', 'text', 'Delimiter', '\t');

    labels = string(strtrim(chemTable.Name));

    figure('Name', 'Chemical distance matrix (Canberra)', ...
           'Position', [100, 100, 800, 800]);

    imagesc(data);
    colormap(parula);
    cb = colorbar;
    cb.Label.String = 'Canberra distance';

    caxis([min(data(:)), max(data(:))]);

    n = numel(labels);
    xticks(1:n); yticks(1:n);
    xticklabels(labels); yticklabels(labels);

    xtickangle(90);
    set(gca, 'FontSize', 6);

    axis square;

end

%%
function plot_point_map(map_file, odour_chemicals_file)
    
    % Load map and chemical table
    data = readmatrix(map_file);
    chemTable = readtable(odour_chemicals_file, 'FileType', 'text', 'Delimiter', '\t');
    
    % Only use chemicals that correspond to map rows
    n = size(data,1);              % number of rows in map
    labels = string(strtrim(chemTable.Code(1:n)));
    sat_ppm = chemTable.Saturated_ppm(1:n);
    
    % Avoid log(0)
    sat_ppm = sat_ppm + 1e-9;
    
    % Scatter plot
    figure('Name', 'Chemical space map (Canberra MDS)', 'Position', [100, 100, 800, 800]);
    scatter(data(:,1), data(:,2), 40, sat_ppm, 'filled');
    
    colormap(hot);
    cb = colorbar;
    cb.Label.String = 'Saturated concentration (ppm)';
    set(gca, 'ColorScale', 'log');
    caxis([min(sat_ppm), max(sat_ppm)]);
    
    hold on;
    for i = 1:numel(labels)
        text(data(i,1), data(i,2), labels(i), 'FontSize', 6, ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
    end
    hold off;
    axis equal;

end