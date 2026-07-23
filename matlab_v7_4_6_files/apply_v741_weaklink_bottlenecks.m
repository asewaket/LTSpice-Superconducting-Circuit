function [params, weak] = apply_v741_weaklink_bottlenecks(params, net, spec, opts)
%APPLY_V741_WEAKLINK_BOTTLENECKS Add low-Ic Josephson-like weak links.

if nargin < 4 || ~isfield(opts, 'enabled') || ~opts.enabled
    weak = empty_weak_struct(net);
    return;
end

rng(spec.randomSeed + opts.seedOffset);

[scoreX, scoreY] = weaklink_scores(net, spec, opts);
maskX = choose_weak_mask(scoreX, net.link.activeX, opts.randomWeakFraction);
maskY = choose_weak_mask(scoreY, net.link.activeY, opts.randomWeakFraction);

params.weakLinkMaskX = maskX;
params.weakLinkMaskY = maskY;
params.dI_fracX = opts.defaultSwitchWidthFrac .* ones(size(params.IcX));
params.dI_fracY = opts.defaultSwitchWidthFrac .* ones(size(params.IcY));
params.IcBroadeningX = zeros(size(params.IcX));
params.IcBroadeningY = zeros(size(params.IcY));

params.IcX(maskX) = max(1e-13, opts.IcMultiplier .* params.IcX(maskX));
params.IcY(maskY) = max(1e-13, opts.IcMultiplier .* params.IcY(maskY));

params.RnX(maskX) = opts.RnMultiplier .* params.RnX(maskX);
params.RnY(maskY) = opts.RnMultiplier .* params.RnY(maskY);

params.fX(maskX) = max(0, opts.residualMultiplier .* params.fX(maskX));
params.fY(maskY) = max(0, opts.residualMultiplier .* params.fY(maskY));

params.dI_fracX(maskX) = opts.weakSwitchWidthFrac;
params.dI_fracY(maskY) = opts.weakSwitchWidthFrac;
params.IcBroadeningX(maskX) = opts.currentBroadening_A;
params.IcBroadeningY(maskY) = opts.currentBroadening_A;

weak = struct();
weak.version = opts.version;
weak.maskX = maskX;
weak.maskY = maskY;
weak.scoreX = scoreX;
weak.scoreY = scoreY;
weak.nodeMap = link_to_node_fraction(net, maskX, maskY);
weak.activeLinkFraction = (nnz(maskX & net.link.activeX) + nnz(maskY & net.link.activeY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));
weak.definition = ['v7.4.1 weak-link bottleneck layer: selected links have ', ...
    'suppressed Ic, modestly enhanced Rn, lower residual superconducting ', ...
    'floor, and sharper current switching.'];

end

function weak = empty_weak_struct(net)

weak = struct();
weak.version = 'v7.4.1';
weak.maskX = false(size(net.link.activeX));
weak.maskY = false(size(net.link.activeY));
weak.scoreX = zeros(size(net.link.activeX));
weak.scoreY = zeros(size(net.link.activeY));
weak.nodeMap = zeros(size(net.active));
weak.nodeMap(~net.active) = NaN;
weak.activeLinkFraction = 0;
weak.definition = 'weak-link layer disabled';

end

function [scoreX, scoreY] = weaklink_scores(net, spec, opts)

[midXx, midYx, midXy, midYy] = link_midpoints(net);

scoreX = zeros(size(net.link.activeX));
scoreY = zeros(size(net.link.activeY));

% Boundary lane between stressed/unstressed regions.
laneX = exp(-(midYx ./ opts.boundaryLaneWidth_um).^2);
laneY = exp(-(midYy ./ opts.boundaryLaneWidth_um).^2);
scoreX = scoreX + opts.boundaryWeight .* laneX;
scoreY = scoreY + opts.boundaryWeight .* laneY;

% Covered-side edge / relaxation inhomogeneity.
if isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'bottom')
    scoreX = scoreX + opts.coveredEdgeWeight .* max(0, -midYx ./ max(abs(min(net.y_um)), eps));
    scoreY = scoreY + opts.coveredEdgeWeight .* max(0, -midYy ./ max(abs(min(net.y_um)), eps));
elseif isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'top')
    scoreX = scoreX + opts.coveredEdgeWeight .* max(0, midYx ./ max(abs(max(net.y_um)), eps));
    scoreY = scoreY + opts.coveredEdgeWeight .* max(0, midYy ./ max(abs(max(net.y_um)), eps));
end

% A few compact hotspots along plausible bottleneck regions.
for k = 1:opts.numHotspots
    x0 = min(net.x_um) + rand() .* (max(net.x_um) - min(net.x_um));
    y0 = opts.boundaryLaneWidth_um .* randn() .* 0.35;
    hx = exp(-((midXx - x0).^2 + (midYx - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
    hy = exp(-((midXy - x0).^2 + (midYy - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
    scoreX = scoreX + opts.hotspotWeight .* hx;
    scoreY = scoreY + opts.hotspotWeight .* hy;
end

% Favor high eta regions where superconductivity is locally enhanced but
% connectivity is bottlenecked.
if isfield(net.link, 'etaX')
    scoreX = scoreX .* (0.4 + 0.6 .* normalize_positive(net.link.etaX));
end
if isfield(net.link, 'etaY')
    scoreY = scoreY .* (0.4 + 0.6 .* normalize_positive(net.link.etaY));
end

scoreX(~net.link.activeX) = 0;
scoreY(~net.link.activeY) = 0;

end

function mask = choose_weak_mask(score, active, frac)

mask = false(size(active));
vals = score(active);
vals = vals(isfinite(vals));
if isempty(vals)
    return;
end

threshold = percentile_local(vals, 100 .* (1 - frac));
mask = active & score >= threshold & score > 0;

end

function [midXx, midYx, midXy, midYy] = link_midpoints(net)

[X, Y] = meshgrid(net.x_um, net.y_um);
midXx = 0.5 .* (X(:,1:end-1) + X(:,2:end));
midYx = 0.5 .* (Y(:,1:end-1) + Y(:,2:end));
midXy = 0.5 .* (X(1:end-1,:) + X(2:end,:));
midYy = 0.5 .* (Y(1:end-1,:) + Y(2:end,:));

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

function Z = normalize_positive(Z)

vals = Z(isfinite(Z));
if isempty(vals) || max(vals) <= 0
    Z(:) = 0;
else
    Z = Z ./ max(vals);
end

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
