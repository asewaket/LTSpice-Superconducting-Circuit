function h = plot_phase13F3_full_variant_LODO_execution_summary(cfg, ...
    foldTraining, residuals, comparison, crossings, coverage, ...
    boundDiagnostics, gates)
%PLOT_PHASE13F3_FULL_VARIANT_LODO_EXECUTION_SUMMARY Plot 13F.3 diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13F.3 full variant LODO execution', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_training_objective(foldTraining);
title('LODO objective by variant');

nexttile;
plot_primary_residuals(residuals);
title('held-out primary residual');

nexttile;
plot_delta_vs_f0(comparison);
title('\DeltaS vs F0 (negative improves)');

nexttile;
plot_crossing_status(crossings);
title('threshold crossing outcomes');

nexttile;
plot_coverage_and_bounds(coverage, boundDiagnostics);
title('coverage and bound diagnostics');

nexttile;
plot_gate_summary(gates);
title('Phase 13F.3 gates');

titleHandle = sgtitle( ...
    'Phase 13F.3 full four-variant LODO execution');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13F3.figureBaseFile '.png']);
saveas(h, [cfg.phase13F3.figureBaseFile '.pdf']);
end

function plot_training_objective(T)
if isempty(T)
    empty_panel('missing fold training manifest');
    return;
end
variants = unique(string(T.variant_id), 'stable');
vals = NaN(numel(variants), 1);
for k = 1:numel(variants)
    vals(k) = median(T.training_objective( ...
        string(T.variant_id) == variants(k)), 'omitnan');
end
bar(vals, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants);
ylabel('median training objective');
grid on;
end

function plot_primary_residuals(T)
if isempty(T)
    empty_panel('missing residual table');
    return;
end
Tp = T(string(T.probe_role) == "primary", :);
variants = unique(string(Tp.variant_id), 'stable');
devices = unique(string(Tp.device), 'stable');
M = NaN(numel(devices), numel(variants));
for d = 1:numel(devices)
    for v = 1:numel(variants)
        idx = string(Tp.device) == devices(d) & ...
            string(Tp.variant_id) == variants(v);
        if any(idx)
            M(d, v) = Tp.residual_value(find(idx, 1, 'first'));
        end
    end
end
bar(M);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('mean squared residual');
legend(variants, 'Location', 'best', 'Interpreter', 'none');
grid on;
end

function plot_delta_vs_f0(T)
if isempty(T)
    empty_panel('missing comparison table');
    return;
end
Tc = T(string(T.variant_id) ~= "F0", :);
variants = unique(string(Tc.variant_id), 'stable');
vals = NaN(numel(variants), 1);
improved = NaN(numel(variants), 1);
for k = 1:numel(variants)
    mask = string(Tc.variant_id) == variants(k);
    vals(k) = median(Tc.DeltaS_vs_F0(mask), 'omitnan');
    improved(k) = sum(Tc.improved_vs_F0(mask));
end
yyaxis left;
bar(vals, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
ylabel('median \DeltaS');
yyaxis right;
plot(1:numel(variants), improved, 'ko-', 'LineWidth', 1.2);
ylabel('devices improved');
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants);
grid on;
end

function plot_crossing_status(T)
if isempty(T)
    empty_panel('missing crossing-status table');
    return;
end
statuses = [
    "both_cross"
    "observed_cross_predicted_no_cross"
    "observed_no_cross_predicted_cross"
    "neither_crosses"
    "crossing_ambiguous"
    ];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.crossing_status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(35);
ylabel('count');
grid on;
end

function plot_coverage_and_bounds(coverage, bounds)
if isempty(coverage)
    empty_panel('missing coverage table');
    return;
end
variants = unique(string(coverage.variant_id), 'stable');
cov = NaN(numel(variants), 1);
pinned = NaN(numel(variants), 1);
for k = 1:numel(variants)
    cov(k) = median(coverage.coverage_fraction( ...
        string(coverage.variant_id) == variants(k)), 'omitnan');
    if ~isempty(bounds)
        vals = bounds.pinned_fold_fraction( ...
            string(bounds.variant_id) == variants(k));
        vals = vals(isfinite(vals));
        if ~isempty(vals)
            pinned(k) = max(vals);
        end
    end
end
bar([cov pinned]);
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants);
ylabel('fraction');
legend(["interval coverage"; "max pinned-fold fraction"], ...
    'Location', 'best');
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
