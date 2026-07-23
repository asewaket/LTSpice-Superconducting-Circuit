function registration = load_raman_scan_registration(filePath)
%LOAD_RAMAN_SCAN_REGISTRATION Load Raman scan endpoints in Hall-bar coordinates.
%
% Expected columns:
%
%   device, scan_id, x0_um, y0_um, x1_um, y1_um
%
% The coordinates are in the same simplified Hall-bar coordinate system used
% by build_hallbar_network.m. A digitized line-scan position is mapped onto
% this line segment by normalized arc length.

if nargin < 1 || isempty(filePath)
    projectDir = fileparts(mfilename('fullpath'));
    filePath = fullfile(projectDir, 'data', 'raman_registration', ...
        'raman_scan_endpoints_hallbar_coordinates.txt');
end

if ~exist(filePath, 'file')
    error('Raman scan registration file not found: %s', filePath);
end

rawText = fileread(filePath);
lines = regexp(rawText, '\r\n|\n|\r', 'split')';
keep = true(size(lines));
for n = 1:numel(lines)
    s = strtrim(lines{n});
    keep(n) = ~isempty(s) && ~startsWith(s, '#');
end
cleanText = strjoin(lines(keep), newline);

C = textscan(cleanText, '%s%s%f%f%f%f', ...
    'Delimiter', ',', ...
    'HeaderLines', 1, ...
    'CollectOutput', false);

registration = table( ...
    string(strtrim(C{1})), ...
    string(strtrim(C{2})), ...
    C{3}, C{4}, C{5}, C{6}, ...
    'VariableNames', {'device', 'scan_id', 'x0_um', 'y0_um', 'x1_um', 'y1_um'});

registration.scan_length_um = hypot( ...
    registration.x1_um - registration.x0_um, ...
    registration.y1_um - registration.y0_um);

zeroLength = registration.scan_length_um <= 0;
if any(zeroLength)
    bad = registration.scan_id(zeroLength);
    error('Registration contains zero-length scan endpoint(s): %s', strjoin(bad, ', '));
end

registration = sortrows(registration, {'device', 'scan_id'});

end
