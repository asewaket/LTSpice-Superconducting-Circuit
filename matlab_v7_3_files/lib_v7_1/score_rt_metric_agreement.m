function score = score_rt_metric_agreement(expMetrics, modelMetrics, opts)
%SCORE_RT_METRIC_AGREEMENT Dimensionless model/experiment mismatch score.

if nargin < 3 || isempty(opts)
    opts = make_raman_hybrid_options();
end

w = opts.scoreWeights;
scaleT = opts.scale.T_K;

terms = [];
weights = [];

[terms, weights] = add_term(terms, weights, modelMetrics.rLow - expMetrics.rLow, w.rLow, 1);
[terms, weights] = add_term(terms, weights, modelMetrics.Tonset_K - expMetrics.Tonset_K, w.Tonset, scaleT);
[terms, weights] = add_term(terms, weights, modelMetrics.Tmid_K - expMetrics.Tmid_K, w.Tmid, scaleT);
[terms, weights] = add_term(terms, weights, modelMetrics.width90_10_K - expMetrics.width90_10_K, w.width, scaleT);

if isempty(terms)
    score = NaN;
else
    score = sqrt(sum(weights .* terms.^2) ./ sum(weights));
end

end

function [terms, weights] = add_term(terms, weights, delta, weight, scale)
if isfinite(delta) && isfinite(weight) && weight > 0 && scale > 0
    terms(end+1) = delta ./ scale; %#ok<AGROW>
    weights(end+1) = weight; %#ok<AGROW>
end
end
