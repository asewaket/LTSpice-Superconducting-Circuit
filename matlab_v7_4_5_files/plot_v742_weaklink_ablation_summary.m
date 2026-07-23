function h = plot_v742_weaklink_ablation_summary(sweepTable)
%PLOT_V742_WEAKLINK_ABLATION_SUMMARY Plot focused weak-link sweep ranking.

if ~istable(sweepTable) || isempty(sweepTable)
    error('plot_v742_weaklink_ablation_summary requires a nonempty table.');
end

T = sortrows(sweepTable, 'featureScore', 'ascend');
n = height(T);
nTop = min(6, n);

h = figure('Name', 'v7.4.2 weak-link ablation summary', ...
    'Color', 'w', 'Position', [80 80 1350 820]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(1:n, T.featureScore, 'o-', 'LineWidth', 1.8, 'MarkerSize', 6);
xlabel('ranked case');
ylabel('feature score, lower is better');
title('weak-link ablation ranking');
grid on; box on;
apply_light_figure_style(gca);

nexttile;
bar(categorical(T.caseName(1:nTop)), ...
    [T.fullMapScore(1:nTop), T.lowBiasScore(1:nTop), ...
    T.zeroBiasScore(1:nTop), T.asymmetryScore(1:nTop)]);
ylabel('score component');
title('top-case score components');
legend({'full map','low-bias map','zero-bias field','top/bottom asym.'}, ...
    'Location', 'best');
xtickangle(30);
grid on; box on;
apply_light_figure_style(gca);
apply_light_legend_style(legend);

nexttile;
scatter(T.weakFraction, T.featureScore, 90, T.IcMultiplier, 'filled');
xlabel('weak-link fraction');
ylabel('feature score');
title('score versus weak-link sparsity');
cb = colorbar;
ylabel(cb, 'I_c multiplier');
grid on; box on;
apply_light_figure_style(gca);

nexttile;
scatter(T.IcMultiplier, T.featureScore, 90, T.switchWidthFrac, 'filled');
set(gca, 'XScale', 'log');
xlabel('weak-link I_c multiplier');
ylabel('feature score');
title('score versus weak-link strength');
cb = colorbar;
ylabel(cb, '\Delta I/I_c');
grid on; box on;
apply_light_figure_style(gca);

sgtitle('v7.4.2 focused weak-link ablation sweep for AS006', ...
    'FontWeight', 'bold');

end
