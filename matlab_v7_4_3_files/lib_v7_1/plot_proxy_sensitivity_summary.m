function h = plot_proxy_sensitivity_summary(summaryTable)
%PLOT_PROXY_SENSITIVITY_SUMMARY Visualize ranked proxy/model samples.

h = figure('Color','w', 'Name', 'proxy sensitivity summary');
set(h, 'Units','inches', 'Position', [1 1 9.5 4.2]);

subplot(1,2,1);
plot(1:height(summaryTable), summaryTable.score_total, 'o-', ...
    'LineWidth', 1.4, 'MarkerSize', 4, 'Color', [0 0.4470 0.7410]);
xlabel('ranked sample');
ylabel('metric score');
title('Sensitivity-sweep ranking');
apply_light_figure_style(gca);

subplot(1,2,2);
topN = min(8, height(summaryTable));
vars = {'boundaryWeight','crackWeight','TcSpan_K','eta0','sigmoidWidth'};
vals = zeros(topN, numel(vars));
for k = 1:numel(vars)
    vals(:,k) = summaryTable.(vars{k})(1:topN);
end
imagesc(vals);
colormap(gca, parula);
colorbar;
set(gca, 'XTick', 1:numel(vars), 'XTickLabel', vars, 'XTickLabelRotation', 35);
set(gca, 'YTick', 1:topN, 'YTickLabel', string(summaryTable.sampleIndex(1:topN)));
xlabel('parameter');
ylabel('sample index');
title(sprintf('Top %d samples', topN));
apply_light_figure_style(gca);

try
    sgtitle('Proxy/parameter sensitivity summary', 'Color','k', 'FontWeight','bold');
catch
end

end

