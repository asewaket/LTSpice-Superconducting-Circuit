function baselineTable = compute_geometry_baseline_scores(sweepTable, opts)
%COMPUTE_GEOMETRY_BASELINE_SCORES Summarize alpha=0 rows per device.

if nargin < 2 || isempty(opts)
    opts = make_raman_robustness_options();
end

devices = unique(string(sweepTable.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    T = sweepTable(string(sweepTable.device) == device & sweepTable.alpha == 0, :);
    vals = T.combinedScore(isfinite(T.combinedScore));
    if isempty(vals)
        baseline = NaN;
        baselineStd = NaN;
        baselineMin = NaN;
        baselineMean = NaN;
        baselineMedian = NaN;
    else
        baselineMin = min(vals);
        baselineMean = mean(vals);
        baselineMedian = median(vals);
        baselineStd = std(vals);
        switch opts.geometryBaselineStatistic
            case 'best'
                baseline = baselineMin;
            case 'mean'
                baseline = baselineMean;
            otherwise
                baseline = baselineMedian;
        end
    end

    rows(end+1,:) = {char(device), height(T), baseline, baselineMean, ...
        baselineMedian, baselineMin, baselineStd}; %#ok<AGROW>
end

baselineTable = cell2table(rows, 'VariableNames', { ...
    'device','N_alpha0_rows','geometryBaselineScore','geometryMeanScore', ...
    'geometryMedianScore','geometryBestScore','geometryScoreStd'});

end
