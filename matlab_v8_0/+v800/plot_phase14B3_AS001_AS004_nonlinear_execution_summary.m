function h = plot_phase14B3_AS001_AS004_nonlinear_execution_summary(cfg, ...
    rawDataResolution, sliceMetrics, deviceMetrics, comparison, ...
    currentSymmetry, coverage, failedLog, gates)
%PLOT_PHASE14B3_AS001_AS004_NONLINEAR_EXECUTION_SUMMARY Plot 14B.3.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.3 AS001/AS004 nonlinear execution', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_device_residuals(deviceMetrics);
title('held-out residual by device');

nexttile;
plot_N0_NI_comparison(comparison);
title('NI improvement vs N0');

nexttile;
plot_slice_metrics(sliceMetrics);
title('temperature-slice residuals');

nexttile;
plot_symmetry_coverage(currentSymmetry, coverage);
title('symmetry and interval coverage');

nexttile;
plot_data_and_failures(rawDataResolution, failedLog);
title('data resolution and retained failures');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.3 gates');

titleHandle = sgtitle( ...
    'Phase 14B.3 AS001/AS004 held-out nonlinear execution');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14B3.figureBaseFile '.png']);
saveas(h, [cfg.phase14B3.figureBaseFile '.pdf']);
end

function plot_device_residuals(T)
devices = unique(string(T.device), 'stable');
variants = unique(string(T.variant_id), 'stable');
M = NaN(numel(devices), numel(variants));
for d = 1:numel(devices)
    for v = 1:numel(variants)
        idx = string(T.device) == devices(d) & ...
            string(T.variant_id) == variants(v);
        if any(idx)
            M(d, v) = T.heldout_full_dVdI_residual(find(idx, 1));
        end
    end
end
bar(M);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
ylabel('held-out residual');
legend(variants, 'Location', 'best');
grid on;
end

function plot_N0_NI_comparison(T)
bar(T.Delta_NI_minus_N0, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('\Delta residual, NI - N0');
grid on;
end

function plot_slice_metrics(T)
heldout = string(T.slice_role) == "heldout";
Th = T(heldout, :);
labels = string(Th.device) + " " + string(Th.variant_id) + ...
    " T=" + string(Th.temperature);
bar(Th.full_dVdI_residual, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(Th), 'XTickLabel', labels);
xtickangle(35);
ylabel('residual');
grid on;
end

function plot_symmetry_coverage(S, C)
labels = string(S.device) + " " + string(S.variant_id);
yyaxis left;
bar(S.mean_current_symmetry_error, 'FaceColor', [0.25 0.55 0.85]);
ylabel('mean symmetry error');
yyaxis right;
plot(1:height(C), C.coverage_fraction, 'ko-', 'LineWidth', 1.2);
ylabel('coverage fraction');
set(gca, 'XTick', 1:height(S), 'XTickLabel', labels);
xtickangle(30);
grid on;
end

function plot_data_and_failures(R, F)
statuses = ["raw_grid_loader_ready"; ...
    "declared_available_loader_path_unresolved"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(R.raw_data_status) == statuses(k));
end
yyaxis left;
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
ylabel('device count');
yyaxis right;
failureCount = max(0, height(F) - double(height(F) == 1 && ...
    string(F.failure_type(1)) == "none"));
plot(1:numel(statuses), [failureCount; failureCount], 'ko-', ...
    'LineWidth', 1.2);
ylabel('retained failure count');
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(30);
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
