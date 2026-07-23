function nl = solve_v72_dvdi_map(net, spec, params, opts)
%SOLVE_V72_DVDI_MAP Nonlinear dV/dI(I,T) map using local Ic switching.

T_vec = opts.T_vec(:)';
I_vec = opts.I_vec(:);
pairs = {'top_4_10','bottom_3_9'};
nT = numel(T_vec);
nI = numel(I_vec);

nl = struct();
nl.T = T_vec;
nl.I = I_vec;
nl.V4p = struct();
nl.R4p = struct();
nl.dVdI = struct();
nl.switchedFraction = zeros(nI, nT);
nl.meanAbsLinkCurrent = zeros(nI, nT);
nl.maxAbsIOverIc = zeros(nI, nT);

for kp = 1:numel(pairs)
    nl.V4p.(pairs{kp}) = NaN(nI, nT);
    nl.R4p.(pairs{kp}) = NaN(nI, nT);
    nl.dVdI.(pairs{kp}) = NaN(nI, nT);
end

for kT = 1:nT
    T = T_vec(kT);
    if kT == 1 || mod(kT, 5) == 0 || kT == nT
        fprintf('  v7.2.2 nonlinear dV/dI map: T step %d/%d, T = %.3g K\n', ...
            kT, nT, T);
    end
    [Rx0, Ry0] = link_resistance_T(params, spec, T);
    gxPrev = safe_conductance(Rx0, net.link.activeX);
    gyPrev = safe_conductance(Ry0, net.link.activeY);

    for kI = 1:nI
        Iapp = I_vec(kI);
        [v, gxPrev, gyPrev] = solve_network_nonlinear(net, spec, params, ...
            T, Iapp, gxPrev, gyPrev);
        [Ix, Iy] = solve_currents_from_conductance(net, v, gxPrev, gyPrev);

        for kp = 1:numel(pairs)
            pairName = pairs{kp};
            probes = spec.probePairs.(pairName);
            Vp = mean_probe_voltage(net, v, probes{1});
            Vm = mean_probe_voltage(net, v, probes{2});
            Vpair = Vp - Vm;
            nl.V4p.(pairName)(kI, kT) = Vpair;
            if abs(Iapp) > 0
                nl.R4p.(pairName)(kI, kT) = Vpair ./ Iapp;
            end
        end

        [swX, swY] = switched_link_masks(params, net, Ix, Iy);
        nSw = nnz(swX & net.link.activeX) + nnz(swY & net.link.activeY);
        nLinks = nnz(net.link.activeX) + nnz(net.link.activeY);
        nl.switchedFraction(kI, kT) = nSw ./ max(nLinks, 1);
        nl.meanAbsLinkCurrent(kI, kT) = mean_abs_link_current(net, Ix, Iy);
        nl.maxAbsIOverIc(kI, kT) = max_abs_current_ratio(params, net, Ix, Iy);
    end

    for kp = 1:numel(pairs)
        pairName = pairs{kp};
        V = nl.V4p.(pairName)(:, kT);
        d = gradient(V, I_vec);
        nl.dVdI.(pairName)(:, kT) = smooth_current_derivative(d, ...
            opts.smoothing.dVdI_currentWindow);
    end
end

nl.definition = ['Nonlinear fixed-point network solve. Link resistance depends ', ...
    'on T and local branch current through existing IcX/IcY.'];

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

if isfield(params, 'IcX')
    validX = net.link.activeX & isfinite(params.IcX) & params.IcX > 0;
    rx = abs(Ix(validX)) ./ params.IcX(validX);
end

if isfield(params, 'IcY')
    validY = net.link.activeY & isfinite(params.IcY) & params.IcY > 0;
    ry = abs(Iy(validY)) ./ params.IcY(validY);
end

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
