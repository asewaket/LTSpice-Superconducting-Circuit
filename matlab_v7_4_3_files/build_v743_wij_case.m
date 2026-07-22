function [netCase, paramsCase, weak] = build_v743_wij_case(netBase, spec, ...
    paramsBase, caseInfo, opts, calibrationMode, fullNormalScale)
%BUILD_V743_WIJ_CASE Apply one controlled W_ij ablation case.
%
% calibrationMode:
%   "shape"       independently recalibrates this ablation to target R_N.
%   "conductance" applies the full-model normal-state scale unchanged.

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

[WX, WY, weak] = make_v743_wij_field(netBase, spec, caseInfo, opts);
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
        weak.calibrationDescription = "conductance-preserving: full-model R_N scale applied unchanged";
    otherwise
        error('Unknown calibrationMode "%s".', calibrationMode);
end

weak.activeLinkFraction = (nnz(paramsCase.weakLinkMaskX & netCase.link.activeX) + ...
    nnz(paramsCase.weakLinkMaskY & netCase.link.activeY)) ./ ...
    max(1, nnz(netCase.link.activeX) + nnz(netCase.link.activeY));
weak.nodeMap = link_to_node_fraction_local(netCase, ...
    paramsCase.weakLinkMaskX, paramsCase.weakLinkMaskY);

end

function [WX, WY, weak] = make_v743_wij_field(net, spec, caseInfo, opts)

WX = ones(size(net.link.activeX));
WY = ones(size(net.link.activeY));

weak = struct();
weak.version = opts.version;
weak.caseName = string(caseInfo.name);
weak.description = string(caseInfo.description);
weak.topology = string(caseInfo.topology);
weak.gammaW = caseInfo.gammaW;
weak.pW = caseInfo.pW;
weak.definition = ['v7.4.3 controlled W_ij ablation: weak-link ', ...
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

[scoreXFull, scoreYFull, scoreXNoBoundary, scoreYNoBoundary] = ...
    v743_weaklink_scores(net, spec, opts);

switch string(caseInfo.topology)
    case {"full","central_lane"}
        scoreX = scoreXFull;
        scoreY = scoreYFull;
    case "boundary_off"
        scoreX = scoreXNoBoundary;
        scoreY = scoreYNoBoundary;
    otherwise
        scoreX = scoreXFull;
        scoreY = scoreYFull;
end

[maskX, maskY] = select_v743_mask(scoreX, scoreY, net, caseInfo.pW);
WX(maskX) = caseInfo.gammaW;
WY(maskY) = caseInfo.gammaW;

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
weak.histogramPreserved = any(strcmp(caseInfo.topology, ["full","shuffled","central_lane"]));

end

function [scoreX, scoreY, noBoundaryX, noBoundaryY] = v743_weaklink_scores(net, spec, opts)

[midXx, midYx, midXy, midYy] = link_midpoints_local(net);
scoreX = zeros(size(net.link.activeX));
scoreY = zeros(size(net.link.activeY));

boundaryX = exp(-(midYx ./ opts.boundaryLaneWidth_um).^2);
boundaryY = exp(-(midYy ./ opts.boundaryLaneWidth_um).^2);
scoreX = scoreX + opts.boundaryWeight .* boundaryX;
scoreY = scoreY + opts.boundaryWeight .* boundaryY;

if isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'bottom')
    scoreX = scoreX + opts.coveredEdgeWeight .* max(0, -midYx ./ max(abs(min(net.y_um)), eps));
    scoreY = scoreY + opts.coveredEdgeWeight .* max(0, -midYy ./ max(abs(min(net.y_um)), eps));
elseif isfield(spec, 'coveredSide') && strcmpi(spec.coveredSide, 'top')
    scoreX = scoreX + opts.coveredEdgeWeight .* max(0, midYx ./ max(abs(max(net.y_um)), eps));
    scoreY = scoreY + opts.coveredEdgeWeight .* max(0, midYy ./ max(abs(max(net.y_um)), eps));
end

% Probe/contact relaxation regions are included as generic weak-link
% candidates but are not removed by the boundary/crack-off ablation.
probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    [px, py] = probe_center(net, net.probeMasks.(probeNames{k}));
    if ~isfinite(px)
        continue;
    end
    sx = exp(-((midXx - px).^2 + (midYx - py).^2) ./ max((0.55)^2, eps));
    sy = exp(-((midXy - px).^2 + (midYy - py).^2) ./ max((0.55)^2, eps));
    scoreX = scoreX + opts.contactWeight .* sx;
    scoreY = scoreY + opts.contactWeight .* sy;
end

if strcmp(spec.geometryClass, 'cracked_full') && isfield(spec, 'crack')
    crackX = abs(midYx - (spec.crack.y0_um + spec.crack.slope .* midXx));
    crackY = abs(midYy - (spec.crack.y0_um + spec.crack.slope .* midXy));
    crackScoreX = exp(-(crackX ./ max(spec.crack.width_um, 0.25)).^2);
    crackScoreY = exp(-(crackY ./ max(spec.crack.width_um, 0.25)).^2);
    scoreX = scoreX + opts.boundaryWeight .* crackScoreX;
    scoreY = scoreY + opts.boundaryWeight .* crackScoreY;
else
    crackScoreX = zeros(size(scoreX));
    crackScoreY = zeros(size(scoreY));
end

rng(spec.randomSeed + opts.seedOffset);
hotX = zeros(size(scoreX));
hotY = zeros(size(scoreY));
for k = 1:opts.numHotspots
    x0 = min(net.x_um) + rand() .* (max(net.x_um) - min(net.x_um));
    y0 = opts.boundaryLaneWidth_um .* randn() .* 0.30;
    hotX = hotX + exp(-((midXx - x0).^2 + (midYx - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
    hotY = hotY + exp(-((midXy - x0).^2 + (midYy - y0).^2) ./ ...
        max(opts.hotspotRadius_um^2, eps));
end
scoreX = scoreX + opts.hotspotWeight .* hotX;
scoreY = scoreY + opts.hotspotWeight .* hotY;

if isfield(net.link, 'etaX')
    scoreX = scoreX .* (0.4 + 0.6 .* normalize_positive_local(net.link.etaX));
end
if isfield(net.link, 'etaY')
    scoreY = scoreY .* (0.4 + 0.6 .* normalize_positive_local(net.link.etaY));
end

noBoundaryX = scoreX - opts.boundaryWeight .* boundaryX - opts.boundaryWeight .* crackScoreX;
noBoundaryY = scoreY - opts.boundaryWeight .* boundaryY - opts.boundaryWeight .* crackScoreY;

scoreX(~net.link.activeX) = 0;
scoreY(~net.link.activeY) = 0;
noBoundaryX(~net.link.activeX) = 0;
noBoundaryY(~net.link.activeY) = 0;

end

function [maskX, maskY] = select_v743_mask(scoreX, scoreY, net, frac)

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
