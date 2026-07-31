function h = plot_phase13D_predictive_adequacy_summary(cfg, ...
    fullCurveAdequacy, crossingConfusion, pairedProbeAdequacy, ...
    geometryFamilyAdequacy, uncertaintyCoverage, gateSummary)
%PLOT_PHASE13D_PREDICTIVE_ADEQUACY_SUMMARY Plot Phase 13D diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13D predictive adequacy', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_full_curve_residuals(cfg, fullCurveAdequacy);
title('held-out full-curve adequacy');

nexttile;
plot_crossing_confusion(crossingConfusion);
title('transition crossing outcomes');

nexttile;
plot_paired_probe(pairedProbeAdequacy);
title('paired-probe transfer');

nexttile;
plot_geometry_family(cfg, geometryFamilyAdequacy);
title('geometry-family holdouts');

nexttile;
plot_uncertainty_coverage(cfg, uncertaintyCoverage);
title('prediction interval coverage');

nexttile;
plot_gate_summary(gateSummary);
title('Phase 13D gates');

titleHandle = sgtitle('Phase 13D predictive adequacy decision');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13D.figureBaseFile '.png']);
saveas(h, [cfg.phase13D.figureBaseFile '.pdf']);
end

function plot_full_curve_residuals(cfg, T)
if isempty(T)
    empty_panel('missing full-curve adequacy');
    return;
end
bar(T.residual_value, 'FaceColor', [0.25 0.55 0.85]);
hold on;
yline(cfg.phase13D.fullCurveStrongResidualThreshold, '--', ...
    'partial threshold');
yline(cfg.phase13D.fullCurvePartialResidualThreshold, '--', ...
    'weak-transfer boundary');
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('mean squared residual');
grid on;
end

function plot_crossing_confusion(T)
if isempty(T)
    empty_panel('missing crossing confusion');
    return;
end
statuses = [
    "both_cross"
    "observed_cross_predicted_no_cross"
    "observed_no_cross_predicted_cross"
    "neither_crosses"
    "crossing_ambiguous"
    ];
metrics = unique(string(T.metric), 'stable');
M = zeros(numel(statuses), numel(metrics));
for m = 1:numel(metrics)
    for s = 1:numel(statuses)
        mask = string(T.metric) == metrics(m) & ...
            string(T.T_comparison_status) == statuses(s);
        if any(mask)
            M(s, m) = T.count(find(mask, 1));
        end
    end
end
bar(M', 'stacked');
set(gca, 'XTick', 1:numel(metrics), 'XTickLabel', metrics);
xtickangle(20);
ylabel('curve count');
legend(statuses, 'Location', 'eastoutside', 'Interpreter', 'none');
grid on;
end

function plot_paired_probe(T)
if isempty(T)
    empty_panel('missing paired-probe table');
    return;
end
bar(T.asymmetry_score, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('A_{probe}(T) score');
grid on;
end

function plot_geometry_family(cfg, T)
if isempty(T)
    empty_panel('missing family holdouts');
    return;
end
bar(T.mean_full_curve_residual, 'FaceColor', [0.25 0.55 0.85]);
hold on;
yline(cfg.phase13D.familyAdequacyResidualThreshold, '--', ...
    'partial family threshold');
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.family_holdout));
xtickangle(25);
ylabel('mean residual');
grid on;
end

function plot_uncertainty_coverage(cfg, T)
if isempty(T)
    empty_panel('missing uncertainty coverage');
    return;
end
mask = string(T.probe_role) == "primary";
Tp = T(mask, :);
bar(Tp.coverage_fraction, 'FaceColor', [0.25 0.55 0.85]);
hold on;
yline(cfg.phase13D.minimumCoverageTarget, '--', 'target');
set(gca, 'XTick', 1:height(Tp), 'XTickLabel', string(Tp.device));
xtickangle(25);
ylabel('coverage fraction');
ylim([0 1]);
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
