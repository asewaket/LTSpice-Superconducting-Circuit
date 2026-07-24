function [netOut, pdeMap] = apply_pde_proxy_to_network(netIn, spec, modelParams, pde, opts)
%APPLY_PDE_PROXY_TO_NETWORK Map PDE displacement/strain proxy onto network eta.
%
% This is the key v7 bridge: a PDE-generated spatial field replaces the v6
% hand-built mechanical proxy before assigning resistor-link parameters.

if nargin < 5 || isempty(opts)
    opts = make_v7_pde_options(spec);
end

netOut = netIn;

[Ux, Uy] = interpolate_pde_displacement_to_grid(pde, netIn.X_um, netIn.Y_um);
[exx, eyy, exy] = grid_strain_from_displacement(Ux, Uy, netIn.x_um, netIn.y_um);

principal = principal_tensile_strain(exx, eyy, exy);
strainProxy = normalize_field(abs(principal), netIn.active);
dispProxy = normalize_field(hypot(Ux, Uy), netIn.active);

contactMask = make_v7_contact_relaxation_mask(netIn, spec, opts);
stressorMask = make_v7_stressor_mask(netIn, spec);
boundaryMask = double(netIn.boundaryMask);

etaRaw = opts.map.strainWeight .* strainProxy + ...
    opts.map.displacementWeight .* dispProxy + ...
    opts.map.boundaryWeight .* boundaryMask + ...
    opts.map.stressorMaskWeight .* stressorMask - ...
    opts.map.contactSuppressionWeight .* contactMask;

etaRaw(~netIn.active) = NaN;
etaRaw = smooth_nan_field(etaRaw, opts.map.smoothSigma_um, spec.grid.dx_um);
etaNode = normalize_field(etaRaw, netIn.active);
etaNode = min(opts.map.clipMax, max(opts.map.clipMin, etaNode));
etaNode(~netIn.active) = 0;

etaX = 0.5 * (etaNode(:,1:end-1) + etaNode(:,2:end));
etaY = 0.5 * (etaNode(1:end-1,:) + etaNode(2:end,:));
etaX(~netIn.link.activeX) = 0;
etaY(~netIn.link.activeY) = 0;

netOut.etaNode = etaNode;
netOut.link.etaX = etaX;
netOut.link.etaY = etaY;
netOut.proxyMode = 'v7_pde';

pdeMap = struct();
pdeMap.Ux = Ux;
pdeMap.Uy = Uy;
pdeMap.exx = exx;
pdeMap.eyy = eyy;
pdeMap.exy = exy;
pdeMap.principalTensileStrain = principal;
pdeMap.strainProxy = strainProxy;
pdeMap.displacementProxy = dispProxy;
pdeMap.contactRelaxationMask = contactMask;
pdeMap.stressorMask = stressorMask;
pdeMap.boundaryMask = boundaryMask;
pdeMap.etaRaw = etaRaw;
pdeMap.etaNode = etaNode;
pdeMap.etaX = etaX;
pdeMap.etaY = etaY;
pdeMap.pdeDescription = pde.description;
pdeMap.mappingNote = ['v7.1 normalized PDE proxy: outline-aware strain/displacement plus ', ...
    'stressor and boundary masks, suppressed near metal contacts/probes.'];

end

function [Ux, Uy] = interpolate_pde_displacement_to_grid(pde, Xq, Yq)

nodes = pde.mesh.Nodes;
ux = pde.solution.Displacement.ux;
uy = pde.solution.Displacement.uy;

Fx = scatteredInterpolant(nodes(1,:)', nodes(2,:)', ux(:), 'natural', 'nearest');
Fy = scatteredInterpolant(nodes(1,:)', nodes(2,:)', uy(:), 'natural', 'nearest');

Ux = Fx(Xq, Yq);
Uy = Fy(Xq, Yq);

end

function [exx, eyy, exy] = grid_strain_from_displacement(Ux, Uy, x, y)

dx = mean(diff(x));
dy = mean(diff(y));

[dUx_dy, dUx_dx] = gradient(Ux, dy, dx);
[dUy_dy, dUy_dx] = gradient(Uy, dy, dx);

exx = dUx_dx;
eyy = dUy_dy;
exy = 0.5 * (dUx_dy + dUy_dx);

end

function e1 = principal_tensile_strain(exx, eyy, exy)

traceTerm = 0.5 * (exx + eyy);
rad = sqrt((0.5 * (exx - eyy)).^2 + exy.^2);
e1 = traceTerm + rad;

end

function mask = make_v7_stressor_mask(net, spec)

mask = double(net.coveredMask);
if strcmp(spec.geometryClass, 'half')
    mask(net.boundaryMask) = max(mask(net.boundaryMask), 0.70);
end
if strcmp(spec.geometryClass, 'cracked_full')
    mask(net.crackMask) = max(mask(net.crackMask), 0.85);
end
mask(~net.active) = 0;

end

function mask = make_v7_contact_relaxation_mask(net, spec, opts)

mask = zeros(size(net.active));

% Source and drain support/contact regions.
mask(net.sourceMask | net.drainMask) = 1.0;

probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    p = net.probeMasks.(probeNames{k});
    mask(p) = max(mask(p), 0.90);
end

sigmaCells = max(1, round(opts.contact.gaussianSigma_um / spec.grid.dx_um));
mask = gaussian_smooth_field_local(mask, sigmaCells);
mask = normalize_field(mask, net.active);
mask(~net.active) = 0;

end

function out = smooth_nan_field(in, sigma_um, dx_um)

sigmaCells = max(1, round(sigma_um / dx_um));
valid = isfinite(in);
work = in;
work(~valid) = 0;
weight = double(valid);

num = gaussian_smooth_field_local(work, sigmaCells);
den = gaussian_smooth_field_local(weight, sigmaCells);
out = num ./ max(den, eps);
out(~valid) = NaN;

end

function out = gaussian_smooth_field_local(in, sigmaCells)

radius = max(2, ceil(3 * sigmaCells));
x = -radius:radius;
g = exp(-(x.^2) / (2 * sigmaCells^2));
g = g ./ sum(g);
out = conv2(conv2(in, g, 'same'), g', 'same');

end

function out = normalize_field(in, active)

out = in;
vals = out(active & isfinite(out));
if isempty(vals)
    out(active) = 0;
    out(~active) = 0;
    return;
end

lo = min(vals);
hi = max(vals);
if hi > lo
    out = (out - lo) ./ (hi - lo);
else
    out(active) = 0;
end
out(~active) = 0;
out(~isfinite(out)) = 0;

end
