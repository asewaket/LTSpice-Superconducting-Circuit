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

sourceMask = active & X <= min(x) + spec.geom.currentContactDepth_um;
drainMask = active & X >= max(x) - spec.geom.currentContactDepth_um;

probeHalfX = spec.geom.probeWidth_um / 2;
probeHalfY = max(0.35, 0.75 * spec.geom.probeWidth_um);
probeXLeft = -spec.geom.probeSpacing_um / 2;
probeXRight = spec.geom.probeSpacing_um / 2;
probeYTop = 0.32 * W;
probeYBottom = -0.32 * W;

probeMasks = struct();
probeMasks.P4  = active & abs(X - probeXLeft)  <= probeHalfX & abs(Y - probeYTop)    <= probeHalfY;
probeMasks.P10 = active & abs(X - probeXRight) <= probeHalfX & abs(Y - probeYTop)    <= probeHalfY;
probeMasks.P3  = active & abs(X - probeXLeft)  <= probeHalfX & abs(Y - probeYBottom) <= probeHalfY;
probeMasks.P9  = active & abs(X - probeXRight) <= probeHalfX & abs(Y - probeYBottom) <= probeHalfY;

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
net.sourceMask = sourceMask;
net.drainMask = drainMask;
net.probeMasks = probeMasks;
net.coveredMask = coveredMask;
net.boundaryMask = boundaryMask;
net.crackMask = crackMask;
net.edgeMask = edgeMask;
net.link.activeX = activeX;
net.link.activeY = activeY;
net.link.regionX = regionX;
net.link.regionY = regionY;

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

