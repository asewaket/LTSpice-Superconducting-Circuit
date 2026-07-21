function [T, I, R] = load_rt_dat_file(filePath)
%LOAD_RT_DAT_FILE Load exported comma-delimited R-vs-T files.
%
% Supported examples:
%   temp,I,R1
%   temp,I,R1,R2
%   temp_K,R_ohm
%   device,temperature_K,resistance_ohm,source_file,...

if contains(char(filePath), '_RT_curve.csv')
    [T, I, R] = load_publication_rt_curve_csv(filePath);
    return;
end

opts = detectImportOptions(filePath, 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
    % Older MATLAB versions do not support VariableNamingRule.
end

function [T, I, R] = load_publication_rt_curve_csv(filePath)
%LOAD_PUBLICATION_RT_CURVE_CSV Direct parser for transport-plots curve CSVs.
%
% Expected columns:
%   device, temperature_K, resistance_ohm, source_file, ...
%
% The later columns include quoted strings and paths, so this function avoids
% MATLAB table type inference and reads only the first three columns.

fid = fopen(filePath, 'r');
if fid < 0
    error('Could not open %s.', filePath);
end

cleanup = onCleanup(@() fclose(fid));

% Skip header.
fgetl(fid);

C = textscan(fid, '%s%f%f%[^\n]', ...
    'Delimiter', ',', ...
    'CollectOutput', false, ...
    'ReturnOnError', false);

T = C{2};
I = NaN(size(T));
R = struct();
R.main_4p = C{3};

valid = isfinite(T) & isfinite(R.main_4p);
T = T(valid);
I = I(valid);
R.main_4p = R.main_4p(valid);

end
tbl = readtable(filePath, opts);

names = tbl.Properties.VariableNames;
lowerNames = lower(names);

tIdx = find(contains(lowerNames, 'temp'), 1, 'first');
if isempty(tIdx)
    tIdx = 1;
end
T = to_numeric_vector(tbl.(names{tIdx}));

iIdx = find(strcmpi(names, 'I') | strcmpi(names, 'current'), 1, 'first');
if isempty(iIdx)
    I = NaN(size(T));
else
    I = to_numeric_vector(tbl.(names{iIdx}));
end

R = struct();

% Prefer explicit numeric resistance columns. The publication-curve CSV files
% also contain text columns such as "resistance_column"; those must not be
% interpreted as plottable resistance data.
preferred = {'resistance_ohm','r_ohm','r','r1','r2'};
rIdx = [];

for kp = 1:numel(preferred)
    hit = find(strcmpi(names, preferred{kp}), 1, 'first');
    if ~isempty(hit)
        rIdx(end+1) = hit; %#ok<AGROW>
    end
end

if isempty(rIdx)
    candidates = [];
    for kn = 1:numel(lowerNames)
        lname = lowerNames{kn};
        isResistanceLike = contains(lname, 'resist') || ...
            contains(lname, 'ohm') || ...
            strcmpi(lname, 'r') || strcmpi(lname, 'r1') || strcmpi(lname, 'r2');
        isMetadata = contains(lname, 'column') || contains(lname, 'source') || ...
            contains(lname, 'method') || contains(lname, 'device');
        if isResistanceLike && ~isMetadata
            candidates(end+1) = kn; %#ok<AGROW>
        end
    end

    if isempty(candidates)
        candidates = find(startsWith(lowerNames, 'r'));
    end

    for kc = 1:numel(candidates)
        idx = candidates(kc);
        col = tbl.(names{idx});
        if isnumeric(col) || islogical(col)
            rIdx(end+1) = idx; %#ok<AGROW>
        end
    end
end

rIdx = unique(rIdx, 'stable');

if isempty(rIdx)
    % Last-resort fallback for the publication RT curve CSV format:
    % device, temperature_K, resistance_ohm, source_file, ...
    if width(tbl) >= 3 && contains(char(filePath), '_RT_curve.csv')
        T = to_numeric_vector(tbl{:,2});
        I = NaN(size(T));
        R.main_4p = to_numeric_vector(tbl{:,3});
        return;
    end

    error('No resistance column found in %s. Available columns: %s', ...
        filePath, strjoin(names, ', '));
end

for k = 1:numel(rIdx)
    idx = rIdx(k);
    rawName = names{idx};
    cleanName = matlab.lang.makeValidName(rawName);

    col = to_numeric_vector(tbl.(rawName));

    if isempty(col) || all(~isfinite(col))
        continue;
    end

    if strcmpi(rawName, 'R1')
        fieldName = 'top_4_10';
    elseif strcmpi(rawName, 'R2')
        fieldName = 'bottom_3_9';
    elseif strcmpi(rawName, 'R_ohm') || strcmpi(rawName, 'R') || strcmpi(rawName, 'resistance_ohm')
        fieldName = 'main_4p';
    else
        fieldName = cleanName;
    end

    R.(fieldName) = col;
end

if isempty(fieldnames(R))
    error('No numeric resistance column found in %s.', filePath);
end

end

function y = to_numeric_vector(x)
%TO_NUMERIC_VECTOR Robustly coerce table columns/cells/strings to double.

if istable(x)
    x = table2array(x);
end

if isnumeric(x) || islogical(x)
    y = double(x);
elseif iscell(x)
    if all(cellfun(@(c) isnumeric(c) && isscalar(c), x(:)))
        y = cellfun(@double, x);
    else
        y = str2double(x);
    end
elseif ischar(x)
    y = str2double(cellstr(x));
elseif isstring(x)
    y = str2double(cellstr(x));
elseif iscategorical(x)
    y = str2double(cellstr(x));
else
    try
        y = double(x);
    catch
        y = str2double(cellstr(x));
    end
end

y = y(:);

end
