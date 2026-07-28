function score = score_normalized_rt(expT, expR, modelT, modelR, cfg)
%SCORE_NORMALIZED_RT Compare experimental and modeled normalized R(T).

if nargin < 5
    cfg = struct();
end

score = empty_score();
if isempty(expT) || isempty(expR) || isempty(modelT) || isempty(modelR)
    score.run_status = "missing_curve";
    return;
end

metricOpts = make_metric_options();
expMetrics = compute_rt_curve_metrics(expT, expR, metricOpts);
modelMetrics = compute_rt_curve_metrics(modelT, modelR, metricOpts);
[expTn, expRn, expRN] = normalize_rt_curve(expT, expR);
[modelTn, modelRn, modelRN] = normalize_rt_curve(modelT, modelR);

validExp = isfinite(expTn) & isfinite(expRn);
validModel = isfinite(modelTn) & isfinite(modelRn);
expTn = expTn(validExp);
expRn = expRn(validExp);
modelTn = modelTn(validModel);
modelRn = modelRn(validModel);
[expTn, expUnique] = unique(expTn, 'stable');
expRn = expRn(expUnique);
[modelTn, modelUnique] = unique(modelTn, 'stable');
modelRn = modelRn(modelUnique);
if numel(expTn) < 3 || numel(modelTn) < 3
    score.run_status = "insufficient_curve_points";
    return;
end

tMin = max(min(expTn), min(modelTn));
tMax = min(max(expTn), max(modelTn));
if ~(isfinite(tMin) && isfinite(tMax) && tMax > tMin)
    score.run_status = "no_temperature_overlap";
    return;
end

gridN = get_cfg_scalar(cfg, 'rtScoreGridPoints', 160);
Tq = linspace(tMin, tMax, gridN).';
RqExp = interp1(expTn, expRn, Tq, 'linear');
RqModel = interp1(modelTn, modelRn, Tq, 'linear');
valid = isfinite(RqExp) & isfinite(RqModel);
if nnz(valid) < 3
    score.run_status = "interpolation_failed";
    return;
end

curveScore = mean((RqModel(valid) - RqExp(valid)).^2);
onsetScore = scaled_abs(modelMetrics.Tonset_K - expMetrics.Tonset_K, ...
    get_cfg_scalar(cfg, 'onsetScale_K', 0.35));
widthScore = scaled_abs(modelMetrics.width90_10_K - expMetrics.width90_10_K, ...
    get_cfg_scalar(cfg, 'widthScale_K', 0.35));
lowTScore = abs(modelMetrics.rLow - expMetrics.rLow);

wCurve = get_cfg_scalar(cfg, 'weightCurve', 0.50);
wOnset = get_cfg_scalar(cfg, 'weightOnset', 0.20);
wWidth = get_cfg_scalar(cfg, 'weightWidth', 0.15);
wLowT = get_cfg_scalar(cfg, 'weightLowT', 0.15);
weights = [wCurve wOnset wWidth wLowT];
terms = [curveScore onsetScore widthScore lowTScore];
finite = isfinite(terms) & isfinite(weights) & weights > 0;
if ~any(finite)
    totalScore = NaN;
else
    totalScore = sum(weights(finite) .* terms(finite)) ./ sum(weights(finite));
end

score.available = isfinite(totalScore);
score.RT_curve_score = curveScore;
score.onset_score = onsetScore;
score.width_score = widthScore;
score.lowT_score = lowTScore;
score.total_LevelA_score = totalScore;
score.RN_exp = expRN;
score.RN_model = modelRN;
score.exp_Tonset_K = expMetrics.Tonset_K;
score.model_Tonset_K = modelMetrics.Tonset_K;
score.exp_width90_10_K = expMetrics.width90_10_K;
score.model_width90_10_K = modelMetrics.width90_10_K;
score.exp_rLow = expMetrics.rLow;
score.model_rLow = modelMetrics.rLow;
score.run_status = ternary(score.available, "scored", "nonfinite_score");
end

function score = empty_score()
score = struct();
score.available = false;
score.RT_curve_score = NaN;
score.onset_score = NaN;
score.width_score = NaN;
score.lowT_score = NaN;
score.total_LevelA_score = NaN;
score.RN_exp = NaN;
score.RN_model = NaN;
score.exp_Tonset_K = NaN;
score.model_Tonset_K = NaN;
score.exp_width90_10_K = NaN;
score.model_width90_10_K = NaN;
score.exp_rLow = NaN;
score.model_rLow = NaN;
score.run_status = "";
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

function out = ternary(tf, a, b)
if tf
    out = a;
else
    out = b;
end
end
