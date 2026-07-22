function combined = combine_raman_scores(metricScore, shapeScore, opts)
%COMBINE_RAMAN_SCORES Combine metric and full-curve shape mismatch.

wm = opts.combinedScore.metricWeight;
ws = opts.combinedScore.shapeWeight;
vals = [];
weights = [];
if isfinite(metricScore) && wm > 0
    vals(end+1) = metricScore; %#ok<AGROW>
    weights(end+1) = wm; %#ok<AGROW>
end
if isfinite(shapeScore) && ws > 0
    vals(end+1) = shapeScore; %#ok<AGROW>
    weights(end+1) = ws; %#ok<AGROW>
end

if isempty(vals)
    combined = NaN;
else
    combined = sqrt(sum(weights .* vals.^2) ./ sum(weights));
end

end
