function h = plot_physics_case_summary(caseTable, summaryTable, opts)
%PLOT_PHYSICS_CASE_SUMMARY Thesis-facing v6.7 case comparison.

devices = unique(string(caseTable.device), 'stable');
caseIDs = string(opts.caseIDs);
caseLabels = string(opts.caseLabels);
colors = lines(numel(devices));

h = figure('Name', 'v6.7 physics-informed case summary', 'Color', 'w', ...
    'Position', [80 80 1260 800]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
for d = 1:numel(devices)
    T = caseTable(string(caseTable.device) == devices(d), :);
    y = nan(numel(caseIDs), 1);
    for ic = 1:numel(caseIDs)
        idx = string(T.caseID) == caseIDs(ic);
        if any(idx)
            y(ic) = T.combinedScore(find(idx, 1, 'first'));
        end
    end
    plot(1:numel(caseIDs), y, '-o', 'LineWidth', 1.8, ...
        'MarkerSize', 5, 'Color', colors(d,:), 'DisplayName', char(devices(d)));
end
set(gca, 'XTick', 1:numel(caseIDs), 'XTickLabel', caseLabels, ...
    'TickLabelInterpreter', 'tex');
xtickangle(25);
ylabel('combined score, lower is better');
title('Physics-informed case score by device');
grid on; box on; apply_light_figure_style(gca);
lgd = legend('Location', 'best'); apply_light_legend_style(lgd);

nexttile;
x = categorical(string(summaryTable.device));
x = reordercats(x, cellstr(string(summaryTable.device)));
bar(x, summaryTable.delta_best_minus_baseline);
yline(0, 'k-', 'HandleVisibility', 'off');
ylabel('\Delta score: best case - baseline');
title('Does a physics-informed case improve R(T)?');
grid on; box on; apply_light_figure_style(gca);

nexttile;
bar(x, [summaryTable.exp_rLow, summaryTable.baseline_model_rLow, summaryTable.best_model_rLow]);
ylabel('low-T residual R/R_N');
title('Residual-resistance comparison');
grid on; box on; apply_light_figure_style(gca);
lgd = legend({'experiment','baseline','best case'}, 'Location', 'best');
apply_light_legend_style(lgd);

nexttile;
baselineOnset = summaryTable.baseline_sourceDrainPercOnset_K;
bestOnset = summaryTable.best_sourceDrainPercOnset_K;
barData = [replace_nan_with_zero(baselineOnset), replace_nan_with_zero(bestOnset)];
bar(x, barData);
ylabel('highest T with source-drain SC path [K]');
title('Source-drain percolation onset');
grid on; box on; apply_light_figure_style(gca);
lgd = legend({'baseline','best case'}, 'Location', 'best');
apply_light_legend_style(lgd);
add_none_labels(gca, x, baselineOnset, bestOnset);

sgtitle('v6.7 literature-informed superconducting-network cases A--G');

end

function y = replace_nan_with_zero(x)
y = x;
y(~isfinite(y)) = 0;
end

function add_none_labels(ax, xcats, a, b)

hold(ax, 'on');
for k = 1:numel(xcats)
    if ~isfinite(a(k))
        text(ax, k - 0.15, 0.03, 'none', 'Rotation', 90, ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);
    end
    if ~isfinite(b(k))
        text(ax, k + 0.15, 0.03, 'none', 'Rotation', 90, ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);
    end
end

end
