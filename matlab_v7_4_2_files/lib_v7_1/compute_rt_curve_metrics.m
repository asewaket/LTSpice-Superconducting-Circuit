function metrics = compute_rt_curve_metrics(T, R, opts)
%COMPUTE_RT_CURVE_METRICS Extract semiquantitative normalized R(T) metrics.
%
% Metrics:
%   RN, Rlow, rLow, suppressionFrac, Tonset, Tmid, T90, T10, width90_10

if nargin < 3 || isempty(opts)
    opts = make_metric_options();
end

T = local_numeric_vector(T);
R = local_numeric_vector(R);

n = min(numel(T), numel(R));
T = T(1:n);
R = R(1:n);

valid = isfinite(T) & isfinite(R);
T = T(valid);
R = R(valid);

[T, order] = sort(T);
R = R(order);

if opts.smoothingWindow > 1
    Rwork = movmean(R, opts.smoothingWindow);
else
    Rwork = R;
end

n = numel(Rwork);
if n == 0
    metrics = empty_metrics();
    return;
end

nHigh = min(n, max(opts.nHighDefault, ceil(opts.highFrac * n)));
nLow = min(n, max(opts.nLowDefault, ceil(opts.lowFrac * n)));

RN = local_nanmean(Rwork(end-nHigh+1:end));
Rlow = local_nanmean(Rwork(1:nLow));
r = Rwork ./ RN;
rLow = Rlow / RN;

metrics = struct();
metrics.N_points = n;
metrics.T_min_K = min(T);
metrics.T_max_K = max(T);
metrics.RN_ohm = RN;
metrics.Rlow_ohm = Rlow;
metrics.rLow = rLow;
metrics.suppressionFrac = 1 - rLow;

metrics.Tonset_K = find_onset_temperature(T, r, opts.onsetThreshold, opts.minConsecutiveBelow);

rMid = rLow + 0.50 * (1 - rLow);
r90 = rLow + opts.widthHighFraction * (1 - rLow);
r10 = rLow + opts.widthLowFraction * (1 - rLow);

metrics.rMid = rMid;
metrics.r90 = r90;
metrics.r10 = r10;

metrics.Tmid_K = crossing_temperature(T, r, rMid);
metrics.T90_K = crossing_temperature(T, r, r90);
metrics.T10_K = crossing_temperature(T, r, r10);
metrics.width90_10_K = metrics.T90_K - metrics.T10_K;

end

function Tonset = find_onset_temperature(T, r, threshold, minConsecutive)

below = r < threshold;
Tonset = NaN;

for k = numel(T):-1:1
    k2 = min(numel(T), k + minConsecutive - 1);
    if all(below(k:k2))
        Tonset = T(k);
        return;
    end
end

end

function Tc = crossing_temperature(T, r, target)

Tc = NaN;
if isempty(T) || ~isfinite(target)
    return;
end

diffVals = r - target;
idx = find(diffVals(1:end-1) .* diffVals(2:end) <= 0, 1, 'last');

if isempty(idx)
    [~, nearest] = min(abs(diffVals));
    if ~isempty(nearest)
        Tc = T(nearest);
    end
    return;
end

x1 = r(idx);
x2 = r(idx+1);
t1 = T(idx);
t2 = T(idx+1);

if x2 == x1
    Tc = mean([t1 t2]);
else
    Tc = t1 + (target - x1) * (t2 - t1) / (x2 - x1);
end

end

function metrics = empty_metrics()

metrics = struct( ...
    'N_points', 0, ...
    'T_min_K', NaN, ...
    'T_max_K', NaN, ...
    'RN_ohm', NaN, ...
    'Rlow_ohm', NaN, ...
    'rLow', NaN, ...
    'suppressionFrac', NaN, ...
    'Tonset_K', NaN, ...
    'rMid', NaN, ...
    'r90', NaN, ...
    'r10', NaN, ...
    'Tmid_K', NaN, ...
    'T90_K', NaN, ...
    'T10_K', NaN, ...
    'width90_10_K', NaN);

end

function y = local_numeric_vector(x)

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

function m = local_nanmean(x)
x = x(isfinite(x));
if isempty(x)
    m = NaN;
else
    m = mean(x);
end
end
