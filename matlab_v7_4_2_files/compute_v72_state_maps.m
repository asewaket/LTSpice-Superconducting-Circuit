function maps = compute_v72_state_maps(net, spec, params, opts)
%COMPUTE_V72_STATE_MAPS Local switched-link and current-redistribution maps.

Tmap = opts.map.T_K;
Ilow = opts.map.I_low_A;
Ihigh = opts.map.I_high_A;

low = solve_state(net, spec, params, Tmap, Ilow);
high = solve_state(net, spec, params, Tmap, Ihigh);
[low.currentDensityCommonNorm, high.currentDensityCommonNorm] = ...
    normalize_pair_positive_maps(low.currentDensityNode, high.currentDensityNode, net.active);

maps = struct();
maps.T_K = Tmap;
maps.I_low_A = Ilow;
maps.I_high_A = Ihigh;
maps.low = low;
maps.high = high;
maps.redistribution = high.currentDensityNode - low.currentDensityNode;
maps.redistributionNorm = normalize_signed_map(maps.redistribution, net.active);
maps.definition = ['Switched links satisfy |I_link| >= Ic. Current density is ', ...
    'a node-averaged magnitude of adjacent x/y link currents.'];

end

function state = solve_state(net, spec, params, T, Iapp)

[Rx0, Ry0] = link_resistance_T(params, spec, T);
gx0 = safe_conductance(Rx0, net.link.activeX);
gy0 = safe_conductance(Ry0, net.link.activeY);
[v, gx, gy] = solve_network_nonlinear(net, spec, params, T, Iapp, gx0, gy0);
[Ix, Iy] = link_currents(net, v, gx, gy);
[swX, swY] = switched_link_masks(params, net, Ix, Iy);

state = struct();
state.T_K = T;
state.I_A = Iapp;
state.v = v;
state.Ix = Ix;
state.Iy = Iy;
state.gx = gx;
state.gy = gy;
state.switchedX = swX;
state.switchedY = swY;
state.switchedNode = link_to_node_fraction(net, swX, swY);
state.currentDensityNode = current_density_to_node(net, Ix, Iy);
state.currentDensityNorm = normalize_positive_map(state.currentDensityNode, net.active);
state.switchedFraction = switched_fraction(net, swX, swY);

end

function [Ix, Iy] = link_currents(net, v, gx, gy)

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

function nodeMap = current_density_to_node(net, Ix, Iy)

[Ny, Nx] = size(net.active);
nodeMap = zeros(Ny, Nx);
count = zeros(Ny, Nx);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            val = abs(Ix(row,col));
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row,col+1) = nodeMap(row,col+1) + val;
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end

for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            val = abs(Iy(row,col));
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row+1,col) = nodeMap(row+1,col) + val;
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

nodeMap(count > 0) = nodeMap(count > 0) ./ count(count > 0);
nodeMap(~net.active) = NaN;

end

function nodeMap = link_to_node_fraction(net, swX, swY)

[Ny, Nx] = size(net.active);
nodeMap = zeros(Ny, Nx);
count = zeros(Ny, Nx);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            val = double(swX(row,col));
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row,col+1) = nodeMap(row,col+1) + val;
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end

for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            val = double(swY(row,col));
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row+1,col) = nodeMap(row+1,col) + val;
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

nodeMap(count > 0) = nodeMap(count > 0) ./ count(count > 0);
nodeMap(~net.active) = NaN;

end

function frac = switched_fraction(net, swX, swY)

nSw = nnz(swX & net.link.activeX) + nnz(swY & net.link.activeY);
nLinks = nnz(net.link.activeX) + nnz(net.link.activeY);
frac = nSw ./ max(nLinks, 1);

end

function Z = normalize_positive_map(Z, active)

vals = Z(active);
vals = vals(isfinite(vals));
if isempty(vals) || max(vals) <= 0
    Z(active) = 0;
else
    Z(active) = Z(active) ./ max(vals);
end
Z(~active) = NaN;

end

function Z = normalize_signed_map(Z, active)

vals = Z(active);
vals = vals(isfinite(vals));
m = max(abs(vals));
if isempty(vals) || m <= 0
    Z(active) = 0;
else
    Z(active) = Z(active) ./ m;
end
Z(~active) = NaN;

end

function [A, B] = normalize_pair_positive_maps(A, B, active)

vals = [A(active); B(active)];
vals = vals(isfinite(vals));
if isempty(vals) || max(vals) <= 0
    A(active) = 0;
    B(active) = 0;
else
    m = max(vals);
    A(active) = A(active) ./ m;
    B(active) = B(active) ./ m;
end
A(~active) = NaN;
B(~active) = NaN;

end
