function h = plot_phase5D2_result_freeze_summary(cfg, inputs, ...
    realDeviceContext, finalGates)
%PLOT_PHASE5D2_RESULT_FREEZE_SUMMARY Plot 5D.2 evidence-policy freeze.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5D.2 result freeze summary', ...
    'Color', 'w', 'Position', [120 120 1550 900]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_deltaS_distributions(inputs.sigmaAudit);
title('score separation by true group');

nexttile;
plot_roc(inputs.roc);
title('operating-point tradeoff');

nexttile;
plot_feasibility(inputs.feasibility);
title('feasible operating point');

nexttile;
plot_device_context(realDeviceContext);
title('real-device \DeltaS context');

nexttile;
plot_penalty_sensitivity(inputs.penaltySensitivity);
title('penalty sensitivity');

nexttile;
plot_gate_summary(finalGates);
title('Phase 5D.2 gates');

sgtitle('v8.0 Phase 5D.2 limitation and evidence-policy freeze');
apply_light_style(h);

saveas(h, [cfg.phase5D2.figureBaseFile '.png']);
saveas(h, [cfg.phase5D2.figureBaseFile '.pdf']);
end

function plot_deltaS_distributions(T)
if isempty(T)
    empty_panel('missing sigma audit');
    return;
end
groups = unique(T.true_group, 'stable');
tiers = unique(T.evidence_tier, 'stable');
Z = NaN(numel(groups), numel(tiers));
for i = 1:numel(groups)
    for j = 1:numel(tiers)
        idx = T.true_group == groups(i) & T.evidence_tier == tiers(j);
        if any(idx)
            Z(i, j) = T.median_abs_deltaS_over_sigma(find(idx, 1));
        end
    end
end
bar(Z);
set(gca, 'XTick', 1:numel(groups), 'XTickLabel', groups);
xtickangle(30);
ylabel('median |Z|');
legend(tiers, 'Location', 'best');
grid on;
end

function plot_roc(T)
if isempty(T)
    empty_panel('missing threshold ROC');
    return;
end
tiers = unique(T.evidence_tier, 'stable');
colors = lines(numel(tiers));
hold on;
for k = 1:numel(tiers)
    idx = T.evidence_tier == tiers(k);
    plot(T.FPR_structured_given_M0star(idx), ...
        T.TPR_structured_given_strong(idx), '-o', ...
        'Color', colors(k, :), 'DisplayName', tiers(k));
end
plot([0 0.15], [0.80 0.80], 'k--', 'DisplayName', 'target region');
plot([0.15 0.15], [0.80 1], 'k--', 'HandleVisibility', 'off');
hold off;
xlabel('FPR structured | M0*');
ylabel('TPR structured | strong');
xlim([0 0.5]);
ylim([0 1]);
legend('Location', 'best');
grid on;
end

function plot_feasibility(T)
if isempty(T)
    empty_panel('missing feasibility table');
    return;
end
labels = T.evidence_tier;
values = double(T.feasible_operating_point_exists);
bar(values, 'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0.35 0.35 0.35]);
hold on;
for k = 1:numel(values)
    if values(k) == 0
        plot(k, 0.5, 'x', 'Color', [0.80 0.10 0.10], ...
            'MarkerSize', 12, 'LineWidth', 2.0);
        text(k, 0.62, 'none', 'HorizontalAlignment', 'center', ...
            'Color', [0.55 0.05 0.05], 'FontWeight', 'bold');
    else
        plot(k, 0.5, 'o', 'Color', [0.00 0.45 0.20], ...
            'MarkerSize', 8, 'LineWidth', 2.0);
        text(k, 0.62, 'found', 'HorizontalAlignment', 'center', ...
            'Color', [0.00 0.35 0.15], 'FontWeight', 'bold');
    end
end
hold off;
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylim([0 1]);
ylabel('feasible operating point');
grid on;
end

function plot_device_context(T)
if isempty(T)
    empty_panel('missing device context');
    return;
end
devices = T.device;
values = T.DeltaS;
bar(values, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('\DeltaS = S_{structured} - S_{M0*}');
grid on;
end

function plot_penalty_sensitivity(T)
if isempty(T)
    empty_panel('missing penalty sensitivity');
    return;
end
labels = T.setting_id;
Y = [T.false_structured_rate, T.strong_structured_detection_rate];
bar(Y);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('rate');
legend(["false structured", "strong detection"], 'Location', 'best');
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing final gates');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.outcome == statuses(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('component count');
grid on;
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
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on');
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
