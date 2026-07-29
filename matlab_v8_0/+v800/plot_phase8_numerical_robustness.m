function h = plot_phase8_numerical_robustness(cfg, schemaAudit, ...
    reproducibilityAudit, implementationAudit, gates, numericalTestPlan)
%PLOT_PHASE8_NUMERICAL_ROBUSTNESS Plot Phase 8A audit summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 8 numerical robustness', ...
    'Color', 'w', 'Position', [100 100 1600 860]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_schema_audit(schemaAudit);
title('schema contract');

nexttile;
plot_reproducibility_audit(reproducibilityAudit);
title('reproducibility audit');

nexttile;
plot_test_plan(numericalTestPlan);
title('Phase 8A/8B test status');

nexttile;
plot_implementation_audit(implementationAudit);
title('implementation checks');

nexttile;
plot_contextual_scores(cfg);
title('frozen real-device context');

nexttile;
plot_gate_summary(gates);
title('Phase 8A gates');

titleHandle = sgtitle( ...
    'v8.0 Phase 8A numerical/implementation robustness audit');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase8.figureBaseFile '.png']);
saveas(h, [cfg.phase8.figureBaseFile '.pdf']);
end

function plot_schema_audit(T)
if isempty(T)
    empty_panel('missing schema audit');
    return;
end
bar(T.missing_count, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-', 'HandleVisibility', 'off');
set(gca, 'XTick', 1:height(T), 'XTickLabel', short_labels(T.artifact_id));
xtickangle(30);
ylabel('missing required columns');
grid on;
end

function plot_reproducibility_audit(T)
if isempty(T)
    empty_panel('missing reproducibility audit');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = status_counts(T.outcome, statuses);
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('check count');
grid on;
end

function plot_test_plan(T)
if isempty(T)
    empty_panel('missing test plan');
    return;
end
statuses = ["completed_in_phase8A"; "declared_for_phase8B"; "not_run"];
counts = status_counts(T.status, statuses);
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(20);
ylabel('test count');
grid on;
end

function plot_implementation_audit(T)
if isempty(T)
    empty_panel('missing implementation audit');
    return;
end
bar([T.observed_count, T.expected_count]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', short_labels(T.item));
xtickangle(30);
ylabel('count');
legend(["observed", "expected"], 'Location', 'best');
grid on;
end

function plot_contextual_scores(cfg)
pathValue = cfg.phase6.sixDeviceEvidenceMatrixFile;
if ~exist(pathValue, 'file')
    empty_panel('missing Phase 6 matrix');
    return;
end
T = readtable(pathValue, 'TextType', 'string');
if ~all(ismember(["device", "phase5D2_DeltaS", "phase5D2_Z"], ...
        string(T.Properties.VariableNames)))
    empty_panel('missing contextual score columns');
    return;
end
yyaxis left;
bar(T.phase5D2_DeltaS, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-', 'HandleVisibility', 'off');
ylabel('\DeltaS = S_{structured} - S_{M0*}');
yyaxis right;
plot(1:height(T), T.phase5D2_Z, 'ko-', 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w');
ylabel('contextual Z');
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
xtickangle(25);
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = status_counts(T.outcome, statuses);
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function counts = status_counts(values, statuses)
values = string(values);
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(values == statuses(k));
end
end

function labels = short_labels(values)
labels = string(values);
labels = replace(labels, "phase5D2_", "5D2 ");
labels = replace(labels, "phase6_", "6 ");
labels = replace(labels, "phase7B_", "7B ");
labels = replace(labels, "phase8_", "8 ");
labels = replace(labels, "_", " ");
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
