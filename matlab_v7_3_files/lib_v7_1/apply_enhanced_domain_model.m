function [paramsOut, domainInfo] = apply_enhanced_domain_model(net, spec, paramsIn, domainOpts, seed)
%APPLY_ENHANCED_DOMAIN_MODEL Nucleate thresholded enhanced SC domains.
%
% The smooth v6.3 Raman model changes local parameters continuously. This
% v6.4 layer asks whether a high-proxy region must instead create a linked
% population of enhanced superconducting bonds with larger Tc/Ic and smaller
% residual resistance.

if nargin < 5 || isempty(seed)
    seed = spec.randomSeed + 6400;
end

paramsOut = paramsIn;
domainInfo = initialize_domain_info(net, domainOpts);

if ~isfield(domainOpts, 'enabled') || ~domainOpts.enabled
    return;
end

rng(seed);

[scoreX, supportX] = link_domain_score(net, spec, 'X', domainOpts);
[scoreY, supportY] = link_domain_score(net, spec, 'Y', domainOpts);

pX = domain_probability(scoreX, supportX, domainOpts);
pY = domain_probability(scoreY, supportY, domainOpts);

randX = correlated_uniform(size(pX), domainOpts.correlation_um, spec.grid.dx_um);
randY = correlated_uniform(size(pY), domainOpts.correlation_um, spec.grid.dy_um);

domainX = net.link.activeX & randX <= pX;
domainY = net.link.activeY & randY <= pY;

paramsOut.TcX(domainX) = paramsOut.TcX(domainX) + domainOpts.TcBoost_K;
paramsOut.TcY(domainY) = paramsOut.TcY(domainY) + domainOpts.TcBoost_K;

paramsOut.IcX(domainX) = paramsOut.IcX(domainX) .* domainOpts.IcMultiplier;
paramsOut.IcY(domainY) = paramsOut.IcY(domainY) .* domainOpts.IcMultiplier;

paramsOut.fX(domainX) = max(0, paramsOut.fX(domainX) .* domainOpts.residualMultiplier);
paramsOut.fY(domainY) = max(0, paramsOut.fY(domainY) .* domainOpts.residualMultiplier);

paramsOut.RnX(domainX) = paramsOut.RnX(domainX) .* domainOpts.RnMultiplier;
paramsOut.RnY(domainY) = paramsOut.RnY(domainY) .* domainOpts.RnMultiplier;

domainInfo.scoreX = scoreX;
domainInfo.scoreY = scoreY;
domainInfo.supportX = supportX;
domainInfo.supportY = supportY;
domainInfo.probabilityX = pX;
domainInfo.probabilityY = pY;
domainInfo.domainX = domainX;
domainInfo.domainY = domainY;
domainInfo.domainNode = link_mask_to_node_mask(net, domainX, domainY);
domainInfo.domainLinkFraction = (nnz(domainX) + nnz(domainY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));
domainInfo.meanProbability = mean([pX(net.link.activeX); pY(net.link.activeY)], 'omitnan');

paramsOut.domainModel = domainOpts.name;

end

function info = initialize_domain_info(net, opts)

info = struct();
info.options = opts;
info.scoreX = zeros(size(net.link.activeX));
info.scoreY = zeros(size(net.link.activeY));
info.supportX = zeros(size(net.link.activeX));
info.supportY = zeros(size(net.link.activeY));
info.probabilityX = zeros(size(net.link.activeX));
info.probabilityY = zeros(size(net.link.activeY));
info.domainX = false(size(net.link.activeX));
info.domainY = false(size(net.link.activeY));
info.domainNode = false(size(net.active));
info.domainLinkFraction = 0;
info.meanProbability = 0;

end

function [score, support] = link_domain_score(net, spec, family, opts)

switch family
    case 'X'
        eta = net.link.etaX;
        active = net.link.activeX;
        support = node_field_to_link(net, 'etaNodeRamanSupport', 'X');
        [Xm, Ym] = link_midpoints(net, 'X');
    case 'Y'
        eta = net.link.etaY;
        active = net.link.activeY;
        support = node_field_to_link(net, 'etaNodeRamanSupport', 'Y');
        [Xm, Ym] = link_midpoints(net, 'Y');
end

if isempty(support)
    support = double(active);
end
support(~active) = 0;
support(~isfinite(support)) = 0;
support = min(1, max(0, support));

relax = contact_relaxation_factor(Xm, Ym, spec, opts);
score = eta .* relax;

if strcmp(spec.geometryClass, 'cracked_full') && isfield(spec, 'crack')
    yCrack = spec.crack.y0_um + spec.crack.slope .* Xm;
    dCrack = abs(Ym - yCrack);
    crackEdge = dCrack <= opts.crackEdgeWidth_um;
    score(crackEdge & active) = min(1, score(crackEdge & active) + opts.crackProbabilityBoost);
end

score(~active) = 0;
score(~isfinite(score)) = 0;

end

function p = domain_probability(score, support, opts)

p = opts.maxProbability ./ (1 + exp(-(score - opts.etaThreshold) ./ opts.etaWidth));
p = p .* (opts.supportFloor + (1 - opts.supportFloor) .* support);
p(~isfinite(p)) = 0;
p = min(1, max(0, p));

end

function u = correlated_uniform(sz, correlation_um, d_um)

corrCells = max(1, round(correlation_um ./ max(eps, d_um)));
field = smooth_random_field(randn(sz), corrCells);
mn = min(field(:));
mx = max(field(:));
if mx > mn
    u = (field - mn) ./ (mx - mn);
else
    u = rand(sz);
end

end

function linkField = node_field_to_link(net, fieldName, family)

if ~isfield(net, fieldName)
    linkField = [];
    return;
end

nodeField = net.(fieldName);
switch family
    case 'X'
        linkField = 0.5 * (nodeField(:,1:end-1) + nodeField(:,2:end));
    case 'Y'
        linkField = 0.5 * (nodeField(1:end-1,:) + nodeField(2:end,:));
end

end

function relax = contact_relaxation_factor(Xm, Ym, spec, opts)

relax = ones(size(Xm));
if opts.contactRelaxStrength <= 0
    return;
end

sigma = max(0.05, opts.contactRelaxWidth_um);
centers = contact_centers(spec);
d2min = inf(size(Xm));
for k = 1:size(centers, 1)
    d2 = (Xm - centers(k,1)).^2 + (Ym - centers(k,2)).^2;
    d2min = min(d2min, d2);
end
suppression = exp(-d2min ./ (2 * sigma^2));
relax = 1 - opts.contactRelaxStrength .* suppression;
relax = max(0, min(1, relax));

end

function centers = contact_centers(spec)

L = spec.geom.activeLength_um;
W = spec.geom.channelWidth_um;

if isfield(spec.geom, 'probeXLeft_um')
    xL = spec.geom.probeXLeft_um;
    xR = spec.geom.probeXRight_um;
else
    xL = -spec.geom.probeSpacing_um / 2;
    xR = spec.geom.probeSpacing_um / 2;
end

if isfield(spec.geom, 'probeYTop_um')
    yT = spec.geom.probeYTop_um;
    yB = spec.geom.probeYBottom_um;
else
    yT = 0.32 * W;
    yB = -0.32 * W;
end

centers = [ ...
    -L/2, 0; ...
     L/2, 0; ...
     xL, yT; ...
     xR, yT; ...
     xL, yB; ...
     xR, yB];

end

function [Xm, Ym] = link_midpoints(net, family)

switch family
    case 'X'
        Xm = 0.5 * (net.X_um(:,1:end-1) + net.X_um(:,2:end));
        Ym = 0.5 * (net.Y_um(:,1:end-1) + net.Y_um(:,2:end));
    case 'Y'
        Xm = 0.5 * (net.X_um(1:end-1,:) + net.X_um(2:end,:));
        Ym = 0.5 * (net.Y_um(1:end-1,:) + net.Y_um(2:end,:));
end

end

function nodeMask = link_mask_to_node_mask(net, domainX, domainY)

nodeMask = false(size(net.active));
[Ny, Nx] = size(net.active);

for row = 1:Ny
    for col = 1:Nx-1
        if domainX(row,col)
            nodeMask(row,col) = true;
            nodeMask(row,col+1) = true;
        end
    end
end

for row = 1:Ny-1
    for col = 1:Nx
        if domainY(row,col)
            nodeMask(row,col) = true;
            nodeMask(row+1,col) = true;
        end
    end
end

nodeMask = nodeMask & net.active;

end
