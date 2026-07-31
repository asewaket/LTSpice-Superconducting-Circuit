function h = plot_phase13A_constitutive_mapping_summary(cfg, roles, TcMap, ...
    WMap, holdoutPlan, prohibited, gates)
%PLOT_PHASE13A_CONSTITUTIVE_MAPPING_SUMMARY Plot Phase 13A diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13A constitutive mapping freeze', ...
    'Color', 'w', 'Position', [120 120 1700 940]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_parameter_roles(roles);
title('parameter role ledger');

nexttile;
plot_mapping_counts(TcMap, WMap);
title('Tc vs connectivity inputs');

nexttile;
plot_holdout_plan(holdoutPlan);
title('leave-one-device-out plan');

nexttile;
plot_prohibited(prohibited);
title('prohibited flexibility');

nexttile;
plot_policy_panel(cfg);
title('transport prediction policy');

nexttile;
plot_gate_summary(gates);
title('Phase 13A gates');

titleHandle = sgtitle( ...
    'Phase 13A constitutive mechanical-to-transport mapping freeze');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13A.figureBaseFile '.png']);
saveas(h, [cfg.phase13A.figureBaseFile '.pdf']);
end

function plot_parameter_roles(T)
if isempty(T)
    empty_panel('missing parameter role ledger');
    return;
end
roles = string(T.parameter_role);
labels = unique(roles, 'stable');
counts = zeros(numel(labels), 1);
for k = 1:numel(labels)
    counts(k) = sum(roles == labels(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('parameter count');
grid on;
end

function plot_mapping_counts(TcMap, WMap)
if isempty(TcMap) || isempty(WMap)
    empty_panel('missing mapping tables');
    return;
end
labels = ["Tc mapping"; "W_ij mapping"];
activeTc = sum(string(TcMap.default_strength_policy) ~= ...
    "weak_optional_predeclared");
activeW = sum(string(WMap.equation_term) ~= "not_in_Wij_first_version");
bar([activeTc; activeW], 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
ylabel('active component count');
grid on;
end

function plot_holdout_plan(T)
if isempty(T)
    empty_panel('missing holdout plan');
    return;
end
bar(height(T), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1, 'XTickLabel', "LOO rows");
ylabel('row count');
ylim([0, max(1, height(T) + 1)]);
grid on;
end

function plot_prohibited(T)
if isempty(T)
    empty_panel('missing prohibited ledger');
    return;
end
bar(height(T), 'FaceColor', [0.85 0.35 0.15]);
set(gca, 'XTick', 1, 'XTickLabel', "prohibited knobs");
ylabel('count');
ylim([0, max(1, height(T) + 1)]);
grid on;
end

function plot_policy_panel(cfg)
cla;
axis off;
text(0.05, 0.78, 'Phase 13A freezes form only:', ...
    'FontWeight', 'bold', 'Color', 'k');
text(0.08, 0.62, '- no R(T) residual inspection', 'Color', 'k');
text(0.08, 0.50, '- no Raman transport fitting', 'Color', 'k');
text(0.08, 0.38, '- no device-specific mechanism knobs', 'Color', 'k');
text(0.08, 0.26, '- LOO prediction required next', 'Color', 'k');
text(0.05, 0.10, "next: " + string(cfg.phase13A.nextPhase), ...
    'Color', [0.70 0.05 0.05], 'FontWeight', 'bold', ...
    'Interpreter', 'none');
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
