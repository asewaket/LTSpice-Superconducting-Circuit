function net = build_hallbar_network(spec)
%BUILD_HALLBAR_NETWORK Build simplified Hall-bar masks and link-region maps.

dx = spec.grid.dx_um;
dy = spec.grid.dy_um;
L = spec.geom.activeLength_um;
W = spec.geom.channelWidth_um;

x = linspace(-L/2, L/2, round(L/dx) + 1);
y = linspace(-W/2, W/2, round(W/dy) + 1);
[X, Y] = meshgrid(x, y);

active = true(size(X));
if isfield(spec, 'flakeOutline') && isfield(spec.flakeOutline, 'enabled') && ...
        spec.flakeOutline.enabled
    active = inpolygon(X, Y, spec.flakeOutline.x_um, spec.flakeOutline.y_um);
end

nominalSourceMask = X <= min(x) + spec.geom.currentContactDepth_um;
nominalDrainMask = X >= max(x) - spec.geom.currentContactDepth_um;
sourceMask = active & nominalSourceMask;
drainMask = active & nominalDrainMask;

probeHalfX = spec.geom.probeWidth_um / 2;
probeHalfY = max(0.35, 0.75 * spec.geom.probeWidth_um);
if isfield(spec.geom, 'probeXLeft_um')
    probeXLeft = spec.geom.probeXLeft_um;
    probeXRight = spec.geom.probeXRight_um;
else
    probeXLeft = -spec.geom.probeSpacing_um / 2;
    probeXRight = spec.geom.probeSpacing_um / 2;
end

if isfield(spec.geom, 'probeYTop_um')
    probeYTop = spec.geom.probeYTop_um;
    probeYBottom = spec.geom.probeYBottom_um;
else
    probeYTop = 0.32 * W;
    probeYBottom = -0.32 * W;
end

nominalProbeMasks = struct();
nominalProbeMasks.P4  = abs(X - probeXLeft)  <= probeHalfX & abs(Y - probeYTop)    <= probeHalfY;
nominalProbeMasks.P10 = abs(X - probeXRight) <= probeHalfX & abs(Y - probeYTop)    <= probeHalfY;
nominalProbeMasks.P3  = abs(X - probeXLeft)  <= probeHalfX & abs(Y - probeYBottom) <= probeHalfY;
nominalProbeMasks.P9  = abs(X - probeXRight) <= probeHalfX & abs(Y - probeYBottom) <= probeHalfY;

probeMasks = struct();
probeMasks.P4  = active & nominalProbeMasks.P4;
probeMasks.P10 = active & nominalProbeMasks.P10;
probeMasks.P3  = active & nominalProbeMasks.P3;
probeMasks.P9  = active & nominalProbeMasks.P9;

probeMasks.P4  = ensure_probe_node(probeMasks.P4,  active, X, Y, probeXLeft,  probeYTop);
probeMasks.P10 = ensure_probe_node(probeMasks.P10, active, X, Y, probeXRight, probeYTop);
probeMasks.P3  = ensure_probe_node(probeMasks.P3,  active, X, Y, probeXLeft,  probeYBottom);
probeMasks.P9  = ensure_probe_node(probeMasks.P9,  active, X, Y, probeXRight, probeYBottom);

probeOverlap = compute_probe_overlap(nominalProbeMasks, probeMasks);
warn_if_probe_clipped(spec, probeOverlap);

coveredMask = false(size(active));
boundaryMask = false(size(active));
crackMask = false(size(active));

switch spec.geometryClass
    case 'control'
        % no stressor mask

    case 'full'
        coveredMask = active;

    case 'half'
        boundaryMask = active & abs(Y) <= spec.geom.boundaryWidth_um / 2;
        switch spec.coveredSide
            case 'top'
                coveredMask = active & Y > spec.geom.boundaryWidth_um / 2;
            case 'bottom'
                coveredMask = active & Y < -spec.geom.boundaryWidth_um / 2;
            otherwise
                error('Unknown coveredSide "%s" for half geometry.', spec.coveredSide);
        end

    case 'cracked_full'
        coveredMask = active;
        yCrack = spec.crack.y0_um + spec.crack.slope * X;
        crackMask = active & abs(Y - yCrack) <= spec.crack.width_um / 2;

    otherwise
        error('Unknown geometryClass "%s".', spec.geometryClass);
end

edgeMask = active & abs(Y) >= (W/2 - spec.geom.edgeWidth_um);

% Link masks. Horizontal links connect (row,col) to (row,col+1).
activeX = active(:,1:end-1) & active(:,2:end);
activeY = active(1:end-1,:) & active(2:end,:);

midXx = 0.5 * (X(:,1:end-1) + X(:,2:end));
midYx = 0.5 * (Y(:,1:end-1) + Y(:,2:end));
midXy = 0.5 * (X(1:end-1,:) + X(2:end,:));
midYy = 0.5 * (Y(1:end-1,:) + Y(2:end,:));

regionX = region_from_midpoints(midXx, midYx, spec, activeX);
regionY = region_from_midpoints(midXy, midYy, spec, activeY);

net = struct();
net.x_um = x;
net.y_um = y;
net.X_um = X;
net.Y_um = Y;
net.active = active;
net.nominalSourceMask = nominalSourceMask;
net.nominalDrainMask = nominalDrainMask;
net.sourceMask = sourceMask;
net.drainMask = drainMask;
net.nominalProbeMasks = nominalProbeMasks;
net.probeMasks = probeMasks;
net.probeOverlap = probeOverlap;
net.coveredMask = coveredMask;
net.boundaryMask = boundaryMask;
net.crackMask = crackMask;
net.edgeMask = edgeMask;
net.link.activeX = activeX;
net.link.activeY = activeY;
net.link.regionX = regionX;
net.link.regionY = regionY;

end

function overlap = compute_probe_overlap(nominalProbeMasks, activeProbeMasks)

probeNames = fieldnames(nominalProbeMasks);
overlap = struct();

for k = 1:numel(probeNames)
    name = probeNames{k};
    nominalN = nnz(nominalProbeMasks.(name));
    activeN = nnz(activeProbeMasks.(name));
    S = struct();
    S.nominalNodes = nominalN;
    S.activeNodes = activeN;
    if nominalN > 0
        S.activeFraction = activeN / nominalN;
    else
        S.activeFraction = NaN;
    end
    overlap.(name) = S;
end

end

function warn_if_probe_clipped(spec, probeOverlap)

if ~(isfield(spec, 'flakeOutline') && isfield(spec.flakeOutline, 'enabled') && ...
        spec.flakeOutline.enabled)
    return;
end

probeNames = fieldnames(probeOverlap);
for k = 1:numel(probeNames)
    name = probeNames{k};
    S = probeOverlap.(name);
    if S.activeNodes <= 1 || S.activeFraction < 0.25
        warning(['%s %s has weak active-flake overlap: %d/%d nominal nodes ', ...
            '(%.2f). Probe geometry may be misregistered.'], ...
            spec.name, name, S.activeNodes, S.nominalNodes, S.activeFraction);
    end
end

end

function mask = ensure_probe_node(mask, active, X, Y, x0, y0)

if any(mask(:))
    return;
end

dist2 = (X - x0).^2 + (Y - y0).^2;
dist2(~active) = Inf;
[~, idx] = min(dist2(:));
mask = false(size(active));
mask(idx) = true;

end

function region = region_from_midpoints(Xm, Ym, spec, activeLink)

region = spec.region.background * ones(size(Xm));
region(~activeLink) = 0;

W = spec.geom.channelWidth_um;
edge = abs(Ym) >= (W/2 - spec.geom.edgeWidth_um);
region(edge & activeLink) = spec.region.edge;

switch spec.geometryClass
    case 'control'
        % background/edge only

    case 'full'
        region(activeLink & ~edge) = spec.region.covered;

    case 'half'
        boundary = abs(Ym) <= spec.geom.boundaryWidth_um / 2;
        switch spec.coveredSide
            case 'top'
                covered = Ym > spec.geom.boundaryWidth_um / 2;
            case 'bottom'
                covered = Ym < -spec.geom.boundaryWidth_um / 2;
        end
        region(activeLink & covered) = spec.region.covered;
        region(activeLink & boundary) = spec.region.boundary;

    case 'cracked_full'
        region(activeLink & ~edge) = spec.region.covered;
        yCrack = spec.crack.y0_um + spec.crack.slope * Xm;
        crack = abs(Ym - yCrack) <= spec.crack.width_um / 2;
        region(activeLink & crack) = spec.region.crack;
end

end
