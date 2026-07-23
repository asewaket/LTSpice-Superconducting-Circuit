function expDvdI = load_v722_experimental_dvdi(device)
%LOAD_V722_EXPERIMENTAL_DVDI Load experimental dV/dI(I,T) data for v7.2.2.
%
% This loader is intentionally separated from load_experimental_rt because
% the nonlinear v7.2.2 plots need an I-axis grid, not only an R(T) trace.
% The returned R maps are differential resistance in ohms; normalized maps
% are also provided as dVdI/RN using a high-resistance percentile estimate.

if nargin < 1 || strlength(string(device)) == 0
    device = 'AS006';
end

device = char(string(device));
expDvdI = empty_exp_dvdi(device);

info = experimental_dvdi_file_info(device);
if ~info.available
    expDvdI.message = sprintf('No experimental dV/dI(I,T) file mapped for %s.', device);
    warning('%s', expDvdI.message);
    return;
end

if ~exist(info.filePath, 'file')
    expDvdI.message = sprintf('Mapped dV/dI file does not exist: %s', info.filePath);
    warning('%s', expDvdI.message);
    return;
end

[T, I, R] = load_rt_dat_file(info.filePath);

expDvdI.available = true;
expDvdI.device = device;
expDvdI.filePath = info.filePath;
expDvdI.sourceLabel = info.sourceLabel;
expDvdI.Traw = T(:);
expDvdI.Iraw = I(:);
expDvdI.Rraw = R;
expDvdI.T = unique(T(:), 'sorted')';
expDvdI.I = unique(I(:), 'sorted');
expDvdI.R = struct();
expDvdI.Rnorm = struct();
expDvdI.RN = struct();

pairs = fieldnames(R);
for k = 1:numel(pairs)
    pairName = pairs{k};
    vals = R.(pairName);
    if ~isnumeric(vals)
        continue;
    end

    Z = grid_resistance(T, I, vals, expDvdI.T, expDvdI.I);
    RN = estimate_rn_from_dvdi_grid(Z);

    expDvdI.R.(pairName) = Z;
    expDvdI.RN.(pairName) = RN;
    expDvdI.Rnorm.(pairName) = Z ./ max(RN, eps);
end

if isempty(fieldnames(expDvdI.R))
    expDvdI.available = false;
    expDvdI.message = sprintf('No numeric dV/dI resistance fields found in %s.', info.filePath);
    warning('%s', expDvdI.message);
else
    expDvdI.message = sprintf('Loaded %s dV/dI(I,T): %s', device, info.sourceLabel);
end

end

function info = experimental_dvdi_file_info(device)

root = '/Users/asewaket/Documents/Thesis/Raw Transport Data/2023_5_26_ASD087/data';
info = struct();
info.available = false;
info.filePath = '';
info.sourceLabel = '';

switch upper(device)
    case 'AS006'
        % Wider current sweep than ASD092_dVdIvIvT_0132.dat.
        info.available = true;
        info.filePath = fullfile(root, 'ASD092_dVdIvIvT_0118.dat');
        info.sourceLabel = 'ASD092 dVdI vs I vs T 0118';
    otherwise
        % Additional devices can be added here as their nonlinear files are
        % identified. R(T)-only devices are still valid for v7.1/v7.2
        % geometry modeling, but cannot populate experimental I-cuts.
end

end

function expDvdI = empty_exp_dvdi(device)

expDvdI = struct();
expDvdI.available = false;
expDvdI.device = device;
expDvdI.filePath = '';
expDvdI.sourceLabel = '';
expDvdI.message = '';
expDvdI.Traw = [];
expDvdI.Iraw = [];
expDvdI.Rraw = struct();
expDvdI.T = [];
expDvdI.I = [];
expDvdI.R = struct();
expDvdI.Rnorm = struct();
expDvdI.RN = struct();

end

function Z = grid_resistance(T, I, R, Tu, Iu)

T = T(:);
I = I(:);
R = R(:);
valid = isfinite(T) & isfinite(I) & isfinite(R);
T = T(valid);
I = I(valid);
R = R(valid);

[~, tIdx] = ismember(T, Tu);
[~, iIdx] = ismember(I, Iu);
valid = tIdx > 0 & iIdx > 0;

Z = NaN(numel(Iu), numel(Tu));
if any(valid)
    Z = accumarray([iIdx(valid), tIdx(valid)], R(valid), ...
        [numel(Iu), numel(Tu)], @mean, NaN);
end

end

function RN = estimate_rn_from_dvdi_grid(Z)

vals = Z(isfinite(Z));
if isempty(vals)
    RN = NaN;
    return;
end

% Use an upper percentile rather than max to avoid one noisy current point
% setting the normalization.
RN = percentile_local(vals, 95);

end

function p = percentile_local(x, pct)

x = sort(x(:));
if isempty(x)
    p = NaN;
    return;
end

q = 1 + (numel(x)-1) * pct / 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (q-lo) * (x(hi)-x(lo));
end

end
