function h = plot_out_of_plane_mode_ablation(modeSummary, oopIndex)
%PLOT_OUT_OF_PLANE_MODE_ABLATION Thesis-friendly v6.3 A4g contribution figure.

devices = unique(string(modeSummary.device), 'stable');
modeOrder = {'A4g_only','in_plane_only','all_with_A4g','without_A4g', ...
    'A5g_only','B2g_only','without_A5g','without_B2g'};

h = figure('Name', 'Out-of-plane Raman mode ablation summary', 'Color', 'w', ...
    'Position', [80 80 1180 640]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
colors = lines(numel(devices));
for d = 1:numel(devices)
    device = devices(d);
    T = modeSummary(string(modeSummary.device) == device, :);
    y = nan(numel(modeOrder), 1);
    for im = 1:numel(modeOrder)
        idx = string(T.mode_variant) == modeOrder{im};
        if any(idx)
            y(im) = T.bestScore(find(idx, 1, 'first'));
        end
    end
    plot(1:numel(modeOrder), y, '-o', 'LineWidth', 1.8, ...
        'MarkerSize', 5, 'Color', colors(d,:), ...
        'DisplayName', char(device));
end
set(gca, 'XTick', 1:numel(modeOrder), 'XTickLabel', modeOrder, ...
    'TickLabelInterpreter', 'none');
xtickangle(30);
ylabel('best combined score');
title('Mode-ablation score by device');
grid on;
box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

nexttile;
x = categorical(string(oopIndex.device));
x = reordercats(x, cellstr(string(oopIndex.device)));
bar(x, [oopIndex.delta_without_A4g_minus_all, oopIndex.delta_inplane_minus_all]);
yline(0, 'k-', 'HandleVisibility', 'off');
ylabel('\Delta score relative to all modes');
title('Out-of-plane contribution diagnostics');
grid on;
box on;
apply_light_figure_style(gca);
lgd = legend({'without A4g - all','in-plane only - all'}, ...
    'Location', 'best');
apply_light_legend_style(lgd);

sgtitle('v6.3 A4g/out-of-plane-sensitive Raman mode-ablation test');

end
