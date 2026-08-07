function h = plot_phase16C_profile_posterior_summary(cfg, profile1DSummary, ...
    profile2DPairManifest, profile2DSurfaces, marginalIntervals, ...
    parameterCorrelation, predictiveEnvelopeSummary, gateSummary)
%PLOT_PHASE16C_PROFILE_POSTERIOR_SUMMARY Plot Phase 16C diagnostics.

h = figure('Name', 'v9 Phase 16C profile posterior exploration', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_profile_widths(profile1DSummary);
plot_selected_degeneracy(profile2DPairManifest, profile2DSurfaces);
plot_correlation(parameterCorrelation);
plot_intervals(marginalIntervals);
plot_predictive_envelopes(predictiveEnvelopeSummary);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 16C profile-objective and pseudo-posterior exploration', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase16C.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase16C.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_profile_widths(T)
nexttile;
bar(T.support_width_fraction);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.parameter);
xtickangle(35);
ylabel('support width / frozen range');
title('1D profile support widths');
grid on;
end

function plot_selected_degeneracy(manifest, surfaces)
nexttile;
if isempty(manifest)
    text(0.5, 0.5, 'no degeneracy pair', 'HorizontalAlignment', 'center');
    axis off;
    return
end
pair = string(manifest.pair_id(1));
rows = surfaces(string(surfaces.pair_id) == pair, :);
xi = unique(rows.theta_i, 'stable');
yj = unique(rows.theta_j, 'stable');
Z = nan(numel(yj), numel(xi));
for a = 1:numel(xi)
    for b = 1:numel(yj)
        idx = rows.theta_i == xi(a) & rows.theta_j == yj(b);
        if any(idx)
            Z(b, a) = rows.objective_delta(find(idx, 1));
        end
    end
end
imagesc(xi, yj, Z);
set(gca, 'YDir', 'normal');
colorbar;
xlabel(string(manifest.parameter_i(1)));
ylabel(string(manifest.parameter_j(1)));
title('2D profile valley: ' + pair, 'Interpreter', 'none');
end

function plot_correlation(T)
nexttile;
[M, rowNames, colNames] = long_to_matrix(T, "parameter_i", ...
    "parameter_j", "correlation");
imagesc(M, [-1 1]);
colormap(gca, redblue_colormap());
colorbar;
set(gca, 'XTick', 1:numel(colNames), 'XTickLabel', colNames);
set(gca, 'YTick', 1:numel(rowNames), 'YTickLabel', rowNames);
xtickangle(35);
title('pseudo-posterior correlation');
end

function plot_intervals(T)
nexttile;
x = 1:height(T);
errLow = T.median_value - T.lower16;
errHigh = T.upper84 - T.median_value;
errorbar(x, T.median_value, errLow, errHigh, 'o', ...
    'LineWidth', 1.5);
yline(1, '--', 'nominal', 'Color', [0.3 0.3 0.3]);
set(gca, 'XTick', x, 'XTickLabel', T.parameter);
xtickangle(35);
ylabel('parameter scale');
title('objective-weighted intervals');
grid on;
end

function plot_predictive_envelopes(T)
nexttile;
bar(T.envelope_width);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.observable);
xtickangle(35);
ylabel('84-16 envelope width');
title('linearized predictive envelopes');
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
title('Phase 16C gates');
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
