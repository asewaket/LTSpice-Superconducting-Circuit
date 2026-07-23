function h = plot_v744_bottleneck_summary(sweepTable)
%PLOT_V744_BOTTLENECK_SUMMARY Summary of physical bottleneck W_ij ablations.

if isempty(sweepTable)
    error('plot_v744_bottleneck_summary requires a nonempty table.');
end

h = figure('Name', 'v7.4.4 physical bottleneck Wij summary', ...
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

sgtitle('v7.4.4 AS006 physical bottleneck W_{ij} sweep');
apply_v744_summary_light_style(h);

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

function apply_v744_summary_light_style(h)
%APPLY_V744_SUMMARY_LIGHT_STYLE Local style guard for thesis-ready output.
%
% Keep this local to avoid depending on whichever apply_light_figure_style.m
% happens to be first on MATLAB's global path.

set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');

for k = 1:numel(axList)
    ax = axList(k);
    set(ax, ...
        'Color', 'w', ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, ...
        'FontSize', 11, ...
        'Box', 'on');
    grid(ax, 'on');

    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';

end

legList = findall(h, 'Type', 'legend');
for k = 1:numel(legList)
    set(legList(k), 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.35 0.35 0.35]);
end

textList = findall(h, 'Type', 'text');
for k = 1:numel(textList)
    set(textList(k), 'Color', 'k');
end

end
