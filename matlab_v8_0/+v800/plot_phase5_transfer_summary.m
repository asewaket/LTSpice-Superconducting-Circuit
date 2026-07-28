function h = plot_phase5_transfer_summary(cfg, transferScores, deviceSummary, loo, gateResults)
%PLOT_PHASE5_TRANSFER_SUMMARY Compact Phase 5 transfer diagnostic figure.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5 six-device transfer summary', ...
    'Color', 'w', 'Position', [120 120 1500 860]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_score_heatmap(transferScores);
title('best score by device and mechanism');

nexttile;
plot_primary_vs_control(deviceSummary);
title('transfer primary vs required controls');

nexttile;
plot_loo_status(loo);
title('leave-one-device-out status');

nexttile;
plot_gate_status(gateResults);
title('Phase 5 gate status');

sgtitle('v8.0 Phase 5 transfer diagnostics');
apply_light_style(h);

saveas(h, [cfg.figureBaseFile '.png']);
saveas(h, [cfg.figureBaseFile '.pdf']);
end

function plot_score_heatmap(T)
idx = T.evidenceAvailable & T.includeInTransferSweep;
if ~any(idx)
    text(0.5, 0.5, 'no scored transfer evidence', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
D = unique(T.device, 'stable');
M = unique(T.mechanism(idx), 'stable');
Z = NaN(numel(D), numel(M));
for i = 1:numel(D)
    for j = 1:numel(M)
        sidx = T.device == D(i) & T.mechanism == M(j) & ...
            T.evidenceAvailable & T.includeInTransferSweep;
        if any(sidx)
            Z(i, j) = min(T.score(sidx));
        end
    end
end
imagesc(Z, 'AlphaData', isfinite(Z));
colorbar;
set(gca, 'Color', [0.88 0.88 0.88], 'XTick', 1:numel(M), ...
    'XTickLabel', M, 'YTick', 1:numel(D), 'YTickLabel', D, ...
    'Tag', 'phase5_heatmap_axes');
xtickangle(30);
ylabel('device');
end

function plot_primary_vs_control(T)
idx = T.evidenceAvailable;
if ~any(idx)
    text(0.5, 0.5, 'no scored device summaries', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
S = T(idx, :);
labels = strcat(S.device, " ", S.calibrationMode);
Y = [S.bestPrimaryScore, S.bestControlScore];
bar(Y);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('best score, lower is better');
legend({'best primary','best required control'}, 'Location', 'best');
grid on;
end

function plot_loo_status(T)
if isempty(T)
    text(0.5, 0.5, 'no LOO rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
statuses = ["pass"; "fail"; "incomplete"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.status == statuses(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('LOO row count');
grid on;
end

function plot_gate_status(T)
if isempty(T)
    text(0.5, 0.5, 'no gate rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
statuses = unique(T.status, 'stable');
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.status == statuses(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    if strcmp(get(ax, 'Tag'), 'phase5_heatmap_axes')
        axColor = [0.88 0.88 0.88];
    else
        axColor = 'w';
    end
    set(ax, 'Color', axColor, 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 11, 'Box', 'on');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
legList = findall(h, 'Type', 'legend');
for k = 1:numel(legList)
    set(legList(k), 'Color', 'w', 'TextColor', 'k', ...
        'EdgeColor', [0.35 0.35 0.35]);
end
colorbarList = findall(h, 'Type', 'ColorBar');
for k = 1:numel(colorbarList)
    set(colorbarList(k), 'Color', 'k');
end
end
