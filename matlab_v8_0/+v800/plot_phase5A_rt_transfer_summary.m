function h = plot_phase5A_rt_transfer_summary(cfg, ledger, summary, loo, gates)
%PLOT_PHASE5A_RT_TRANSFER_SUMMARY Level-A frozen R(T) transfer figure.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5A frozen R(T) transfer summary', ...
    'Color', 'w', 'Position', [120 120 1500 860]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_score_heatmap(ledger);
title('best Level-A score by device and mechanism');

nexttile;
plot_primary_vs_controls(summary);
title('frozen primary track vs protected controls');

nexttile;
plot_loo_status(loo);
title('primary R(T) leave-one-device-out');

nexttile;
plot_gate_status(gates);
title('Phase 5A gate status');

sgtitle('v8.0 Phase 5A frozen primary R(T) transfer diagnostics');
apply_light_style(h);

saveas(h, [cfg.phase5A.figureBaseFile '.png']);
saveas(h, [cfg.phase5A.figureBaseFile '.pdf']);
end

function plot_score_heatmap(T)
idx = T.run_status == "scored";
if ~any(idx)
    text(0.5, 0.5, 'no scored Level-A ledger rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
D = unique(T.device, 'stable');
M = unique(T.mechanism(idx), 'stable');
Z = NaN(numel(D), numel(M));
for i = 1:numel(D)
    for j = 1:numel(M)
        sidx = idx & T.device == D(i) & T.mechanism == M(j);
        if any(sidx)
            Z(i, j) = min(T.total_LevelA_score(sidx));
        end
    end
end
imagesc(Z, 'AlphaData', isfinite(Z));
colorbar;
set(gca, 'Color', [0.88 0.88 0.88], 'XTick', 1:numel(M), ...
    'XTickLabel', M, 'YTick', 1:numel(D), 'YTickLabel', D, ...
    'Tag', 'phase5A_heatmap_axes');
xtickangle(30);
ylabel('device');
end

function plot_primary_vs_controls(T)
idx = T.primary_curve_scored;
if ~any(idx)
    text(0.5, 0.5, 'no scored device summaries', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
S = T(idx, :);
labels = S.device;
Y = [S.best_primary_score, S.best_challenger_score, S.best_control_score];
bar(Y);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('best score, lower is better');
legend({'transfer primary','required challengers','protected controls'}, ...
    'Location', 'best');
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
statuses = ["pass"; "fail"; "incomplete"];
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
    if strcmp(get(ax, 'Tag'), 'phase5A_heatmap_axes')
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
