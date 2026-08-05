function h = plot_phase15D_raw_AS006_field_execution_summary(cfg, ...
    variantResiduals, heldoutFieldWindow, currentRangeTransfer, ...
    fieldSymmetry, criticalCurrentEnvelope, oscillatoryStructure, ...
    predictionBoundsAudit, gates)
%PLOT_PHASE15D_RAW_AS006_FIELD_EXECUTION_SUMMARY Plot Phase 15D diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 15D raw AS006 field execution', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_full_map_residuals(variantResiduals);
title('full-map residuals');

nexttile;
plot_heldout_field(heldoutFieldWindow);
title('held-out field windows');

nexttile;
plot_current_transfer(currentRangeTransfer);
title('current-range transfer');

nexttile;
plot_symmetry_and_ic(fieldSymmetry, criticalCurrentEnvelope);
title('field symmetry and I_c envelope');

nexttile;
plot_oscillation_and_bounds(oscillatoryStructure, predictionBoundsAudit);
title('oscillation and bounds diagnostics');

nexttile;
plot_gates(gates);
title('Phase 15D gates');

titleHandle = sgtitle( ...
    'Phase 15D raw AS006 field-dependent execution');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase15D.figureBaseFile '.png']);
saveas(h, [cfg.phase15D.figureBaseFile '.pdf']);
end

function plot_full_map_residuals(T)
labels = string(T.variant) + " " + string(T.channel);
bar(T.mean_squared_residual, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(35);
ylabel('normalized MSE');
grid on;
end

function plot_heldout_field(T)
isOuter = string(T.holdout_id) == "central_field_train_outer_field_holdout";
S = T(isOuter, :);
labels = string(S.variant) + " " + string(S.channel);
bar([S.calibration_window_mse, S.heldout_window_mse]);
set(gca, 'XTick', 1:height(S), 'XTickLabel', labels);
xtickangle(35);
ylabel('normalized MSE');
legend({'central', 'outer'}, 'Location', 'best');
grid on;
end

function plot_current_transfer(T)
labels = string(T.variant) + " " + string(T.channel);
bar([T.low_current_mse, T.high_current_mse]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(35);
ylabel('normalized MSE');
legend({'low |I|', 'high |I|'}, 'Location', 'best');
grid on;
end

function plot_symmetry_and_ic(symmetry, IcEnv)
yyaxis left;
bar(symmetry.mean_even_field_symmetry_error, ...
    'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(symmetry), ...
    'XTickLabel', string(symmetry.source) + " " + string(symmetry.channel));
xtickangle(35);
ylabel('field symmetry error');
yyaxis right;
plot(IcEnv.mean_abs_Ic_error_A, '-o', 'LineWidth', 1.4);
ylabel('mean |I_c error| (A)');
grid on;
end

function plot_oscillation_and_bounds(osc, bounds)
modelRows = string(osc.source) ~= "observed";
S = osc(modelRows, :);
yyaxis left;
bar(S.peak_count + S.trough_count, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(S), ...
    'XTickLabel', string(S.source) + " " + string(S.channel));
xtickangle(35);
ylabel('turning-point count');
yyaxis right;
plot(bounds.fraction_outside_bounds, '-o', 'LineWidth', 1.4);
ylabel('fraction outside bounds');
grid on;
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
        'GridColor', [0.82 0.82 0.82], 'MinorGridColor', [0.9 0.9 0.9], ...
        'Box', 'on', 'FontWeight', 'bold');
end
legendList = findall(h, 'Type', 'Legend');
for k = 1:numel(legendList)
    set(legendList(k), 'TextColor', 'k', 'Color', 'w', ...
        'EdgeColor', [0.4 0.4 0.4]);
end
end
