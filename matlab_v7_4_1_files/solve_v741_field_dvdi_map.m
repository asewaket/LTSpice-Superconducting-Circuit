function field = solve_v741_field_dvdi_map(net, spec, params0, opts, weak)
%SOLVE_V741_FIELD_DVDI_MAP Simulate dV/dI(I,B) with weak-link nonlinearities.

B_vec = opts.B_vec_T(:)';
I_vec = opts.I_vec_A(:);
pairs = {'top_4_10','bottom_3_9'};
nB = numel(B_vec);
nI = numel(I_vec);

if nargin < 5
    weak = struct();
end

field = struct();
field.version = 'v7.4.1';
field.T_K = opts.T_K;
field.B_T = B_vec;
field.I_A = I_vec;
field.fieldDirection = opts.fieldDirection;
field.weakLinkDefinition = '';
field.weakLinkFraction = NaN;
if isfield(weak, 'definition')
    field.weakLinkDefinition = weak.definition;
end
if isfield(weak, 'activeLinkFraction')
    field.weakLinkFraction = weak.activeLinkFraction;
end
field.V4p = struct();
field.R4p = struct();
field.dVdI = struct();
field.switchedFraction = zeros(nI, nB);
field.weakSwitchedFraction = zeros(nI, nB);
field.maxAbsIOverIc = zeros(nI, nB);
field.meanAbsLinkCurrent = zeros(nI, nB);
field.meanTcFactor = zeros(1, nB);
field.meanIcFactor = zeros(1, nB);

for kp = 1:numel(pairs)
    field.V4p.(pairs{kp}) = NaN(nI, nB);
    field.R4p.(pairs{kp}) = NaN(nI, nB);
    field.dVdI.(pairs{kp}) = NaN(nI, nB);
end

for kB = 1:nB
    B = B_vec(kB);
    if kB == 1 || mod(kB, 10) == 0 || kB == nB
        fprintf('  v7.4.1 weak-link field dV/dI map: B step %d/%d, B = %.4g T\n', ...
            kB, nB, B);
    end

    paramsB = apply_v73_field_to_params(params0, net, opts, B);
    tcRatio = [paramsB.TcX(net.link.activeX) ./ max(params0.TcX(net.link.activeX), eps); ...
        paramsB.TcY(net.link.activeY) ./ max(params0.TcY(net.link.activeY), eps)];
    icRatio = [paramsB.IcX(net.link.activeX) ./ max(params0.IcX(net.link.activeX), eps); ...
        paramsB.IcY(net.link.activeY) ./ max(params0.IcY(net.link.activeY), eps)];
    field.meanTcFactor(kB) = mean(tcRatio(isfinite(tcRatio)), 'omitnan');
    field.meanIcFactor(kB) = mean(icRatio(isfinite(icRatio)), 'omitnan');

    [Rx0, Ry0] = link_resistance_T(paramsB, spec, opts.T_K);
    gxPrev = safe_conductance(Rx0, net.link.activeX);
    gyPrev = safe_conductance(Ry0, net.link.activeY);

    for kI = 1:nI
        Iapp = I_vec(kI);
        [v, gxPrev, gyPrev] = solve_network_nonlinear_v741(net, spec, paramsB, ...
            opts.T_K, Iapp, gxPrev, gyPrev);
        [Ix, Iy] = solve_currents_from_conductance(net, v, gxPrev, gyPrev);

        for kp = 1:numel(pairs)
            pairName = pairs{kp};
            probes = spec.probePairs.(pairName);
            Vp = mean_probe_voltage(net, v, probes{1});
            Vm = mean_probe_voltage(net, v, probes{2});
            Vpair = Vp - Vm;
            field.V4p.(pairName)(kI, kB) = Vpair;
            if abs(Iapp) > 0
                field.R4p.(pairName)(kI, kB) = Vpair ./ Iapp;
            end
        end

        [swX, swY] = switched_link_masks(paramsB, net, Ix, Iy);
        nSw = nnz(swX & net.link.activeX) + nnz(swY & net.link.activeY);
        nLinks = nnz(net.link.activeX) + nnz(net.link.activeY);
        field.switchedFraction(kI, kB) = nSw ./ max(nLinks, 1);
        field.weakSwitchedFraction(kI, kB) = weak_switched_fraction(net, paramsB, swX, swY);
        field.maxAbsIOverIc(kI, kB) = max_abs_current_ratio(paramsB, net, Ix, Iy);
        field.meanAbsLinkCurrent(kI, kB) = mean_abs_link_current(net, Ix, Iy);
    end

    for kp = 1:numel(pairs)
        pairName = pairs{kp};
        V = field.V4p.(pairName)(:, kB);
        d = gradient(V, I_vec);
        field.dVdI.(pairName)(:, kB) = smooth_current_derivative(d, ...
            opts.smoothing.dVdI_currentWindow);
    end
end

field.definition = ['Fixed-temperature out-of-plane field sweep. Field ', ...
    'suppresses local Tc and Ic and adds a flux-flow-like finite-resistance ', ...
    'contribution before a sharpened weak-link nonlinear current solve.'];

end

function [Ix, Iy] = solve_currents_from_conductance(net, v, gx, gy)

[Ny, Nx] = size(v);
Ix = zeros(Ny, Nx-1);
Iy = zeros(Ny-1, Nx);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            Ix(row,col) = gx(row,col) * (v(row,col) - v(row,col+1));
        end
    end
end

function f = weak_switched_fraction(net, params, swX, swY)

if ~(isfield(params, 'weakLinkMaskX') && isfield(params, 'weakLinkMaskY'))
    f = NaN;
    return;
end

weakX = params.weakLinkMaskX & net.link.activeX;
weakY = params.weakLinkMaskY & net.link.activeY;
nWeak = nnz(weakX) + nnz(weakY);
if nWeak == 0
    f = NaN;
    return;
end
f = (nnz(swX & weakX) + nnz(swY & weakY)) ./ nWeak;

end

for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            Iy(row,col) = gy(row,col) * (v(row,col) - v(row+1,col));
        end
    end
end

end

function [swX, swY] = switched_link_masks(params, net, Ix, Iy)

swX = false(size(params.IcX));
swY = false(size(params.IcY));
swX(net.link.activeX) = abs(Ix(net.link.activeX)) >= params.IcX(net.link.activeX);
swY(net.link.activeY) = abs(Iy(net.link.activeY)) >= params.IcY(net.link.activeY);

end

function r = max_abs_current_ratio(params, net, Ix, Iy)

rx = [];
ry = [];
validX = net.link.activeX & isfinite(params.IcX) & params.IcX > 0;
validY = net.link.activeY & isfinite(params.IcY) & params.IcY > 0;
rx = abs(Ix(validX)) ./ params.IcX(validX);
ry = abs(Iy(validY)) ./ params.IcY(validY);
vals = [rx(:); ry(:)];
vals = vals(isfinite(vals));
if isempty(vals)
    r = NaN;
else
    r = max(vals);
end

end

function m = mean_abs_link_current(net, Ix, Iy)

vals = [abs(Ix(net.link.activeX)); abs(Iy(net.link.activeY))];
vals = vals(isfinite(vals));
if isempty(vals)
    m = NaN;
else
    m = mean(vals);
end

end

function y = smooth_current_derivative(y, win)

if nargin < 2 || win <= 1
    return;
end
win = max(1, round(win));
if win <= 1 || numel(y) < win
    return;
end
kernel = ones(win, 1) ./ win;
y = conv(y(:), kernel, 'same');

end
