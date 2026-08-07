function h = plot_phase16B_sensitivity_conditioning_summary(cfg, ...
    normalizedSensitivity, correlationMatrix, singularValues, ...
    deviceSensitivity, recoverabilityUpdate, gateSummary)
%PLOT_PHASE16B_SENSITIVITY_CONDITIONING_SUMMARY Plot Phase 16B diagnostics.

h = figure('Name', 'v9 Phase 16B sensitivity conditioning', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_sensitivity_heatmap(normalizedSensitivity);
plot_correlation_heatmap(correlationMatrix);
plot_singular_values(singularValues);
plot_device_information(deviceSensitivity);
plot_recoverability_update(recoverabilityUpdate);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 16B reduced-parameter sensitivity and conditioning', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase16B.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase16B.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_sensitivity_heatmap(T)
nexttile;
[M, rowNames, colNames] = long_to_matrix(T, "observable", "parameter", ...
    "normalized_sensitivity");
imagesc(abs(M));
colormap(gca, parula(8));
colorbar;
set(gca, 'XTick', 1:numel(colNames), 'XTickLabel', colNames);
set(gca, 'YTick', 1:numel(rowNames), 'YTickLabel', rowNames);
xtickangle(35);
title('normalized sensitivity |S|');
end

function plot_correlation_heatmap(T)
nexttile;
[M, rowNames, colNames] = long_to_matrix(T, "parameter_i", ...
    "parameter_j", "correlation");
imagesc(M, [-1 1]);
colormap(gca, redblue_colormap());
colorbar;
set(gca, 'XTick', 1:numel(colNames), 'XTickLabel', colNames);
set(gca, 'YTick', 1:numel(rowNames), 'YTickLabel', rowNames);
xtickangle(35);
title('approximate parameter correlation');
end

function plot_singular_values(T)
nexttile;
semilogy(T.mode, T.relative_to_max, '-o', 'LineWidth', 1.5);
yline(1e-2, '--', 'effective-rank threshold', 'Color', [0.3 0.3 0.3]);
xlabel('mode');
ylabel('\sigma / \sigma_1');
title('singular-value spectrum');
grid on;
end

function plot_device_information(T)
nexttile;
[M, rowNames, colNames] = long_to_matrix(T, "device", "parameter", ...
    "device_information_score");
imagesc(M);
colormap(gca, parula(8));
colorbar;
set(gca, 'XTick', 1:numel(colNames), 'XTickLabel', colNames);
set(gca, 'YTick', 1:numel(rowNames), 'YTickLabel', rowNames);
xtickangle(35);
title('device-by-parameter information');
end

function plot_recoverability_update(T)
nexttile;
classes = unique(string(T.phase16B_recoverability), 'stable');
counts = zeros(numel(classes), 1);
for i = 1:numel(classes)
    counts(i) = sum(string(T.phase16B_recoverability) == classes(i));
end
bar(counts);
set(gca, 'XTickLabel', classes);
xtickangle(35);
ylabel('parameter count');
title('updated recoverability');
grid on;
end

function plot_gate_summary(T)
nexttile;
cats = ["pass"; "fail"; "not_run"];
counts = zeros(numel(cats), 1);
for i = 1:numel(cats)
    counts(i) = sum(string(T.outcome) == cats(i));
end
bar(counts);
set(gca, 'XTickLabel', cats);
ylabel('gate count');
title('Phase 16B gates');
grid on;
end

function [M, rowNames, colNames] = long_to_matrix(T, rowVar, colVar, valueVar)
rowNames = unique(string(T.(rowVar)), 'stable');
colNames = unique(string(T.(colVar)), 'stable');
M = nan(numel(rowNames), numel(colNames));
for i = 1:numel(rowNames)
    for j = 1:numel(colNames)
        idx = string(T.(rowVar)) == rowNames(i) & ...
            string(T.(colVar)) == colNames(j);
        if any(idx)
            M(i, j) = T.(valueVar)(find(idx, 1, 'first'));
        end
    end
end
end

function cmap = redblue_colormap()
n = 128;
r = [(0:n/2-1).'/(n/2); ones(n/2, 1)];
g = [(0:n/2-1).'/(n/2); flipud((0:n/2-1).'/(n/2))];
b = [ones(n/2, 1); flipud((0:n/2-1).'/(n/2))];
cmap = [r g b];
end

function force_light_theme(h)
axesHandles = findall(h, 'Type', 'axes');
for ax = reshape(axesHandles, 1, [])
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82 0.82 0.82], ...
        'MinorGridColor', [0.90 0.90 0.90]);
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
    if ~isempty(ax.ZLabel)
        ax.ZLabel.Color = 'k';
    end
end
end
