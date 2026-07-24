function pairScores = compute_probe_pair_scores(expData, run, metricOpts, scoreOpts)
%COMPUTE_PROBE_PAIR_SCORES Compare model/experiment for top and bottom pairs.

pairs = {'top_4_10','bottom_3_9'};
pairScores = struct();

for k = 1:numel(pairs)
    pairName = pairs{k};
    S = empty_pair_score();
    S.pairName = pairName;

    if isfield(run.result.R4p, pairName)
        modelT = run.result.T;
        modelR = run.result.R4p.(pairName);
        S.modelMetrics = compute_rt_curve_metrics(modelT, modelR, metricOpts);
        S.model_rLow = S.modelMetrics.rLow;
    else
        pairScores.(pairName) = S;
        continue;
    end

    [expT, expR] = experimental_pair_curve(expData, pairName);
    if isempty(expT) || isempty(expR)
        pairScores.(pairName) = S;
        continue;
    end

    S.available = true;
    S.expMetrics = compute_rt_curve_metrics(expT, expR, metricOpts);
    S.exp_rLow = S.expMetrics.rLow;
    S.metricScore = score_rt_metric_agreement(S.expMetrics, S.modelMetrics, scoreOpts);
    S.shapeScore = compute_rt_shape_score(expT, expR, modelT, modelR);
    S.combinedScore = combine_raman_scores(S.metricScore, S.shapeScore, scoreOpts);

    pairScores.(pairName) = S;
end

end

function [T, R] = experimental_pair_curve(expData, pairName)

T = [];
R = [];

if isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available && ...
        isfield(expData.pairData.R, pairName)
    T = expData.pairData.T;
    R = expData.pairData.R.(pairName);
    return;
end

% Fallback: the curated publication curve can represent the selected model
% pair, even when separate top/bottom raw pair curves are unavailable.
if isfield(expData, 'modelPair') && strcmp(pairName, expData.modelPair) && ...
        isfield(expData.R, 'main_4p')
    T = expData.T;
    R = expData.R.main_4p;
end

end

function S = empty_pair_score()

S = struct();
S.pairName = '';
S.available = false;
S.metricScore = NaN;
S.shapeScore = NaN;
S.combinedScore = NaN;
S.exp_rLow = NaN;
S.model_rLow = NaN;
S.expMetrics = [];
S.modelMetrics = [];

end
