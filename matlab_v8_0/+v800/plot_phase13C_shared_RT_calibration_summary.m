function h = plot_phase13C_shared_RT_calibration_summary(cfg, lock, ...
    objective, loo, pairs, familyHoldouts, gates)
%PLOT_PHASE13C_SHARED_RT_CALIBRATION_SUMMARY Plot Phase 13C setup diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13C shared RT calibration setup', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_RT_lock(lock);
title('R(T) data lock');

nexttile;
plot_objective(objective);
title('frozen objective weights');

nexttile;
plot_LOO(loo);
title('leave-one-device-out folds');

nexttile;
plot_probe_pairs(pairs);
title('paired-probe plan');

nexttile;
plot_family_holdouts(familyHoldouts);
title('geometry-family stress tests');

nexttile;
plot_gate_summary(gates);
title('Phase 13C setup gates');

titleHandle = sgtitle( ...
    'Phase 13C shared R(T) calibration data/objective lock');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13C.figureBaseFile '.png']);
saveas(h, [cfg.phase13C.figureBaseFile '.pdf']);
end

function plot_RT_lock(T)
if isempty(T)
    empty_panel('missing R(T) data lock');
    return;
end
vals = [double(T.has_R1_RT), double(T.has_R2_RT), ...
    double(T.has_primary_RT), double(T.has_secondary_RT)];
bar(vals);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('available = 1');
legend({'R1', 'R2', 'primary', 'secondary'}, ...
    'Location', 'southoutside', 'Interpreter', 'none');
grid on;
end

function plot_objective(T)
if isempty(T)
    empty_panel('missing objective');
    return;
end
bar(T.weight, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.metric));
xtickangle(30);
ylabel('weight');
ylim([0, max(0.35, max(T.weight) + 0.05)]);
grid on;
end

function plot_LOO(T)
if isempty(T)
    empty_panel('missing LOO manifest');
    return;
end
statuses = ["not_run_pending_full_RT_solver"; "completed"; "failed"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.execution_status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(25);
ylabel('fold count');
grid on;
end

function plot_probe_pairs(T)
if isempty(T)
    empty_panel('no paired probes available');
    return;
end
bar(ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('joint pair declared');
ylim([0 1.2]);
grid on;
end

function plot_family_holdouts(T)
if isempty(T)
    empty_panel('missing family holdouts');
    return;
end
bar(ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.family_holdout));
xtickangle(25);
ylabel('predeclared = 1');
ylim([0 1.2]);
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
    counts(k) = sum(string(T.outcome) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', ...
    'Color', 'k');
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
end
