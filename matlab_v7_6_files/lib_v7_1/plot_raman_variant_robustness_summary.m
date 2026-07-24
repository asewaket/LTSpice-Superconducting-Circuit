function h = plot_raman_variant_robustness_summary(summary)
%PLOT_RAMAN_VARIANT_ROBUSTNESS_SUMMARY Mean ± std for top variants.

devices = unique(string(summary.device), 'stable');
h = figure('Name', 'Raman variant robustness summary', 'Color', 'w', ...
    'Position', [100 100 1050 330*numel(devices)]);
tiledlayout(numel(devices), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:numel(devices)
    device = devices(d);
    T = summary(string(summary.device) == device, :);
    T = sortrows(T, 'combinedScoreMean');
    nexttile;
    x = 1:height(T);
    errorbar(x, T.combinedScoreMean, T.combinedScoreStd, 'o', ...
        'LineWidth', 1.7, 'MarkerSize', 6, ...
        'Color', [0.0 0.45 0.74], ...
        'MarkerFaceColor', [0.0 0.45 0.74]);
    hold on;
    geoIdx = string(T.couplingMode) == "geometry_only";
    if any(geoIdx)
        yGeo = T.combinedScoreMean(find(geoIdx, 1, 'first'));
        yline(yGeo, '--', 'geometry-only mean', ...
            'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    end
    set(gca, 'XTick', x, 'XTickLabel', compact_labels(T));
    xtickangle(22);
    ylabel('combined score');
    title(sprintf('%s top-variant robustness, mean \\pm std', device));
    grid on;
    box on;
    apply_light_figure_style(gca);
end

sgtitle('v6.2 disorder-robustness test for top Raman variants');

end

function labels = compact_labels(T)
labels = strings(height(T), 1);
for k = 1:height(T)
    if string(T.couplingMode(k)) == "geometry_only"
        labels(k) = "geometry only";
    else
        labels(k) = string(T.raman_mode(k)) + newline + ...
            string(T.representation(k)) + newline + ...
            string(T.couplingMode(k)) + newline + ...
            "\alpha=" + string(T.alpha(k));
    end
end
labels = cellstr(labels);
end
