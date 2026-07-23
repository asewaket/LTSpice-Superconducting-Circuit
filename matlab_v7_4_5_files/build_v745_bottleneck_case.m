function [netCase, paramsCase, weak] = build_v745_bottleneck_case(netBase, spec, ...
    paramsBase, caseInfo, opts, calibrationMode, fullNormalScale)
%BUILD_V745_BOTTLENECK_CASE Apply one physical bottleneck W_ij case.
%
% calibrationMode:
%   "shape"       independently recalibrates this ablation to target R_N.
%   "conductance" applies the combined-bottleneck normal-state scale unchanged.

if nargin < 6 || strlength(string(calibrationMode)) == 0
    calibrationMode = "shape";
end
if nargin < 7
    fullNormalScale = NaN;
end

netCase = netBase;
if strcmp(caseInfo.topology, "central_lane")
    netCase = apply_ablation_mode(netCase, spec, 'central_lane');
end

[WX, WY, weak] = make_v745_bottleneck_field(netBase, spec, caseInfo, opts);
weak.calibrationMode = string(calibrationMode);

paramsCase = paramsBase;
paramsCase.WX = WX;
paramsCase.WY = WY;
paramsCase.weakLinkMaskX = WX < 0.999 & netBase.link.activeX;
paramsCase.weakLinkMaskY = WY < 0.999 & netBase.link.activeY;

if opts.applyWtoRn
    paramsCase.RnX = paramsCase.RnX ./ max(WX, eps);
    paramsCase.RnY = paramsCase.RnY ./ max(WY, eps);
end
if opts.applyWtoIc
    paramsCase.IcX = paramsCase.IcX .* WX;
    paramsCase.IcY = paramsCase.IcY .* WY;
end

switch string(calibrationMode)
    case "shape"
        paramsCase = calibrate_normal_resistance(netCase, spec, paramsCase);
        weak.normalScaleApplied = paramsCase.normalScale;
        weak.calibrationDescription = "shape-controlled: each ablation recalibrated to target R_N";
    case "conductance"
        if ~(isfinite(fullNormalScale) && fullNormalScale > 0)
            error('A finite fullNormalScale is required for conductance-preserving calibration.');
        end
        paramsCase.RnX = paramsCase.RnX .* fullNormalScale;
        paramsCase.RnY = paramsCase.RnY .* fullNormalScale;
        paramsCase.normalScale = fullNormalScale;
        weak.normalScaleApplied = fullNormalScale;
        weak.calibrationDescription = "conductance-preserving: combined-bottleneck R_N scale applied unchanged";
    otherwise
        error('Unknown calibrationMode "%s".', calibrationMode);
end

weak.activeLinkFraction = (nnz(paramsCase.weakLinkMaskX & netCase.link.activeX) + ...
    nnz(paramsCase.weakLinkMaskY & netCase.link.activeY)) ./ ...
    max(1, nnz(netCase.link.activeX) + nnz(netCase.link.activeY));
weak.nodeMap = link_to_node_fraction_local(netCase, ...
    paramsCase.weakLinkMaskX, paramsCase.weakLinkMaskY);
weak.scoreMap = link_score_to_node_mean_local(netCase, weak.scoreX, weak.scoreY);

end

function [WX, WY, weak] = make_v745_bottleneck_field(net, spec, caseInfo, opts)

WX = ones(size(net.link.activeX));
WY = ones(size(net.link.activeY));

weak = struct();
weak.version = opts.version;
weak.caseName = string(caseInfo.name);
weak.description = string(caseInfo.description);
weak.topology = string(caseInfo.topology);
weak.gammaW = caseInfo.gammaW;
weak.pW = caseInfo.pW;
weak.definition = ['v7.4.5 physical bottleneck W_ij ablation: weak-link ', ...
    'transparency is the only ablated weak-link variable.'];

if strcmp(caseInfo.topology, "none") || ~isfinite(caseInfo.gammaW) || caseInfo.pW <= 0
    weak.maskX = false(size(net.link.activeX));
    weak.maskY = false(size(net.link.activeY));
    weak.scoreX = zeros(size(net.link.activeX));
    weak.scoreY = zeros(size(net.link.activeY));
    weak.meanW = 1;
    weak.histogramPreserved = false;
    return;
end

scores = v745_physical_bottleneck_scores(net, spec, opts);

switch string(caseInfo.topology)
    case {"combined","central_lane","uniform","shuffled"}
        scoreX = scores.combinedX;
        scoreY = scores.combinedY;
    case "boundary_lane"
        scoreX = scores.boundaryX;
        scoreY = scores.boundaryY;
    case "contact_relaxation"
        scoreX = scores.contactX;
        scoreY = scores.contactY;
    case "current_crowding"
        scoreX = scores.crowdingX;
        scoreY = scores.crowdingY;
    case "tear_lane"
        scoreX = scores.tearX;
        scoreY = scores.tearY;
    case "anisotropic"
        scoreX = scores.combinedX .* opts.anisotropyFactorX;
        scoreY = scores.combinedY .* caseInfo.anisotropyFactor;
    otherwise
        scoreX = scores.combinedX;
        scoreY = scores.combinedY;
end

[maskX, maskY] = select_v745_mask(scoreX, scoreY, net, caseInfo.pW);
gammaX = caseInfo.gammaW;
gammaY = caseInfo.gammaW;
if strcmp(caseInfo.topology, "anisotropic")
    gammaY = max(eps, caseInfo.gammaW .* caseInfo.anisotropyFactor);
end
WX(maskX) = gammaX;
WY(maskY) = gammaY;

if strcmp(caseInfo.topology, "uniform")
    meanW = mean([WX(net.link.activeX); WY(net.link.activeY)], 'omitnan');
    WX(net.link.activeX) = meanW;
    WY(net.link.activeY) = meanW;
    maskX = WX < 0.999 & net.link.activeX;
    maskY = WY < 0.999 & net.link.activeY;
elseif strcmp(caseInfo.topology, "shuffled")
    [WX, WY, maskX, maskY] = shuffle_w_values(WX, WY, net, spec.randomSeed + opts.seedOffset);
end

weak.maskX = maskX;
weak.maskY = maskY;
weak.scoreX = scoreX;
weak.scoreY = scoreY;
weak.meanW = mean([WX(net.link.activeX); WY(net.link.activeY)], 'omitnan');
weak.minW = min([WX(net.link.activeX); WY(net.link.activeY)], [], 'omitnan');
weak.gammaW_X = gammaX;
weak.gammaW_Y = gammaY;
weak.histogramPreserved = any(strcmp(caseInfo.topology, ["combined","shuffled","central_lane"]));

end

function scores = v745_physical_bottleneck_scores(net, spec, opts)

[midXx, midYx, midXy, midYy] = link_midpoints_local(net);

boundaryX = exp(-(midYx ./ opts.boundaryLaneWidth_um).^2);
boundaryY = exp(-(midYy ./ opts.boundaryLaneWidth_um).^2);
boundaryX = opts.boundaryWeight .* boundaryX;
boundaryY = opts.boundaryWeight .* boundaryY;

if isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'bottom')
    edgeX = opts.coveredEdgeWeight .* max(0, -midYx ./ max(abs(min(net.y_um)), eps));
    edgeY = opts.coveredEdgeWeight .* max(0, -midYy ./ max(abs(min(net.y_um)), eps));
elseif isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'top')
    edgeX = opts.coveredEdgeWeight .* max(0, midYx ./ max(abs(max(net.y_um)), eps));
    edgeY = opts.coveredEdgeWeight .* max(0, midYy ./ max(abs(max(net.y_um)), eps));
else
    edgeX = zeros(size(boundaryX));
    edgeY = zeros(size(boundaryY));
end

contactX = zeros(size(boundaryX));
contactY = zeros(size(boundaryY));
crowdingX = zeros(size(boundaryX));
crowdingY = zeros(size(boundaryY));
probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    [px, py] = probe_center(net, net.probeMasks.(probeNames{k}));
    if ~isfinite(px)
        continue;
    end
    sx = exp(-((midXx - px).^2 + (midYx - py).^2) ./ max(opts.contactHaloRadius_um^2, eps));
    sy = exp(-((midXy - px).^2 + (midYy - py).^2) ./ max(opts.contactHaloRadius_um^2, eps));
    contactX = contactX + opts.contactWeight .* sx;
    contactY = contactY + opts.contactWeight .* sy;

    % Current crowding is strongest for links that connect into a probe halo.
    cx = exp(-((midXx - px).^2 + (midYx - py).^2) ./ max(opts.currentCrowdingRadius_um^2, eps));
    cy = exp(-((midXy - px).^2 + (midYy - py).^2) ./ max(opts.currentCrowdingRadius_um^2, eps));
    crowdingX = crowdingX + opts.currentCrowdingWeight .* cx;
    crowdingY = crowdingY + opts.currentCrowdingWeight .* cy;
end

sourceDrainX = exp(-((abs(midXx) - max(abs(net.x_um))).^2) ./ max(opts.edgeCrowdingWidth_um^2, eps));
sourceDrainY = exp(-((abs(midXy) - max(abs(net.x_um))).^2) ./ max(opts.edgeCrowdingWidth_um^2, eps));
crowdingX = crowdingX + opts.currentCrowdingWeight .* sourceDrainX;
crowdingY = crowdingY + opts.currentCrowdingWeight .* sourceDrainY;

if isfield(spec, 'crack')
    crackX = abs(midYx - (spec.crack.y0_um + spec.crack.slope .* midXx));
    crackY = abs(midYy - (spec.crack.y0_um + spec.crack.slope .* midXy));
    tearWidth = max(spec.crack.width_um, opts.tearLaneWidth_um);
    tearScoreX = exp(-(crackX ./ tearWidth).^2);
    tearScoreY = exp(-(crackY ./ tearWidth).^2);
else
    tearY0x = opts.tearLaneWidth_um .* sin((midXx - opts.tearX0_um) ./ max(opts.tearHalfLength_um, eps));
    tearY0y = opts.tearLaneWidth_um .* sin((midXy - opts.tearX0_um) ./ max(opts.tearHalfLength_um, eps));
    tearGateX = exp(-((midXx - opts.tearX0_um) ./ max(opts.tearHalfLength_um, eps)).^4);
    tearGateY = exp(-((midXy - opts.tearX0_um) ./ max(opts.tearHalfLength_um, eps)).^4);
    tearScoreX = tearGateX .* exp(-((midYx - tearY0x) ./ max(opts.tearLaneWidth_um, eps)).^2);
    tearScoreY = tearGateY .* exp(-((midYy - tearY0y) ./ max(opts.tearLaneWidth_um, eps)).^2);
end
tearX = opts.tearWeight .* tearScoreX;
tearY = opts.tearWeight .* tearScoreY;

rng(spec.randomSeed + opts.seedOffset);
hotX = zeros(size(boundaryX));
hotY = zeros(size(boundaryY));
for k = 1:opts.numHotspots
    x0 = min(net.x_um) + rand() .* (max(net.x_um) - min(net.x_um));
    y0 = opts.boundaryLaneWidth_um .* randn() .* 0.30;
    hotX = hotX + exp(-((midXx - x0).^2 + (midYx - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
    hotY = hotY + exp(-((midXy - x0).^2 + (midYy - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
end
hotX = opts.hotspotWeight .* hotX;
hotY = opts.hotspotWeight .* hotY;

combinedX = boundaryX + edgeX + contactX + crowdingX + tearX + hotX;
combinedY = boundaryY + edgeY + contactY + crowdingY + tearY + hotY;

if isfield(net.link, 'etaX')
    combinedX = combinedX .* (0.4 + 0.6 .* normalize_positive_local(net.link.etaX));
end
if isfield(net.link, 'etaY')
    combinedY = combinedY .* (0.4 + 0.6 .* normalize_positive_local(net.link.etaY));
end

scores = struct();
scores.boundaryX = clean_score(boundaryX + edgeX, net.link.activeX);
scores.boundaryY = clean_score(boundaryY + edgeY, net.link.activeY);
scores.contactX = clean_score(contactX, net.link.activeX);
scores.contactY = clean_score(contactY, net.link.activeY);
scores.crowdingX = clean_score(crowdingX, net.link.activeX);
scores.crowdingY = clean_score(crowdingY, net.link.activeY);
scores.tearX = clean_score(tearX, net.link.activeX);
scores.tearY = clean_score(tearY, net.link.activeY);
scores.combinedX = clean_score(combinedX, net.link.activeX);
scores.combinedY = clean_score(combinedY, net.link.activeY);

end

function score = clean_score(score, activeMask)

score(~activeMask) = 0;
score(~isfinite(score)) = 0;

end

function [maskX, maskY] = select_v745_mask(scoreX, scoreY, net, frac)

maskX = false(size(scoreX));
maskY = false(size(scoreY));
activeVals = [scoreX(net.link.activeX); scoreY(net.link.activeY)];
activeVals = activeVals(isfinite(activeVals));
if isempty(activeVals) || frac <= 0
    return;
end
nWeak = max(1, round(frac .* numel(activeVals)));
sortedVals = sort(activeVals, 'descend');
threshold = sortedVals(min(nWeak, numel(sortedVals)));
maskX = net.link.activeX & scoreX >= threshold & scoreX > 0;
maskY = net.link.activeY & scoreY >= threshold & scoreY > 0;

end

function [WX, WY, maskX, maskY] = shuffle_w_values(WX, WY, net, seed)

rng(seed);
vals = [WX(net.link.activeX); WY(net.link.activeY)];
vals = vals(randperm(numel(vals)));
nX = nnz(net.link.activeX);
WX(net.link.activeX) = vals(1:nX);
WY(net.link.activeY) = vals(nX+1:end);
maskX = WX < 0.999 & net.link.activeX;
maskY = WY < 0.999 & net.link.activeY;

end

function [midXx, midYx, midXy, midYy] = link_midpoints_local(net)

[X, Y] = meshgrid(net.x_um, net.y_um);
midXx = 0.5 .* (X(:,1:end-1) + X(:,2:end));
midYx = 0.5 .* (Y(:,1:end-1) + Y(:,2:end));
midXy = 0.5 .* (X(1:end-1,:) + X(2:end,:));
midYy = 0.5 .* (Y(1:end-1,:) + Y(2:end,:));

end

function [px, py] = probe_center(net, mask)

if ~any(mask(:))
    px = NaN;
    py = NaN;
    return;
end
px = mean(net.X_um(mask), 'omitnan');
py = mean(net.Y_um(mask), 'omitnan');

end

function Z = normalize_positive_local(Z)

vals = Z(isfinite(Z));
if isempty(vals)
    Z(:) = 0;
    return;
end
mn = min(vals);
mx = max(vals);
if mx <= mn
    Z = zeros(size(Z));
else
    Z = (Z - mn) ./ (mx - mn);
end

end

function nodeMap = link_to_node_fraction_local(net, maskX, maskY)

nodeMap = zeros(size(net.active));
count = zeros(size(net.active));

for row = 1:size(maskX,1)
    for col = 1:size(maskX,2)
        if net.link.activeX(row,col)
            nodeMap(row,col) = nodeMap(row,col) + double(maskX(row,col));
            nodeMap(row,col+1) = nodeMap(row,col+1) + double(maskX(row,col));
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end

for row = 1:size(maskY,1)
    for col = 1:size(maskY,2)
        if net.link.activeY(row,col)
            nodeMap(row,col) = nodeMap(row,col) + double(maskY(row,col));
            nodeMap(row+1,col) = nodeMap(row+1,col) + double(maskY(row,col));
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

nodeMap = nodeMap ./ max(count, 1);
nodeMap(~net.active) = NaN;

end

function nodeMap = link_score_to_node_mean_local(net, scoreX, scoreY)

nodeMap = zeros(size(net.active));
count = zeros(size(net.active));

for row = 1:size(scoreX,1)
    for col = 1:size(scoreX,2)
        if net.link.activeX(row,col)
            val = scoreX(row,col);
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row,col+1) = nodeMap(row,col+1) + val;
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end

for row = 1:size(scoreY,1)
    for col = 1:size(scoreY,2)
        if net.link.activeY(row,col)
            val = scoreY(row,col);
            nodeMap(row,col) = nodeMap(row,col) + val;
            nodeMap(row+1,col) = nodeMap(row+1,col) + val;
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

nodeMap = nodeMap ./ max(count, 1);
nodeMap = normalize_positive_local(nodeMap);
nodeMap(~net.active) = NaN;

end
