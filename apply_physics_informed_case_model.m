function [paramsOut, caseInfo] = apply_physics_informed_case_model(net, spec, paramsIn, caseDef, seed)
%APPLY_PHYSICS_INFORMED_CASE_MODEL Apply v6.5 named physics hypotheses.

if nargin < 5 || isempty(seed)
    seed = spec.randomSeed + 6500;
end
rng(seed);

paramsOut = paramsIn;
scoreX = net.link.etaX;
scoreY = net.link.etaY;
scoreX(~net.link.activeX) = 0;
scoreY(~net.link.activeY) = 0;

domainX = false(size(net.link.activeX));
domainY = false(size(net.link.activeY));
contactX = false(size(net.link.activeX));
contactY = false(size(net.link.activeY));

if isfield(caseDef, 'contactRelaxationOnly') && caseDef.contactRelaxationOnly
    [contactX, contactY] = contact_link_masks(net, spec, caseDef.contactWidth_um);
    paramsOut = apply_contact_relaxation(paramsOut, contactX, contactY, caseDef);
else
    if strcmp(char(caseDef.domainMode), 'none')
        paramsOut = apply_smooth_case_modulation(paramsOut, net, scoreX, scoreY, caseDef, 1);
    elseif isfield(caseDef, 'backgroundGainFactor') && caseDef.backgroundGainFactor > 0
        paramsOut = apply_smooth_case_modulation(paramsOut, net, scoreX, scoreY, ...
            caseDef, caseDef.backgroundGainFactor);
    end

    switch char(caseDef.domainMode)
        case 'none'
            % smooth case only
        case 'boundary_lane'
            [domainX, domainY] = boundary_lane_domains(net, spec, caseDef);
            paramsOut = apply_domain_link_boost(paramsOut, domainX, domainY, caseDef);
        case 'crack_edge_lane'
            [domainX, domainY] = crack_edge_domains(net, spec, caseDef);
            paramsOut = apply_domain_link_boost(paramsOut, domainX, domainY, caseDef);
        otherwise
            error('Unknown physics-informed domainMode "%s".', caseDef.domainMode);
    end
end

caseInfo = struct();
caseInfo.caseID = caseDef.caseID;
caseInfo.label = caseDef.label;
caseInfo.description = caseDef.description;
caseInfo.scoreX = scoreX;
caseInfo.scoreY = scoreY;
caseInfo.domainX = domainX;
caseInfo.domainY = domainY;
caseInfo.domainNode = link_mask_to_node_mask_local(net, domainX, domainY);
caseInfo.contactX = contactX;
caseInfo.contactY = contactY;
caseInfo.contactNode = link_mask_to_node_mask_local(net, contactX, contactY);
caseInfo.domainLinkFraction = (nnz(domainX) + nnz(domainY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));
caseInfo.contactLinkFraction = (nnz(contactX) + nnz(contactY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));

paramsOut.physicsCase = caseDef.caseID;

end

function params = apply_smooth_case_modulation(params, net, scoreX, scoreY, caseDef, scaleFactor)

if nargin < 6 || isempty(scaleFactor)
    scaleFactor = 1;
end

TcGain_K = scaleFactor .* caseDef.TcGain_K;
IcMultiplier = 1 + scaleFactor .* (caseDef.IcMultiplier - 1);
residualSuppression = scaleFactor .* caseDef.residualSuppression;
RnSuppression = scaleFactor .* caseDef.RnSuppression;

params.TcX(net.link.activeX) = params.TcX(net.link.activeX) + TcGain_K .* scoreX(net.link.activeX);
params.TcY(net.link.activeY) = params.TcY(net.link.activeY) + TcGain_K .* scoreY(net.link.activeY);

params.IcX(net.link.activeX) = params.IcX(net.link.activeX) .* ...
    (1 + (IcMultiplier - 1) .* scoreX(net.link.activeX));
params.IcY(net.link.activeY) = params.IcY(net.link.activeY) .* ...
    (1 + (IcMultiplier - 1) .* scoreY(net.link.activeY));

params.fX(net.link.activeX) = params.fX(net.link.activeX) .* ...
    (1 - residualSuppression .* scoreX(net.link.activeX));
params.fY(net.link.activeY) = params.fY(net.link.activeY) .* ...
    (1 - residualSuppression .* scoreY(net.link.activeY));
params.fX = max(0, params.fX);
params.fY = max(0, params.fY);

params.RnX(net.link.activeX) = params.RnX(net.link.activeX) .* ...
    (1 - RnSuppression .* scoreX(net.link.activeX));
params.RnY(net.link.activeY) = params.RnY(net.link.activeY) .* ...
    (1 - RnSuppression .* scoreY(net.link.activeY));
params.RnX = max(params.Rfloor, params.RnX);
params.RnY = max(params.Rfloor, params.RnY);

end

function params = apply_domain_link_boost(params, domainX, domainY, caseDef)

params.TcX(domainX) = params.TcX(domainX) + caseDef.TcGain_K;
params.TcY(domainY) = params.TcY(domainY) + caseDef.TcGain_K;
params.IcX(domainX) = params.IcX(domainX) .* caseDef.IcMultiplier;
params.IcY(domainY) = params.IcY(domainY) .* caseDef.IcMultiplier;
params.fX(domainX) = params.fX(domainX) .* (1 - caseDef.residualSuppression);
params.fY(domainY) = params.fY(domainY) .* (1 - caseDef.residualSuppression);
params.RnX(domainX) = params.RnX(domainX) .* (1 - caseDef.RnSuppression);
params.RnY(domainY) = params.RnY(domainY) .* (1 - caseDef.RnSuppression);

params.fX = max(0, params.fX);
params.fY = max(0, params.fY);
params.RnX = max(params.Rfloor, params.RnX);
params.RnY = max(params.Rfloor, params.RnY);

end

function params = apply_contact_relaxation(params, contactX, contactY, caseDef)

params.TcX(contactX) = max(0.005, params.TcX(contactX) - caseDef.contactTcSuppression_K);
params.TcY(contactY) = max(0.005, params.TcY(contactY) - caseDef.contactTcSuppression_K);
params.IcX(contactX) = params.IcX(contactX) .* caseDef.contactIcMultiplier;
params.IcY(contactY) = params.IcY(contactY) .* caseDef.contactIcMultiplier;
params.fX(contactX) = min(0.98, params.fX(contactX) + caseDef.contactResidualIncrease);
params.fY(contactY) = min(0.98, params.fY(contactY) + caseDef.contactResidualIncrease);
params.RnX(contactX) = params.RnX(contactX) .* (1 + caseDef.contactRnIncrease);
params.RnY(contactY) = params.RnY(contactY) .* (1 + caseDef.contactRnIncrease);

end

function [domainX, domainY] = boundary_lane_domains(net, spec, caseDef)

[Xx, Yx] = link_midpoints(net, 'X');
[Xy, Yy] = link_midpoints(net, 'Y');

if strcmp(spec.geometryClass, 'half')
    centerY = 0;
else
    domainX = false(size(net.link.activeX));
    domainY = false(size(net.link.activeY));
    return;
end

domainX = net.link.activeX & abs(Yx - centerY) <= caseDef.laneHalfWidth_um;
domainY = net.link.activeY & abs(Yy - centerY) <= caseDef.laneHalfWidth_um;
[domainX, domainY] = apply_random_gaps(domainX, domainY, caseDef.gapProbability);

end

function [domainX, domainY] = crack_edge_domains(net, spec, caseDef)

domainX = false(size(net.link.activeX));
domainY = false(size(net.link.activeY));
if ~strcmp(spec.geometryClass, 'cracked_full') || ~isfield(spec, 'crack')
    return;
end

[Xx, Yx] = link_midpoints(net, 'X');
[Xy, Yy] = link_midpoints(net, 'Y');
yCrackX = spec.crack.y0_um + spec.crack.slope .* Xx;
yCrackY = spec.crack.y0_um + spec.crack.slope .* Xy;

dX = abs(Yx - yCrackX);
dY = abs(Yy - yCrackY);
edge0 = spec.crack.width_um / 2;
domainX = net.link.activeX & dX >= edge0 & dX <= edge0 + caseDef.laneHalfWidth_um;
domainY = net.link.activeY & dY >= edge0 & dY <= edge0 + caseDef.laneHalfWidth_um;

% Favor along-crack/current-carrying links so this case actually tests a
% crack-adjacent conductive lane rather than isolated pixels.
domainY = domainY & rand(size(domainY)) > 0.50;
[domainX, domainY] = apply_random_gaps(domainX, domainY, caseDef.gapProbability);

end

function [maskX, maskY] = apply_random_gaps(maskX, maskY, gapProbability)

if gapProbability <= 0
    return;
end
maskX = maskX & rand(size(maskX)) > gapProbability;
maskY = maskY & rand(size(maskY)) > gapProbability;

end

function [maskX, maskY] = contact_link_masks(net, spec, width_um)

[Xx, Yx] = link_midpoints(net, 'X');
[Xy, Yy] = link_midpoints(net, 'Y');
centers = contact_centers(spec);

maskX = false(size(net.link.activeX));
maskY = false(size(net.link.activeY));
for k = 1:size(centers, 1)
    maskX = maskX | hypot(Xx - centers(k,1), Yx - centers(k,2)) <= width_um;
    maskY = maskY | hypot(Xy - centers(k,1), Yy - centers(k,2)) <= width_um;
end
maskX = maskX & net.link.activeX;
maskY = maskY & net.link.activeY;

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
centers = [-L/2 0; L/2 0; xL yT; xR yT; xL yB; xR yB];

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

function nodeMask = link_mask_to_node_mask_local(net, maskX, maskY)

nodeMask = false(size(net.active));
[Ny, Nx] = size(net.active);
for row = 1:Ny
    for col = 1:Nx-1
        if maskX(row,col)
            nodeMask(row,col) = true;
            nodeMask(row,col+1) = true;
        end
    end
end
for row = 1:Ny-1
    for col = 1:Nx
        if maskY(row,col)
            nodeMask(row,col) = true;
            nodeMask(row+1,col) = true;
        end
    end
end
nodeMask = nodeMask & net.active;

end
