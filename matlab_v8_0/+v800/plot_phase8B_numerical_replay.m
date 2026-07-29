function h = plot_phase8B_numerical_replay(cfg, meshReplay, solverReplay, ...
    normalizationReplay, seedReplay, stability, gates)
%PLOT_PHASE8B_NUMERICAL_REPLAY Plot Phase 8B replay summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 8B numerical replay', ...
    'Color', 'w', 'Position', [100 100 1600 860]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_replay_drift_by_class(meshReplay, solverReplay, normalizationReplay, ...
    seedReplay);
title('max |\DeltaS| drift by replay class');

nexttile;
plot_mesh_by_device(meshReplay);
title('mesh replay by device');

nexttile;
plot_normalization_by_device(normalizationReplay);
title('normalization-window replay');

nexttile;
plot_seed_envelope(seedReplay);
title('seed replay envelope');

nexttile;
plot_stability(stability);
title('status stability');

nexttile;
plot_gate_summary(gates);
title('Phase 8B gates');

titleHandle = sgtitle( ...
    'v8.0 Phase 8B frozen-context numerical replay');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase8B.figureBaseFile '.png']);
saveas(h, [cfg.phase8B.figureBaseFile '.pdf']);
end

function plot_replay_drift_by_class(meshT, solverT, normT, seedT)
labels = ["mesh"; "solver"; "normalization"; "seed"];
values = [
    max_abs_or_zero(meshT.deltaS_drift)
    max_abs_or_zero(solverT.deltaS_drift)
    max_abs_or_zero(normT.deltaS_drift)
    max_abs_or_zero(seedT.deltaS_drift)
    ];
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('max |\DeltaS drift|');
grid on;
end

function plot_mesh_by_device(T)
if isempty(T)
    empty_panel('missing mesh replay');
    return;
end
devices = unique(T.device, 'stable');
values = max_abs_by_device(T, devices);
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('max |\DeltaS drift|');
grid on;
end

function plot_normalization_by_device(T)
if isempty(T)
    empty_panel('missing normalization replay');
    return;
end
devices = unique(T.device, 'stable');
values = max_abs_by_device(T, devices);
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('max |\DeltaS drift|');
grid on;
end

function plot_seed_envelope(T)
if isempty(T)
    empty_panel('missing seed replay');
    return;
end
devices = unique(T.device, 'stable');
values = max_abs_by_device(T, devices);
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('max |\DeltaS drift|');
grid on;
end

function plot_stability(T)
if isempty(T)
    empty_panel('missing stability table');
    return;
end
x = 1:height(T);
yyaxis left;
bar(x - 0.15, T.max_abs_deltaS_drift, 0.30, ...
    'FaceColor', [0.25 0.55 0.85], ...
    'DisplayName', 'max |\DeltaS drift|');
ylabel('max |\DeltaS drift|');
ylim([0, max([0.02; 1.15 .* T.max_abs_deltaS_drift])]);

yyaxis right;
plot(x + 0.15, T.direction_change_count, 'o-', ...
    'Color', [0.95 0.45 0.15], ...
    'MarkerFaceColor', [0.95 0.45 0.15], ...
    'LineWidth', 1.2, ...
    'DisplayName', 'direction changes');
ylabel('direction-change count');
ylim([0, max([1; 1.15 .* T.direction_change_count])]);

set(gca, 'XTick', x, 'XTickLabel', T.device);
xtickangle(25);
legend('Location', 'best');
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.outcome == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function values = max_abs_by_device(T, devices)
values = zeros(numel(devices), 1);
for k = 1:numel(devices)
    idx = T.device == devices(k);
    values(k) = max_abs_or_zero(T.deltaS_drift(idx));
end
end

function value = max_abs_or_zero(x)
if isempty(x)
    value = 0;
else
    x = abs(x);
    x = x(isfinite(x));
    if isempty(x)
        value = 0;
    else
        value = max(x);
    end
end
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', 'Color', 'k');
axis off;
end

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
legendList = findall(h, 'Type', 'Legend');
for k = 1:numel(legendList)
    set(legendList(k), 'TextColor', 'k', 'Color', 'w', ...
        'EdgeColor', [0.4 0.4 0.4]);
end
end
