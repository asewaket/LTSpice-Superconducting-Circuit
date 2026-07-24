function opts = make_v72_nonlinear_options(params, net)
%MAKE_V72_NONLINEAR_OPTIONS Options for v7.2.2 nonlinear diagnostics.

if nargin < 1
    params = [];
end
if nargin < 2
    net = [];
end

opts = struct();
opts.version = 'v7.2.2';

% Temperature/current grid for the first nonlinear map. Keep this moderate so
% the first AS006 scaffold runs quickly enough to iterate.
opts.T_vec = linspace(0.05, 2.20, 55);
opts.nI = 81;
opts.Imax_A = estimate_current_axis_max(params, net);
opts.I_vec = linspace(-opts.Imax_A, opts.Imax_A, opts.nI);

% Selected spatial-map conditions. I_map_high intentionally sits below the
% maximum sweep current so the current-density maps are not dominated only by
% the fully normal limit.
opts.map.T_K = 0.25;
opts.map.I_low_A = 0.05 * opts.Imax_A;
opts.map.I_high_A = 0.70 * opts.Imax_A;
opts.map.I_signed_A = opts.map.I_high_A;

% Numerical derivatives for dV/dI are lightly smoothed only along current.
opts.smoothing.dVdI_currentWindow = 3;

opts.output.subdir = fullfile('outputs', 'v7_2_2_as006_nonlinear_maps');

end

function Imax = estimate_current_axis_max(params, net)

fallback = 3.0e-6;
Imax = fallback;

if isempty(params) || isempty(net) || ~isstruct(params)
    return;
end

Ic = [];
if isfield(params, 'IcX') && isfield(net, 'link') && isfield(net.link, 'activeX')
    vals = params.IcX(net.link.activeX);
    Ic = [Ic; vals(:)]; %#ok<AGROW>
end
if isfield(params, 'IcY') && isfield(net, 'link') && isfield(net.link, 'activeY')
    vals = params.IcY(net.link.activeY);
    Ic = [Ic; vals(:)]; %#ok<AGROW>
end

Ic = Ic(isfinite(Ic) & Ic > 0);
if isempty(Ic)
    return;
end

% Use a high percentile rather than max so one very strong link does not make
% the whole I-axis uninformative.
Imax = 1.8 * percentile_local(Ic, 90);
Imax = max(0.5e-6, min(6.0e-6, Imax));

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
