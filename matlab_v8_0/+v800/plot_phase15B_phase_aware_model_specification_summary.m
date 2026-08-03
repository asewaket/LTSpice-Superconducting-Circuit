function h = plot_phase15B_phase_aware_model_specification_summary(cfg, ...
    modelVariantLedger, parameterRoleLedger, prohibitedFlexibilityLedger, ...
    validationHoldoutPlan, syntheticTestPlan, gates)
%PLOT_PHASE15B_PHASE_AWARE_MODEL_SPECIFICATION_SUMMARY Plot Phase 15B.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 15B phase-aware model specification', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_variants(modelVariantLedger);
title('field-response variants');

nexttile;
plot_parameter_roles(parameterRoleLedger);
title('allowed parameter roles');

nexttile;
plot_prohibited(prohibitedFlexibilityLedger);
title('blocked flexibility');

nexttile;
plot_validation(validationHoldoutPlan);
title('predeclared validation windows');

nexttile;
plot_synthetic_tests(syntheticTestPlan);
title('Phase 15C synthetic requirements');

nexttile;
plot_gates(gates);
title('Phase 15B gates');

titleHandle = sgtitle( ...
    'Phase 15B minimal phase-aware field-response specification freeze');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase15B.figureBaseFile '.png']);
saveas(h, [cfg.phase15B.figureBaseFile '.pdf']);
end

function plot_variants(T)
labels = string(T.variant);
values = [double(T.field_suppression_included), ...
    double(T.oscillatory_response_allowed), ...
    double(T.phase_solver_required)];
bar(values);
ylim([0 1.2]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
ylabel('included = 1');
legend({'field suppression', 'oscillation', 'phase solver'}, ...
    'Location', 'northwest');
grid on;
end

function plot_parameter_roles(T)
labels = string(T.scope);
[groups, names] = findgroups(labels);
counts = splitapply(@numel, labels, groups);
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(names), 'XTickLabel', names);
xtickangle(30);
ylabel('parameter count');
grid on;
end

function plot_prohibited(T)
bar(height(T), 'FaceColor', [0.65 0.20 0.20]);
set(gca, 'XTick', 1, 'XTickLabel', {'prohibited'});
ylabel('blocked item count');
grid on;
text(1, height(T) * 0.5, 'no manual period / topology / hysteresis fit', ...
    'HorizontalAlignment', 'center', 'Color', [0.45 0 0], ...
    'FontWeight', 'bold');
end

function plot_validation(T)
bar(ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1.2]);
labels = string(T.holdout_id);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(35);
ylabel('declared = 1');
grid on;
end

function plot_synthetic_tests(T)
bar(height(T), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1, 'XTickLabel', {'required'});
ylabel('test count');
grid on;
text(1, height(T) * 0.5, 'before Phase 15D residual fitting', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

function plot_gates(T)
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
