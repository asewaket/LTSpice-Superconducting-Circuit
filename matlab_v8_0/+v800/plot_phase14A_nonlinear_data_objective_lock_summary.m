function h = plot_phase14A_nonlinear_data_objective_lock_summary(cfg, ...
    manifest, objectiveSpec, holdout, prohibited, gates)
%PLOT_PHASE14A_NONLINEAR_DATA_OBJECTIVE_LOCK_SUMMARY Plot 14A lock.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14A nonlinear data/objective lock', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_device_availability(manifest);
title('nonlinear observable availability');

nexttile;
plot_observable_roles(manifest);
title('Phase 14/15 observable split');

nexttile;
plot_objective_weights(objectiveSpec);
title('frozen nonlinear objective weights');

nexttile;
plot_holdout_policy(holdout);
title('calibration/holdout candidates');

nexttile;
plot_policy_text(cfg, prohibited);
title('frozen model policy');

nexttile;
plot_gate_summary(gates);
title('Phase 14A gates');

titleHandle = sgtitle('Phase 14A nonlinear data and objective lock');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14A.figureBaseFile '.png']);
saveas(h, [cfg.phase14A.figureBaseFile '.pdf']);
end

function plot_device_availability(T)
devices = string(T.device);
available = double(T.nonlinear_dataset_available);
fieldOnly = double(string(T.allowed_model_use) == ...
    "field_dependent_context_deferred_to_phase15");
bar([available fieldOnly]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('availability flag');
legend(["dVdI(I,T)"; "field context deferred"], 'Location', 'best');
ylim([0 1.2]);
grid on;
end

function plot_observable_roles(T)
roles = ["current_temperature_candidate"; ...
    "phase15_field_context_deferred"; "not_available"];
counts = zeros(numel(roles), 1);
for k = 1:numel(roles)
    counts(k) = sum(string(T.phase14A_role) == roles(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(roles), 'XTickLabel', roles);
xtickangle(25);
ylabel('device count');
grid on;
end

function plot_objective_weights(T)
bar(T.weight, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.term));
xtickangle(35);
ylabel('weight');
grid on;
end

function plot_holdout_policy(T)
if isempty(T)
    empty_panel('missing holdout manifest');
    return;
end
bar(ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('candidate row');
ylim([0 1.2]);
grid on;
end

function plot_policy_text(cfg, prohibited)
axis off;
lines = [
    "Equilibrium baseline: " + cfg.phase14A.equilibriumBaseline
    "R(T) status: " + cfg.phase14A.equilibriumRTStatus
    "Shared quantitative R(T): " + string(cfg.phase14A.sharedQuantitativeRTPredictor)
    "Interface term: " + cfg.phase14A.interfaceTransferTerm
    "Prohibited items: " + string(height(prohibited))
    "Electrothermal terms: blocked until 14C"
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
