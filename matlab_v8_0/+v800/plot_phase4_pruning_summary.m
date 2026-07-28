function h = plot_phase4_pruning_summary(cfg, mechanismSummary, pruningDecisions)
%PLOT_PHASE4_PRUNING_SUMMARY Compact Phase 4 identifiability figure.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 4 identifiability/pruning summary', ...
    'Color', 'w', 'Position', [100 100 1450 850]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_mode_bars(mechanismSummary, 'meanRank', 'mean rank, lower is better');
title('mean rank by mechanism and mode');

nexttile;
plot_top_two_support(mechanismSummary);
title('top-two support');

nexttile;
plot_baseline_margin(mechanismSummary);
title('baseline improvement magnitude');

nexttile;
plot_decision_counts(pruningDecisions);
title('Phase 4 decision classes');

sgtitle('v8.0 Phase 4 AS006 identifiability and pruning diagnostics');
apply_light_style(h);

saveas(h, [cfg.figureBaseFile '.png']);
saveas(h, [cfg.figureBaseFile '.pdf']);
end

function plot_mode_bars(T, valueName, ylab)
if isempty(T)
    text(0.5, 0.5, 'no data', 'HorizontalAlignment', 'center');
    return;
end

mechanisms = unique(T.mechanism, 'stable');
modes = unique(T.calibrationMode, 'stable');
Y = NaN(numel(mechanisms), numel(modes));
for i = 1:numel(mechanisms)
    for j = 1:numel(modes)
        idx = T.mechanism == mechanisms(i) & T.calibrationMode == modes(j);
        if any(idx)
            Y(i, j) = T.(valueName)(find(idx, 1, 'first'));
        end
    end
end

bar(Y);
set(gca, 'XTick', 1:numel(mechanisms), 'XTickLabel', mechanisms);
xtickangle(30);
ylabel(ylab);
legend(cellstr(modes), 'Location', 'best');
grid on;
end

function plot_top_two_support(T)
if isempty(T)
    text(0.5, 0.5, 'no data', 'HorizontalAlignment', 'center');
    return;
end

mechanisms = unique(T.mechanism, 'stable');
modes = unique(T.calibrationMode, 'stable');
Y = NaN(numel(mechanisms), numel(modes));
for i = 1:numel(mechanisms)
    for j = 1:numel(modes)
        idx = T.mechanism == mechanisms(i) & T.calibrationMode == modes(j);
        if any(idx)
            Y(i, j) = T.topTwoRate(find(idx, 1, 'first'));
        end
    end
end

bar(Y);
hold on;
groupWidth = min(0.8, numel(modes) / (numel(modes) + 1.5));
for j = 1:numel(modes)
    x = (1:numel(mechanisms)) - groupWidth / 2 + ...
        (2 * j - 1) * groupWidth / (2 * numel(modes));
    zeroIdx = isfinite(Y(:, j)) & Y(:, j) == 0;
    plot(x(zeroIdx), 0.025 * ones(sum(zeroIdx), 1), 'kx', ...
        'LineWidth', 1.0, 'MarkerSize', 5, 'HandleVisibility', 'off');
end
hold off;

set(gca, 'XTick', 1:numel(mechanisms), 'XTickLabel', mechanisms);
xtickangle(30);
ylabel('fraction of seeds ranked 1 or 2');
legend(cellstr(modes), 'Location', 'best');
ylim([0 1]);
grid on;
end

function plot_baseline_margin(T)
if isempty(T)
    text(0.5, 0.5, 'no data', 'HorizontalAlignment', 'center');
    return;
end

isBaseline = T.mechanism == "no weak links" | ...
    T.mechanism == "central-lane / 1D-like";
T = T(~isBaseline, :);
if isempty(T)
    text(0.5, 0.5, 'no candidate data', 'HorizontalAlignment', 'center');
    return;
end

mechanisms = unique(T.mechanism, 'stable');
modes = unique(T.calibrationMode, 'stable');
Y = NaN(numel(mechanisms), numel(modes));
for i = 1:numel(mechanisms)
    for j = 1:numel(modes)
        idx = T.mechanism == mechanisms(i) & T.calibrationMode == modes(j);
        if any(idx)
            Y(i, j) = -T.meanDeltaVsNoWeak(find(idx, 1, 'first'));
        end
    end
end

bar(Y);
yline(0, 'k-', 'LineWidth', 0.8);
set(gca, 'XTick', 1:numel(mechanisms), 'XTickLabel', mechanisms);
xtickangle(30);
ylabel('candidate mean score gain vs no weak links');
legend(cellstr(modes), 'Location', 'best');
grid on;
end

function plot_decision_counts(T)
if isempty(T)
    text(0.5, 0.5, 'no data', 'HorizontalAlignment', 'center');
    return;
end
decisions = unique(T.decision, 'stable');
counts = zeros(numel(decisions), 1);
for k = 1:numel(decisions)
    counts(k) = sum(T.decision == decisions(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(decisions), 'XTickLabel', decisions);
xtickangle(25);
ylabel('mechanism count');
grid on;
end

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 11, 'Box', 'on');
    grid(ax, 'on');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
legList = findall(h, 'Type', 'legend');
for k = 1:numel(legList)
    set(legList(k), 'Color', 'w', 'TextColor', 'k', ...
        'EdgeColor', [0.35 0.35 0.35]);
end
end
