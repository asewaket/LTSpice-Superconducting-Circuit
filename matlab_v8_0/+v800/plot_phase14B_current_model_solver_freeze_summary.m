function h = plot_phase14B_current_model_solver_freeze_summary(cfg, ...
    currentSpec, parameterLedger, solverSpec, limitingPlan, holdout, ...
    prohibited, gates)
%PLOT_PHASE14B_CURRENT_MODEL_SOLVER_FREEZE_SUMMARY Plot 14B.1 freeze.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.1 current-model solver freeze', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_model_components(currentSpec);
title('current-model components');

nexttile;
plot_parameter_roles(parameterLedger);
title('parameter role ledger');

nexttile;
plot_solver_statuses(cfg, solverSpec);
title('solver status contract');

nexttile;
plot_limiting_cases(limitingPlan);
title('Phase 14B.2 limiting cases');

nexttile;
plot_handoff_text(cfg, holdout, prohibited);
title('frozen nonlinear policy');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.1 gates');

titleHandle = sgtitle('Phase 14B.1 current-dependent network feasibility freeze');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14B.figureBaseFile '.png']);
saveas(h, [cfg.phase14B.figureBaseFile '.pdf']);
end

function plot_model_components(T)
statuses = unique(string(T.status), 'stable');
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(25);
ylabel('component count');
grid on;
end

function plot_parameter_roles(T)
roles = unique(string(T.role), 'stable');
counts = zeros(numel(roles), 1);
for k = 1:numel(roles)
    counts(k) = sum(string(T.role) == roles(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(roles), 'XTickLabel', roles);
xtickangle(25);
ylabel('parameter count');
grid on;
end

function plot_solver_statuses(cfg, T)
declared = cfg.phase14B.allowedSolverStatuses;
counts = zeros(numel(declared), 1);
for k = 1:numel(declared)
    counts(k) = any(string(T.step) == "allowed_solver_status:" + declared(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(declared), 'XTickLabel', declared);
xtickangle(35);
ylabel('declared flag');
ylim([0 1.2]);
grid on;
end

function plot_limiting_cases(T)
bar(ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.case_id));
xtickangle(35);
ylabel('declared case');
ylim([0 1.2]);
grid on;
end

function plot_handoff_text(cfg, holdout, prohibited)
axis off;
lines = [
    "Equilibrium baseline: " + cfg.phase14B.equilibriumBaseline
    "Variants: " + cfg.phase14B.baselineModelVariant + " vs " + ...
        cfg.phase14B.currentModelVariant
    "Candidate devices: " + strjoin(string(holdout.device), "|")
    "Thermal feedback: blocked"
    "Prohibited items: " + string(height(prohibited))
    "Next: synthetic limiting-case verification"
    ];
for k = 1:numel(lines)
    text(0.05, 0.90 - 0.13 * (k - 1), lines(k), ...
        'Units', 'normalized', 'Color', 'k', 'FontWeight', 'bold', ...
        'Interpreter', 'none');
end
end

function plot_gate_summary(T)
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
