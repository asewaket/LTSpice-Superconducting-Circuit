function h = plot_phase15C_synthetic_flux_interference_summary(cfg, ...
    zeroFieldInheritance, twoPathInterference, fluxPeriodicity, ...
    effectiveAreaScaling, fieldSuppressionResults, phaseAblationResults, ...
    fieldSymmetry, phaseSolverDiagnostics, gates)
%PLOT_PHASE15C_SYNTHETIC_FLUX_INTERFERENCE_SUMMARY Plot Phase 15C.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 15C synthetic flux verification', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_zero_field(zeroFieldInheritance);
title('zero-field NI inheritance');

nexttile;
plot_two_path(twoPathInterference);
title('two-path interference');

nexttile;
plot_periodicity(fluxPeriodicity);
title('\Phi_0 periodicity');

nexttile;
plot_suppression_and_symmetry(fieldSuppressionResults, fieldSymmetry);
title('PB suppression and field symmetry');

nexttile;
plot_phase_ablation_and_solver(phaseAblationResults, ...
    phaseSolverDiagnostics);
title('phase-loop requirement and solver residuals');

nexttile;
plot_gates(gates);
title('Phase 15C gates');

titleHandle = sgtitle( ...
    'Phase 15C synthetic flux/interference verification');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase15C.figureBaseFile '.png']);
saveas(h, [cfg.phase15C.figureBaseFile '.pdf']);
end

function plot_zero_field(T)
bar(T.absolute_error, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.variant));
ylabel('|model - NI|');
grid on;
end

function plot_two_path(T)
plot(T.flux_quanta, T.normalized_Ic, '-o', ...
    'Color', [0.25 0.55 0.85], 'LineWidth', 1.5, ...
    'MarkerSize', 4);
xlabel('\Phi / \Phi_0');
ylabel('normalized I_c');
grid on;
end

function plot_periodicity(T)
bar(T.periodicity_error, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), ...
    'XTickLabel', string(T.flux_quanta));
xtickangle(35);
ylabel('|S(\Phi) - S(\Phi+\Phi_0)|');
grid on;
end

function plot_suppression_and_symmetry(suppression, symmetry)
yyaxis left;
plot(suppression.B_T, suppression.PB_envelope, '-o', ...
    'LineWidth', 1.4);
ylabel('PB envelope');
yyaxis right;
plot(symmetry.B_T, symmetry.symmetry_error, '-s', ...
    'LineWidth', 1.4);
ylabel('symmetry error');
xlabel('|B| (T)');
grid on;
legend({'PB envelope', 'P_\phi symmetry error'}, ...
    'Location', 'northeast');
end

function plot_phase_ablation_and_solver(ablation, diagnostics)
yyaxis left;
bar(double(ablation.oscillation_detected), ...
    'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(ablation), ...
    'XTickLabel', string(ablation.case_id));
xtickangle(30);
ylabel('oscillation detected');
yyaxis right;
plot(diagnostics.flux_quanta, diagnostics.phase_residual, '-o', ...
    'LineWidth', 1.4);
ylabel('phase residual');
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
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
end
