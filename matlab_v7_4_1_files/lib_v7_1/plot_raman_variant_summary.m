function h = plot_raman_variant_summary(sweepTable)
%PLOT_RAMAN_VARIANT_SUMMARY Compact summary of v6.1 Raman variant scores.

devices = unique(string(sweepTable.device), 'stable');
h = figure('Name', 'Raman variant sensitivity summary', 'Color', 'w', ...
    'Position', [100 100 1150 620]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
colors = lines(numel(devices));
for d = 1:numel(devices)
    idx = string(sweepTable.device) == devices(d);
    T = sortrows(sweepTable(idx,:), 'combinedScore');
    n = min(20, height(T));
    plot(1:n, T.combinedScore(1:n), '-o', 'LineWidth', 1.8, ...
        'MarkerSize', 5, 'Color', colors(d,:), 'DisplayName', char(devices(d)));
end
xlabel('ranked variant');
ylabel('combined score, lower is better');
title('Best Raman variants by device');
grid on;
box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

nexttile;
bestRows = table();
for d = 1:numel(devices)
    T = sortrows(sweepTable(string(sweepTable.device) == devices(d), :), 'combinedScore');
    bestRows = [bestRows; T(1,:)]; %#ok<AGROW>
end

labels = string(bestRows.device) + newline + ...
    string(bestRows.raman_mode) + newline + ...
    string(bestRows.representation) + newline + ...
    string(bestRows.couplingMode) + newline + ...
    "\alpha=" + string(bestRows.alpha);
bar(categorical(labels), bestRows.combinedScore, 0.65, ...
    'FaceColor', [0.25 0.50 0.85]);
ylabel('best combined score');
title('Best variant identity');
grid on;
box on;
set(gca, 'TickLabelInterpreter', 'none');
apply_light_figure_style(gca);

sgtitle('v6.1 Raman proxy/coupling sensitivity');

end
