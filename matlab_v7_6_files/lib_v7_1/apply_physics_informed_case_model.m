function [paramsOut, caseInfo] = apply_physics_informed_case_model(net, spec, paramsIn, caseDef, seed)
%APPLY_PHYSICS_INFORMED_CASE_MODEL Apply v6.7 named physics hypotheses.

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
effectX = zeros(size(net.link.activeX));
effectY = zeros(size(net.link.activeY));
effectLabel = 'case effect';

if isfield(caseDef, 'contactRelaxationOnly') && caseDef.contactRelaxationOnly
    [contactX, contactY] = contact_link_masks(net, spec, caseDef.contactWidth_um);
    paramsOut = apply_contact_relaxation(paramsOut, contactX, contactY, caseDef);
    effectX = double(contactX);
    effectY = double(contactY);
    effectLabel = 'contact-relaxation mask';
else
    if strcmp(char(caseDef.domainMode), 'none')
        paramsOut = apply_smooth_case_modulation(paramsOut, net, scoreX, scoreY, caseDef, 1);
        [effectX, effectY, effectLabel] = smooth_effect_maps(scoreX, scoreY, caseDef, 1);
    elseif isfield(caseDef, 'backgroundGainFactor') && caseDef.backgroundGainFactor > 0
        paramsOut = apply_smooth_case_modulation(paramsOut, net, scoreX, scoreY, ...
            caseDef, caseDef.backgroundGainFactor);
        [effectX, effectY, effectLabel] = smooth_effect_maps(scoreX, scoreY, ...
            caseDef, caseDef.backgroundGainFactor);
    end

    switch char(caseDef.domainMode)
        case 'none'
            % smooth case only
        case 'boundary_lane'
            [domainX, domainY] = boundary_lane_domains(net, spec, caseDef);
            paramsOut = apply_domain_link_boost(paramsOut, domainX, domainY, caseDef);
            effectX = max(effectX, double(domainX));
            effectY = max(effectY, double(domainY));
            effectLabel = 'boundary-lane domain mask';
        case 'crack_edge_lane'
            [domainX, domainY] = crack_edge_domains(net, spec, caseDef);
            paramsOut = apply_domain_link_boost(paramsOut, domainX, domainY, caseDef);
            effectX = max(effectX, double(domainX));
            effectY = max(effectY, double(domainY));
            effectLabel = 'crack-edge domain mask';
        case 'interrupted_boundary_lane'
            [domainX, domainY] = interrupted_boundary_lane_domains(net, spec, caseDef);
            paramsOut = apply_domain_link_boost(paramsOut, domainX, domainY, caseDef);
            effectX = max(effectX, double(domainX));
            effectY = max(effectY, double(domainY));
            effectLabel = 'interrupted boundary-lane mask';
        case 'weak_boundary_channel'
            [domainX, domainY] = boundary_lane_domains(net, spec, caseDef);
            paramsOut = apply_weak_boundary_channel(paramsOut, domainX, domainY, caseDef);
            effectX = max(effectX, double(domainX));
            effectY = max(effectY, double(domainY));
            effectLabel = 'weak boundary-channel transparency map';
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
caseInfo.effectX = effectX;
caseInfo.effectY = effectY;
caseInfo.effectNode = link_value_to_node_map(net, effectX, effectY);
caseInfo.effectLabel = effectLabel;
caseInfo.domainLinkFraction = (nnz(domainX) + nnz(domainY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));
caseInfo.contactLinkFraction = (nnz(contactX) + nnz(contactY)) ./ ...
    max(1, nnz(net.link.activeX) + nnz(net.link.activeY));

paramsOut.physicsCase = caseDef.caseID;

end

function [effectX, effectY, effectLabel] = smooth_effect_maps(scoreX, scoreY, caseDef, scaleFactor)

effectX = zeros(size(scoreX));
effectY = zeros(size(scoreY));
effectLabel = 'smooth parameter-modulation strength';

if strcmp(caseDef.caseID, 'baseline_smooth')
    effectLabel = 'baseline: no additional v6.7 case mask';
    return;
end

amp = abs(scaleFactor .* caseDef.TcGain_K) + ...
    abs(scaleFactor .* (caseDef.IcMultiplier - 1)) + ...
    abs(scaleFactor .* caseDef.residualSuppression) + ...
    abs(scaleFactor .* caseDef.RnSuppression);
if amp <= 0
    return;
end

effectX = scoreX;
effectY = scoreY;
switch caseDef.caseID
    case 'case_A_inplane_Tc'
        effectLabel = 'Tc-boost map from in-plane Raman';
    case 'case_B_outofplane_weaklinks'
        effectLabel = 'weak-link/residual modulation from out-of-plane Raman';
    otherwise
        effectLabel = 'smooth case modulation map';
end

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

function params = apply_weak_boundary_channel(params, domainX, domainY, caseDef)

params = apply_domain_link_boost(params, domainX, domainY, caseDef);

% Unlike a binary superconducting lane, Case G preserves finite weak-link
% resistance. This prevents a forced zero-resistance path while allowing an
% extended channel to carry current with broad/residual behavior.
params.fX(domainX) = max(params.fX(domainX), caseDef.weakChannelResidualFloor);
params.fY(domainY) = max(params.fY(domainY), caseDef.weakChannelResidualFloor);
params.RnX(domainX) = params.RnX(domainX) .* caseDef.weakChannelRnMultiplier;
params.RnY(domainY) = params.RnY(domainY) .* caseDef.weakChannelRnMultiplier;
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

function [domainX, domainY] = interrupted_boundary_lane_domains(net, spec, caseDef)

[domainX, domainY] = boundary_lane_domains(net, spec, caseDef);
if ~any(domainX(:)) && ~any(domainY(:))
    return;
end

[Xx, Yx] = link_midpoints(net, 'X');
[Xy, Yy] = link_midpoints(net, 'Y');

% Create deterministic interruptions near voltage probes/current contacts and
% one central gap. This tests AS006-like strong-but-incomplete lanes.
centers = contact_centers(spec);
gapCentersX = [centers(:,1); 0];
for k = 1:numel(gapCentersX)
    w = caseDef.interruptionWidth_um;
    if k <= size(centers, 1)
        w = max(w, caseDef.contactGapWidth_um);
    end
    domainX = domainX & abs(Xx - gapCentersX(k)) > w;
    domainY = domainY & abs(Xy - gapCentersX(k)) > w;
end

% Preserve small islands inside the lane with a mild eta preference; this
% gives a broken-lane morphology rather than a perfectly erased stripe.
etaX = net.link.etaX;
etaY = net.link.etaY;
domainX = domainX | (net.link.activeX & abs(Yx) <= 0.35 * caseDef.laneHalfWidth_um & etaX > 0.70);
domainY = domainY | (net.link.activeY & abs(Yy) <= 0.35 * caseDef.laneHalfWidth_um & etaY > 0.70);

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

function nodeMap = link_value_to_node_map(net, valueX, valueY)

nodeMap = zeros(size(net.active));
count = zeros(size(net.active));
[Ny, Nx] = size(net.active);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            v = valueX(row,col);
            nodeMap(row,col) = nodeMap(row,col) + v;
            nodeMap(row,col+1) = nodeMap(row,col+1) + v;
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end

for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            v = valueY(row,col);
            nodeMap(row,col) = nodeMap(row,col) + v;
            nodeMap(row+1,col) = nodeMap(row+1,col) + v;
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

valid = count > 0;
nodeMap(valid) = nodeMap(valid) ./ count(valid);
nodeMap(~net.active) = NaN;
if any(valid(:))
    mx = max(nodeMap(valid), [], 'omitnan');
    if isfinite(mx) && mx > 0
        nodeMap(valid) = nodeMap(valid) ./ mx;
    end
end

end
