function h = plot_domain_percolation_summary(sweepTable, summaryTable)
%PLOT_DOMAIN_PERCOLATION_SUMMARY Compact v6.4 score/residual/percolation figure.

devices = unique(string(sweepTable.device), 'stable');
variants = unique(string(sweepTable.domain_variant), 'stable');
colors = lines(numel(devices));

h = figure('Name', 'v6.4 domain/percolation summary', 'Color', 'w', ...
    'Position', [80 80 1240 760]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
for d = 1:numel(devices)
    T = sweepTable(string(sweepTable.device) == devices(d), :);
    y = nan(numel(variants), 1);
    for iv = 1:numel(variants)
        idx = string(T.domain_variant) == variants(iv);
        if any(idx)
            y(iv) = T.combinedScore(find(idx, 1, 'first'));
        end
    end
    plot(1:numel(variants), y, '-o', 'LineWidth', 1.8, ...
        'MarkerSize', 5, 'Color', colors(d,:), 'DisplayName', char(devices(d)));
end
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants, ...
    'TickLabelInterpreter', 'none');
xtickangle(25);
ylabel('combined score, lower is better');
title('Domain-nucleation score by device');
grid on; box on; apply_light_figure_style(gca);
lgd = legend('Location', 'best'); apply_light_legend_style(lgd);

nexttile;
x = categorical(string(summaryTable.device));
x = reordercats(x, cellstr(string(summaryTable.device)));
bar(x, summaryTable.delta_best_minus_smooth);
yline(0, 'k-', 'HandleVisibility', 'off');
ylabel('\Delta score: best domain - smooth');
title('Does thresholded domain nucleation improve R(T)?');
grid on; box on; apply_light_figure_style(gca);

nexttile;
hold on;
bar(x, [summaryTable.exp_rLow, summaryTable.smooth_model_rLow, summaryTable.best_model_rLow]);
ylabel('low-T residual R/R_N');
title('Residual-resistance comparison');
grid on; box on; apply_light_figure_style(gca);
lgd = legend({'experiment','smooth Raman','best domain'}, 'Location', 'best');
apply_light_legend_style(lgd);

nexttile;
hold on;
bar(x, [summaryTable.smooth_sourceDrainPercOnset_K, summaryTable.best_sourceDrainPercOnset_K]);
ylabel('highest T with source-drain SC path [K]');
title('Source-drain percolation onset');
grid on; box on; apply_light_figure_style(gca);
lgd = legend({'smooth Raman','best domain'}, 'Location', 'best');
apply_light_legend_style(lgd);

sgtitle('v6.4 Raman-informed enhanced-domain/percolation diagnostics');

end
