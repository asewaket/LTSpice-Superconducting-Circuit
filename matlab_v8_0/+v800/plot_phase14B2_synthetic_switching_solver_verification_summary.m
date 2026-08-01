function h = plot_phase14B2_synthetic_switching_solver_verification_summary(cfg, ...
    singleLink, parallelPath, boundaryBottleneck, symmetryChecks, ...
    icMonotonicity, highCurrentLimit, zeroCurrentRecovery, ...
    solverConvergence, limitingCaseSummary, gates)
%PLOT_PHASE14B2_SYNTHETIC_SWITCHING_SOLVER_VERIFICATION_SUMMARY Plot 14B.2.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.2 synthetic switching verification', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_single_link(singleLink);
title('single-link threshold');

nexttile;
plot_parallel_boundary(parallelPath, boundaryBottleneck);
title('redistribution and bottleneck stages');

nexttile;
plot_Ic_temperature(icMonotonicity);
title('Ic(T) monotonicity');

nexttile;
plot_symmetry_and_limits(symmetryChecks, highCurrentLimit, ...
    zeroCurrentRecovery);
title('symmetry, high-current, zero-current checks');

nexttile;
plot_solver_summary(solverConvergence, limitingCaseSummary);
title('solver and limiting cases');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.2 gates');

titleHandle = sgtitle('Phase 14B.2 synthetic current-switching solver verification');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14B2.figureBaseFile '.png']);
saveas(h, [cfg.phase14B2.figureBaseFile '.pdf']);
end

function plot_single_link(T)
rowIndex = (1:height(T)).';
caseLabel = "I=" + string(T.applied_current) + ", T=" + string(T.temperature);
yyaxis left;
plot(rowIndex, T.ic, 'o-', 'LineWidth', 1.4);
ylabel('Ic');
yyaxis right;
bar(rowIndex, double(T.switched), 0.45);
ylabel('switched');
xlabel('synthetic case');
set(gca, 'XTick', rowIndex, 'XTickLabel', caseLabel);
xtickangle(30);
grid on;
end

function plot_parallel_boundary(P, B)
plot(P.applied_current, P.stage_count, 'o-', 'LineWidth', 1.4);
hold on;
plot(B.applied_current, B.switched_link_count, 's-', 'LineWidth', 1.4);
legend(["parallel path"; "boundary bottleneck"], 'Location', 'best');
xlabel('applied current');
ylabel('switched/stage count');
grid on;
end

function plot_Ic_temperature(T)
plot(T.temperature, T.ic, 'o-', 'LineWidth', 1.5);
xlabel('T / Tc');
ylabel('Ic');
ylim([0 1.05]);
grid on;
end

function plot_symmetry_and_limits(S, H, Z)
values = [
    max(S.voltage_odd_error)
    max(S.differential_resistance_even_error)
    min(H.relative_error)
    max(Z.absolute_error)
    ];
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(values), 'XTickLabel', ...
    ["V odd error"; "dVdI even error"; "high-I min rel err"; ...
    "zero-I max err"]);
xtickangle(25);
ylabel('diagnostic magnitude');
grid on;
end

function plot_solver_summary(S, L)
yyaxis left;
bar(S.max_iterations_observed, 'FaceColor', [0.25 0.55 0.85]);
ylabel('max iterations');
yyaxis right;
plot(double(string(L.status) == "pass"), 'o-', 'LineWidth', 1.4);
ylabel('case pass flag');
set(gca, 'XTick', 1:height(L), 'XTickLabel', string(L.case_id));
xtickangle(35);
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
