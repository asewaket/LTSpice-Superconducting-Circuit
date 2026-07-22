function raman = load_raman_digitized_data(dataDir)
%LOAD_RAMAN_DIGITIZED_DATA Load digitized Raman line-scan peak-position data.
%
%   raman = LOAD_RAMAN_DIGITIZED_DATA()
%   raman = LOAD_RAMAN_DIGITIZED_DATA(dataDir)
%
% The expected input files are comma-separated text files with comment lines
% beginning with '#', followed by the columns:
%
%   device, scan_direction, mode, position_um, peak_cm1, delta_peak_cm1
%
% The returned table keeps the digitized values and adds compact labels that
% are useful for plotting and later model registration.

if nargin < 1 || isempty(dataDir)
    projectDir = fileparts(mfilename('fullpath'));
    dataDir = fullfile(projectDir, 'data', 'raman_digitized');
end

files = dir(fullfile(dataDir, '*_raman_digitized.txt'));
if isempty(files)
    error('No *_raman_digitized.txt files found in %s.', dataDir);
end

allTables = cell(numel(files), 1);
for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);
    rawText = fileread(filePath);
    lines = regexp(rawText, '\r\n|\n|\r', 'split')';
    keep = true(size(lines));
    for n = 1:numel(lines)
        s = strtrim(lines{n});
        keep(n) = ~isempty(s) && ~startsWith(s, '#');
    end
    cleanText = strjoin(lines(keep), newline);

    C = textscan(cleanText, '%s%s%s%f%f%f', ...
        'Delimiter', ',', ...
        'HeaderLines', 1, ...
        'CollectOutput', false);

    T = table( ...
        string(strtrim(C{1})), ...
        string(strtrim(C{2})), ...
        string(strtrim(C{3})), ...
        C{4}, C{5}, C{6}, ...
        repmat(string(files(k).name), numel(C{4}), 1), ...
        'VariableNames', {'device', 'scan_direction', 'mode', ...
        'position_um', 'peak_cm1', 'delta_peak_cm1', 'source_file'});

    T.series_id = T.device + "_" + T.scan_direction + "_" + T.mode;
    allTables{k} = T;
end

raman = vertcat(allTables{:});
raman = sortrows(raman, {'device', 'scan_direction', 'mode', 'position_um'});

end
