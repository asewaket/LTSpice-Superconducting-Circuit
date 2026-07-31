function h = plot_phase13C_full_RT_execution_summary(cfg, foldTraining, ...
    residuals, transitionMetrics, probePairs, gates)
%PLOT_PHASE13C_FULL_RT_EXECUTION_SUMMARY Plot Phase 13C.2 diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13C.2 full RT execution', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_fold_objective(foldTraining);
title('LODO training objective');

nexttile;
plot_residuals(residuals);
title('held-out full-curve residuals');

nexttile;
plot_T50_residuals(transitionMetrics);
title('held-out T50 residuals');

nexttile;
plot_probe_pairs(probePairs);
title('paired-probe asymmetry');

nexttile;
plot_gate_summary(gates);
title('Phase 13C.2 execution gates');

nexttile;
plot_handoff_note();
title('interpretation policy');

titleHandle = sgtitle( ...
    'Phase 13C.2 full shared R(T) execution diagnostics');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13C2.figureBaseFile '.png']);
saveas(h, [cfg.phase13C2.figureBaseFile '.pdf']);
end

function plot_fold_objective(T)
if isempty(T)
    empty_panel('missing fold training manifest');
    return;
end
bar(T.training_objective, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.heldout_device));
xtickangle(25);
ylabel('training objective');
grid on;
end

function plot_residuals(T)
if isempty(T)
    empty_panel('missing residual table');
    return;
end
mask = string(T.probe_role) == "primary";
Tp = T(mask, :);
bar(Tp.residual_value, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(Tp), 'XTickLabel', string(Tp.device));
xtickangle(25);
ylabel('mean squared residual');
grid on;
end

function plot_T50_residuals(T)
if isempty(T)
    empty_panel('missing transition metrics');
    return;
end
mask = string(T.metric) == "T50" & string(T.probe_role) == "primary";
Tp = T(mask, :);
bar(Tp.residual, 'FaceColor', [0.25 0.55 0.85]);
hold on;
yline(0, 'k-');
set(gca, 'XTick', 1:height(Tp), 'XTickLabel', string(Tp.device));
xtickangle(25);
ylabel('\DeltaT50 (K)');
grid on;
end

function plot_probe_pairs(T)
if isempty(T) || all(string(T.device) == "")
    empty_panel('no paired probes scored');
    return;
end
bar(T.asymmetry_score, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('A_{probe}(T) score');
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gates');
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

function plot_handoff_note()
axis off;
text(0.05, 0.75, 'Execution closure means the experiment ran honestly.', ...
    'FontWeight', 'bold', 'Color', 'k');
text(0.05, 0.55, 'Predictive adequacy is deferred to Phase 13D.', ...
    'Color', 'k');
text(0.05, 0.35, 'Poor fit remains a valid completed execution outcome.', ...
    'Color', 'k');
text(0.05, 0.15, 'No Phase 6 labels, Raman targets, or device-specific knobs.', ...
    'Color', 'k');
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
