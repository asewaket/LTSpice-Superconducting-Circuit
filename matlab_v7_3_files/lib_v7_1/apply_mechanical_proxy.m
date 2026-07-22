function net = apply_mechanical_proxy(net, spec, model, mode)
%APPLY_MECHANICAL_PROXY Build normalized eta fields from geometry/stressor masks.
%
% eta is a mechanical-response proxy, not a calibrated strain field. It is
% constructed from independently specified geometry: stressor coverage,
% half-coverage boundary, crack mask, edge/interface regions, and film force.

if nargin < 4
    mode = 'full';
end

amp = min(1, abs(spec.filmForce_Npm) / model.proxy.forceScale_Npm);
eta = zeros(size(net.active));

switch spec.geometryClass
    case 'control'
        eta(:) = 0;

    case 'full'
        eta(net.coveredMask) = amp * model.proxy.fullCoverageWeight;

    case 'half'
        eta(net.coveredMask) = amp * model.proxy.coveredWeight;
        eta(net.boundaryMask) = amp * model.proxy.boundaryWeight;

    case 'cracked_full'
        eta(net.coveredMask) = amp * model.proxy.fullCoverageWeight;
        eta(net.crackMask) = max(eta(net.crackMask), amp * model.proxy.crackWeight);
end

eta(net.edgeMask) = max(eta(net.edgeMask), amp * model.proxy.edgeWeight);

if strcmp(mode, 'crack_off') && strcmp(spec.geometryClass, 'cracked_full')
    eta(net.crackMask) = amp * model.proxy.fullCoverageWeight;
end

sigmaCells = max(1, round(model.proxy.smooth_um / spec.grid.dx_um));
if any(eta(:) ~= 0)
    etaSmooth = gaussian_smooth_field(eta, sigmaCells);
    maxBefore = max(eta(:));
    if max(etaSmooth(:)) > 0
        eta = etaSmooth * (maxBefore / max(etaSmooth(:)));
    else
        eta = etaSmooth;
    end
end

eta = min(model.proxy.clipMax, max(model.proxy.clipMin, eta));

% Link eta is the average of the two endpoint eta values.
etaX = 0.5 * (eta(:,1:end-1) + eta(:,2:end));
etaY = 0.5 * (eta(1:end-1,:) + eta(2:end,:));
etaX(~net.link.activeX) = 0;
etaY(~net.link.activeY) = 0;

if strcmp(mode, 'uniform')
    vals = [etaX(net.link.activeX); etaY(net.link.activeY)];
    if ~isempty(vals)
        etaMean = mean(vals);
        etaX(net.link.activeX) = etaMean;
        etaY(net.link.activeY) = etaMean;
        eta(net.active) = etaMean;
    end
elseif strcmp(mode, 'random_eta')
    etaX = shuffle_valid_values(etaX, net.link.activeX);
    etaY = shuffle_valid_values(etaY, net.link.activeY);
end

net.etaNode = eta;
net.link.etaX = etaX;
net.link.etaY = etaY;
net.proxyMode = mode;

end

function out = gaussian_smooth_field(in, sigmaCells)

sigmaCells = max(1, sigmaCells);
radius = max(2, ceil(3 * sigmaCells));
x = -radius:radius;
g = exp(-(x.^2) / (2 * sigmaCells^2));
g = g / sum(g);
out = conv2(conv2(in, g, 'same'), g', 'same');

end

function a = shuffle_valid_values(a, valid)

vals = a(valid);
vals = vals(randperm(numel(vals)));
a(valid) = vals;

end
