function spec = make_coarse_device_spec(deviceName, nLongitudinal, nLateral)
%MAKE_COARSE_DEVICE_SPEC Return spec with a small effective-domain grid.
%
% This is for robustness checks such as 3x3, 4x4, and 5x5 networks. The
% network should be interpreted as a coarse-grained domain/weak-link topology,
% not as a literal physical mesh of microscopic resistors.

spec = make_device_spec(deviceName);

if nLongitudinal < 2 || nLateral < 2
    error('Coarse network dimensions must be at least 2 by 2.');
end

spec.grid.dx_um = spec.geom.activeLength_um / (nLongitudinal - 1);
spec.grid.dy_um = spec.geom.channelWidth_um / (nLateral - 1);

xNodes = linspace(-spec.geom.activeLength_um/2, spec.geom.activeLength_um/2, nLongitudinal);
yNodes = linspace(-spec.geom.channelWidth_um/2, spec.geom.channelWidth_um/2, nLateral);

if nLongitudinal <= 3
    spec.geom.probeXLeft_um = xNodes(1);
    spec.geom.probeXRight_um = xNodes(end);
else
    spec.geom.probeXLeft_um = xNodes(2);
    spec.geom.probeXRight_um = xNodes(end-1);
end

if nLateral <= 3
    spec.geom.probeYBottom_um = yNodes(1);
    spec.geom.probeYTop_um = yNodes(end);
else
    spec.geom.probeYBottom_um = yNodes(2);
    spec.geom.probeYTop_um = yNodes(end-1);
end

spec.coarseGrid.nLongitudinal = nLongitudinal;
spec.coarseGrid.nLateral = nLateral;
spec.coarseGrid.label = sprintf('%dx%d coarse domain network', nLateral, nLongitudinal);

end
