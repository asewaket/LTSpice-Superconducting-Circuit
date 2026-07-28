function out = score_probe_asymmetry(expT, expTop, expBottom, modelT, modelTop, modelBottom, cfg)
%SCORE_PROBE_ASYMMETRY Compare top/bottom probe asymmetry without refitting.

if nargin < 7
    cfg = struct();
end

out = empty_out();
if isempty(expT) || isempty(expTop) || isempty(expBottom) || ...
        isempty(modelT) || isempty(modelTop) || isempty(modelBottom)
    out.run_status = "missing_probe_pair";
    return;
end

[eT, eA, eOrd, eFeat] = asymmetry_curve(expT, expTop, expBottom, cfg);
[mT, mA, mOrd, mFeat] = asymmetry_curve(modelT, modelTop, modelBottom, cfg);
if numel(eT) < 3 || numel(mT) < 3
    out.run_status = "insufficient_probe_pair_points";
    return;
end

tMin = max(min(eT), min(mT));
tMax = min(max(eT), max(mT));
if ~(isfinite(tMin) && isfinite(tMax) && tMax > tMin)
    out.run_status = "no_asymmetry_temperature_overlap";
    return;
end

nGrid = get_cfg_scalar(cfg, 'rtScoreGridPoints', 160);
Tq = linspace(tMin, tMax, nGrid).';
eAq = interp1(eT, eA, Tq, 'linear');
mAq = interp1(mT, mA, Tq, 'linear');
valid = isfinite(eAq) & isfinite(mAq);
if nnz(valid) < 3
    out.run_status = "asymmetry_interpolation_failed";
    return;
end

curveScore = mean((mAq(valid) - eAq(valid)).^2);
featureScore = mean([
    scaled_abs(mFeat.maxAbs - eFeat.maxAbs, 0.25)
    scaled_abs(mFeat.lowT - eFeat.lowT, 0.20)
    scaled_abs(mFeat.integratedAbs - eFeat.integratedAbs, 0.20)
    scaled_abs(mFeat.onsetT_K - eFeat.onsetT_K, 0.35)
    ], 'omitnan');
if ~isfinite(featureScore)
    featureScore = NaN;
end

out.available = true;
out.asymmetry_curve_score = curveScore;
out.asymmetry_feature_score = featureScore;
if isfinite(featureScore)
    out.asymmetry_score = 0.65 .* curveScore + 0.35 .* featureScore;
else
    out.asymmetry_score = curveScore;
end
out.exp_ordering = eOrd;
out.model_ordering = mOrd;
out.ordering_match = eOrd == mOrd;
out.exp_max_asymmetry = eFeat.maxAbs;
out.model_max_asymmetry = mFeat.maxAbs;
out.exp_lowT_asymmetry = eFeat.lowT;
out.model_lowT_asymmetry = mFeat.lowT;
out.exp_integrated_asymmetry = eFeat.integratedAbs;
out.model_integrated_asymmetry = mFeat.integratedAbs;
out.exp_asymmetry_onset_K = eFeat.onsetT_K;
out.model_asymmetry_onset_K = mFeat.onsetT_K;
out.run_status = "scored";
end

function [T, A, ordering, feat] = asymmetry_curve(T, topR, bottomR, cfg)
T = T(:);
topR = topR(:);
bottomR = bottomR(:);
n = min([numel(T), numel(topR), numel(bottomR)]);
T = T(1:n);
topR = topR(1:n);
bottomR = bottomR(1:n);
valid = isfinite(T) & isfinite(topR) & isfinite(bottomR) & ...
    abs(topR + bottomR) > eps;
T = T(valid);
topR = topR(valid);
bottomR = bottomR(valid);
[T, order] = sort(T);
topR = topR(order);
bottomR = bottomR(order);
[T, uniqueIdx] = unique(T, 'stable');
topR = topR(uniqueIdx);
bottomR = bottomR(uniqueIdx);

A = (topR - bottomR) ./ max(0.5 .* (topR + bottomR), eps);
tol = get_cfg_scalar(cfg, 'asymmetryOrderingTolerance', 0.08);
metricOpts = make_metric_options();
topMetrics = compute_rt_curve_metrics(T, topR, metricOpts);
bottomMetrics = compute_rt_curve_metrics(T, bottomR, metricOpts);
if ~isfinite(topMetrics.rLow) || ~isfinite(bottomMetrics.rLow) || ...
        abs(topMetrics.rLow - bottomMetrics.rLow) < tol
    ordering = "approximately symmetric";
elseif topMetrics.rLow < bottomMetrics.rLow
    ordering = "top more suppressed";
else
    ordering = "bottom more suppressed";
end

feat = struct();
feat.maxAbs = max(abs(A), [], 'omitnan');
nLow = max(1, ceil(0.10 .* numel(A)));
feat.lowT = mean(A(1:nLow), 'omitnan');
feat.integratedAbs = mean(abs(A), 'omitnan');
threshold = get_cfg_scalar(cfg, 'asymmetryOnsetThreshold', 0.08);
idx = find(abs(A) > threshold, 1, 'last');
if isempty(idx)
    feat.onsetT_K = NaN;
else
    feat.onsetT_K = T(idx);
end
end

function out = empty_out()
out = struct();
out.available = false;
out.asymmetry_score = NaN;
out.asymmetry_curve_score = NaN;
out.asymmetry_feature_score = NaN;
out.exp_ordering = "";
out.model_ordering = "";
out.ordering_match = false;
out.exp_max_asymmetry = NaN;
out.model_max_asymmetry = NaN;
out.exp_lowT_asymmetry = NaN;
out.model_lowT_asymmetry = NaN;
out.exp_integrated_asymmetry = NaN;
out.model_integrated_asymmetry = NaN;
out.exp_asymmetry_onset_K = NaN;
out.model_asymmetry_onset_K = NaN;
out.run_status = "";
end

function y = scaled_abs(delta, scale)
if ~isfinite(delta) || ~isfinite(scale) || scale <= 0
    y = NaN;
else
    y = abs(delta) ./ scale;
end
end

function y = get_cfg_scalar(cfg, name, defaultValue)
y = defaultValue;
if isstruct(cfg) && isfield(cfg, name) && ...
        isnumeric(cfg.(name)) && isscalar(cfg.(name)) && isfinite(cfg.(name))
    y = cfg.(name);
end
end
