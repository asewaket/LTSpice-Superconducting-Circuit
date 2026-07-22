function h = plot_v743_wij_ablation_summary(sweepTable)
%PLOT_V743_WIJ_ABLATION_SUMMARY Summary of controlled W_ij ablations.

if isempty(sweepTable)
    error('plot_v743_wij_ablation_summary requires a nonempty table.');
end

h = figure('Name', 'v7.4.3 controlled Wij ablation summary', ...
    'Color', 'w', 'Position', [80 80 1450 900]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_sorted_scores(sweepTable, 'shapeScore', 'shape-controlled score');
title('shape-controlled ranking');

nexttile;
plot_sorted_scores(sweepTable, 'conductanceScore', 'conductance-preserving score');
title('conductance-preserving ranking');

nexttile;
plot_topology_summary(sweepTable, 'shapeScore');
title('best shape score by W_{ij} topology');

nexttile;
plot_topology_summary(sweepTable, 'conductanceScore');
title('best conductance-preserving score by W_{ij} topology');

sgtitle('v7.4.3 controlled AS006 weak-link transparency ablation');
apply_light_figure_style(h);

end

function plot_sorted_scores(T, scoreName, ylab)

valid = isfinite(T.(scoreName));
T = sortrows(T(valid,:), scoreName);
plot(1:height(T), T.(scoreName), '-o', 'LineWidth', 1.6);
xlabel('ranked case');
ylabel(ylab);
grid on;
if height(T) > 0
    text(0.03, 0.92, sprintf('best: %s / %s', ...
        string(T.topology(1)), string(T.calibrationMode(1))), ...
        'Units', 'normalized', 'FontSize', 9, ...
        'BackgroundColor', 'w', 'EdgeColor', [0.85 0.85 0.85]);
end

end

function plot_topology_summary(T, scoreName)

valid = isfinite(T.(scoreName));
T = T(valid,:);
topologies = unique(string(T.topology), 'stable');
vals = NaN(size(topologies));
for k = 1:numel(topologies)
    rows = string(T.topology) == topologies(k);
    here = T.(scoreName)(rows);
    here = here(isfinite(here));
    if ~isempty(here)
        vals(k) = min(here);
    end
end
bar(vals);
set(gca, 'XTick', 1:numel(topologies), 'XTickLabel', topologies);
xtickangle(30);
ylabel('best score, lower is better');
grid on;

end
