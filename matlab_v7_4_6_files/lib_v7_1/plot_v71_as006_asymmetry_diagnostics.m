function h = plot_v71_as006_asymmetry_diagnostics(spec, asym)
%PLOT_V71_AS006_ASYMMETRY_DIAGNOSTICS Plot AS006 top-bottom R(T) asymmetry.

h = figure('Name', 'v7.1 AS006 top-bottom asymmetry diagnostic', ...
    'Color', 'w', 'Position', [90 90 1120 430]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

curves = asym.curves;

nexttile;
hold on;
plot(curves.T_K, curves.model_top_4_10_norm, '-', ...
    'Color', [0.00 0.45 0.74], 'LineWidth', 2.2, ...
    'DisplayName', 'model top 4-10');
plot(curves.T_K, curves.model_bottom_3_9_norm, '-', ...
    'Color', [0.85 0.33 0.10], 'LineWidth', 2.2, ...
    'DisplayName', 'model bottom 3-9');

if asym.summary.experimentAvailable
    plot(curves.T_K, curves.exp_top_4_10_norm, 'o', ...
        'Color', [0.00 0.45 0.74], 'MarkerSize', 3.5, ...
        'DisplayName', 'exp top 4-10');
    plot(curves.T_K, curves.exp_bottom_3_9_norm, 'o', ...
        'Color', [0.85 0.33 0.10], 'MarkerSize', 3.5, ...
        'DisplayName', 'exp bottom 3-9');
end

xlabel('Temperature T [K]');
ylabel('pair-normalized R/R_N');
title('top and bottom four-probe curves');
ylim([0 1.15]);
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

nexttile;
hold on;
plot(curves.T_K, curves.model_delta_bottom_minus_top, '-', ...
    'Color', [0.15 0.15 0.15], 'LineWidth', 2.4, ...
    'DisplayName', 'model \Delta r');

if asym.summary.experimentAvailable
    plot(curves.T_K, curves.exp_delta_bottom_minus_top, 'o', ...
        'Color', [0.55 0.15 0.65], 'MarkerSize', 3.5, ...
        'DisplayName', 'experiment \Delta r');
    plot(curves.T_K, curves.delta_model_minus_exp, '--', ...
        'Color', [0.30 0.30 0.30], 'LineWidth', 1.4, ...
        'DisplayName', 'model - experiment');
end

yline(0, ':', 'Color', [0.25 0.25 0.25], 'HandleVisibility', 'off');
xlabel('Temperature T [K]');
ylabel('\Delta r = r_{3-9} - r_{4-10}');
title(sprintf('\\Delta r mismatch RMS = %.3g', asym.summary.deltaMismatchRms));
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

sgtitle(sprintf('v7.1 %s top-bottom asymmetry: %s', ...
    spec.name, spec.filmForceLabel), 'FontWeight', 'bold');

end
