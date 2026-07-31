function h = plot_phase13F_upgrade_specification_summary(cfg, ...
    variantManifest, comparisonThresholds, parameterRoles, gates)
%PLOT_PHASE13F_UPGRADE_SPECIFICATION_SUMMARY Plot Phase 13F.1 summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13F.1 upgrade specification', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_variants(variantManifest);
title('required ablation variants');

nexttile;
plot_thresholds(comparisonThresholds);
title('comparison criteria count');

nexttile;
plot_parameter_roles(parameterRoles);
title('parameter role ledger');

nexttile;
plot_gate_summary(gates);
title('Phase 13F.1 gates');

titleHandle = sgtitle('Phase 13F.1 constrained R(T) upgrade specification');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13F.figureBaseFile '.png']);
saveas(h, [cfg.phase13F.figureBaseFile '.pdf']);
end

function plot_variants(T)
x = 1:height(T);
bar(x, double([T.baseline_shunt_upgrade, T.interface_transfer_upgrade]), ...
    'stacked');
set(gca, 'XTick', x, 'XTickLabel', string(T.variant_id));
ylabel('upgrade enabled');
legend(["baseline/shunt"; "interface"], 'Location', 'northwest');
grid on;
end

function plot_thresholds(T)
bar(height(T), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1, 'XTickLabel', "frozen criteria");
ylabel('criterion count');
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
