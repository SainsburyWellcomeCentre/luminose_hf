function mapping = getOdourMapping()
    % getOdourMapping  Read odour_bottles.tsv and return a struct array
    
    % Default mapping if file not found
    mapping = struct('Name', arrayfun(@(i) sprintf('V%d', i), 1:16, 'UniformOutput', false), ...
                     'Chemicals', repmat({''}, 1, 16), ...
                     'Notes', repmat({''}, 1, 16));
    
    try
        % Find the file in olfactometer/ relative to the repository root
        guiPath = fileparts(mfilename('fullpath'));
        repoRoot = fileparts(guiPath);
        filePath = fullfile(repoRoot, 'olfactometer', 'odour_bottles.tsv');
        
        if exist(filePath, 'file')
            fid = fopen(filePath, 'r');
            header = fgetl(fid); % skip header
            i = 1;
            while ~feof(fid) && i <= 16
                line = fgetl(fid);
                parts = strsplit(line, char(9)); % tab separated
                if length(parts) >= 2
                    mapping(i).Name = parts{1};
                    mapping(i).Chemicals = parts{2};
                end
                if length(parts) >= 8
                    mapping(i).Notes = parts{8};
                end
                i = i + 1;
            end
            fclose(fid);
        else
             warning('Odour bottles file not found at: %s', filePath);
        end
    catch ME
        warning('Error reading odour bottles: %s', ME.message);
        % Fallback to default mapping already initialized
    end
end
