function expField = load_v73_experimental_field_dvdi(device)
%LOAD_V73_EXPERIMENTAL_FIELD_DVDI Load dV/dI(I,B) field sweep data.
%
% The AS006 files used here are out-of-plane magnetic-field sweeps. R1 and
% R2 are mapped to the same four-probe pairs used elsewhere:
%   R1 -> top_4_10
%   R2 -> bottom_3_9

if nargin < 1 || strlength(string(device)) == 0
    device = 'AS006';
end

device = char(string(device));
expField = empty_exp_field(device);

info = experimental_field_file_info(device);
if ~info.available
    expField.message = sprintf('No experimental dV/dI(I,B) file mapped for %s.', device);
    warning('%s', expField.message);
    return;
end

if ~exist(info.filePath, 'file')
    expField.message = sprintf('Mapped field file does not exist: %s', info.filePath);
    warning('%s', expField.message);
    return;
end

opts = detectImportOptions(info.filePath, 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
end
tbl = readtable(info.filePath, opts);

names = tbl.Properties.VariableNames;
B = to_numeric_vector(tbl.(names{find(strcmpi(names, 'Bfield'), 1, 'first')}));
I = to_numeric_vector(tbl.(names{find(strcmpi(names, 'I'), 1, 'first')}));

expField.available = true;
expField.device = device;
expField.filePath = info.filePath;
expField.sourceLabel = info.sourceLabel;
expField.fieldDirection = info.fieldDirection;
expField.assumedTemperature_K = info.assumedTemperature_K;
expField.Braw_T = B(:);
expField.Iraw_A = I(:);
expField.B_T = unique(B(:), 'sorted')';
expField.I_A = unique(I(:), 'sorted');
expField.R = struct();
expField.Rnorm = struct();
expField.RN = struct();
expField.zeroBias = struct();

for k = 1:numel(names)
    rawName = names{k};
    if strcmpi(rawName, 'R1')
        pairName = 'top_4_10';
    elseif strcmpi(rawName, 'R2')
        pairName = 'bottom_3_9';
    else
        continue;
    end

    Rvals = to_numeric_vector(tbl.(rawName));
    Z = grid_resistance(B, I, Rvals, expField.B_T, expField.I_A);
    RN = estimate_rn_from_grid(Z);
    expField.R.(pairName) = Z;
    expField.Rnorm.(pairName) = Z ./ max(RN, eps);
    expField.RN.(pairName) = RN;
    expField.zeroBias.(pairName) = zero_bias_trace(expField.I_A, Z);
end

if isempty(fieldnames(expField.R))
    expField.available = false;
    expField.message = sprintf('No R1/R2 field-sweep columns found in %s.', info.filePath);
    warning('%s', expField.message);
else
    expField.message = sprintf('Loaded %s out-of-plane dV/dI(I,B): %s', ...
        device, info.sourceLabel);
end

end

function info = experimental_field_file_info(device)

root = '/Users/asewaket/Documents/Thesis/Raw Transport Data/2023_5_26_ASD087/data';
info = struct();
info.available = false;
info.filePath = '';
info.sourceLabel = '';
info.fieldDirection = 'out_of_plane';
info.assumedTemperature_K = 0.06;

switch upper(device)
    case 'AS006'
        info.available = true;
        info.filePath = fullfile(root, 'ASD092_dVdIvIvB_0108.dat');
        info.sourceLabel = 'ASD092 dVdI vs I vs B 0108';
    otherwise
        % Add other devices here once their field sweeps are identified.
end

end

function expField = empty_exp_field(device)

expField = struct();
expField.available = false;
expField.device = device;
expField.filePath = '';
expField.sourceLabel = '';
expField.fieldDirection = 'out_of_plane';
expField.assumedTemperature_K = NaN;
expField.message = '';
expField.Braw_T = [];
expField.Iraw_A = [];
expField.B_T = [];
expField.I_A = [];
expField.R = struct();
expField.Rnorm = struct();
expField.RN = struct();
expField.zeroBias = struct();

end

function y = to_numeric_vector(x)

if istable(x)
    x = table2array(x);
end

if isnumeric(x) || islogical(x)
    y = double(x);
elseif iscell(x)
    y = str2double(x);
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

function Z = grid_resistance(B, I, R, Bu, Iu)

B = B(:);
I = I(:);
R = R(:);
valid = isfinite(B) & isfinite(I) & isfinite(R);
B = B(valid);
I = I(valid);
R = R(valid);

[~, bIdx] = ismember(B, Bu);
[~, iIdx] = ismember(I, Iu);
valid = bIdx > 0 & iIdx > 0;

Z = NaN(numel(Iu), numel(Bu));
if any(valid)
    Z = accumarray([iIdx(valid), bIdx(valid)], R(valid), ...
        [numel(Iu), numel(Bu)], @mean, NaN);
end

end

function RN = estimate_rn_from_grid(Z)

vals = Z(isfinite(Z));
if isempty(vals)
    RN = NaN;
else
    RN = percentile_local(vals, 95);
end

end

function zb = zero_bias_trace(I, Z)

[~, idx] = min(abs(I));
zb = Z(idx, :);

end

function p = percentile_local(x, pct)

x = sort(x(:));
q = 1 + (numel(x)-1) * pct / 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (q-lo) * (x(hi)-x(lo));
end

end
