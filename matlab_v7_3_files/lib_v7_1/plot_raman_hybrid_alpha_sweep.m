function h = plot_raman_hybrid_alpha_sweep(sweepTable)
%PLOT_RAMAN_HYBRID_ALPHA_SWEEP Plot v6 metric score versus Raman weight.

devices = unique(string(sweepTable.device), 'stable');

h = figure('Name', 'Raman-hybrid alpha sweep scores', 'Color', 'w', ...
    'Position', [100 100 880 520]);
hold on;
colors = lines(numel(devices));
for d = 1:numel(devices)
    idx = string(sweepTable.device) == devices(d);
    T = sortrows(sweepTable(idx,:), 'alpha');
    plot(T.alpha, T.score, '-o', 'LineWidth', 2.0, ...
        'MarkerSize', 6, 'Color', colors(d,:), ...
        'DisplayName', char(devices(d)));
    [bestScore, bestIdx] = min(T.score);
    plot(T.alpha(bestIdx), bestScore, 'p', 'Color', colors(d,:), ...
        'MarkerFaceColor', colors(d,:), 'MarkerSize', 11, ...
        'HandleVisibility', 'off');
end
xlabel('Raman mixing weight \alpha');
ylabel('metric mismatch score, lower is better');
title('Does Raman-informed spatial heterogeneity improve normalized R(T)?');
grid on;
box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end
