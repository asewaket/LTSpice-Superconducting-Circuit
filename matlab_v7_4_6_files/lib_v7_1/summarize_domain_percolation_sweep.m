function summary = summarize_domain_percolation_sweep(sweepTable)
%SUMMARIZE_DOMAIN_PERCOLATION_SWEEP Best and smooth-only deltas by device.

devices = unique(string(sweepTable.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    T = sweepTable(string(sweepTable.device) == device, :);
    T = sortrows(T, 'combinedScore');
    best = T(1,:);
    smooth = T(string(T.domain_variant) == "smooth_only", :);
    if isempty(smooth)
        smooth = best;
    else
        smooth = smooth(1,:);
    end

    rows(end+1,:) = {char(device), char(best.domain_variant), ...
        smooth.combinedScore, best.combinedScore, ...
        best.combinedScore - smooth.combinedScore, ...
        smooth.model_rLow, best.model_rLow, best.exp_rLow, ...
        smooth.sourceDrainPercOnset_K, best.sourceDrainPercOnset_K, ...
        best.domainLinkFraction, best.meanDomainProbability}; %#ok<AGROW>
end

summary = cell2table(rows, 'VariableNames', { ...
    'device','best_domain_variant','smooth_score','best_score','delta_best_minus_smooth', ...
    'smooth_model_rLow','best_model_rLow','exp_rLow', ...
    'smooth_sourceDrainPercOnset_K','best_sourceDrainPercOnset_K', ...
    'best_domainLinkFraction','best_meanDomainProbability'});

end
