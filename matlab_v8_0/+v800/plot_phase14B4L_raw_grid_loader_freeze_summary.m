function h = plot_phase14B4L_raw_grid_loader_freeze_summary(cfg, ...
    selected, axisValidation, matrixValidation, duplicateResolution, ...
    canonicalGrids, gates)
%PLOT_PHASE14B4L_RAW_GRID_LOADER_FREEZE_SUMMARY Plot 14B.4L.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.4L raw grid loader freeze', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_lock_status(canonicalGrids);
title('canonical grid lock');

nexttile;
plot_axis_sizes(axisValidation);
title('axis sizes');

nexttile;
plot_duplicate_resolution(duplicateResolution);
title('duplicate candidate resolution');

nexttile;
plot_zero_current(axisValidation);
title('current-axis span');

nexttile;
plot_matrix_validation(matrixValidation);
title('matrix completeness');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.4L gates');

titleHandle = sgtitle( ...
    'Phase 14B.4L raw AS001/AS004 grid parsing and loader freeze');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, char([cfg.phase14B4L.figureBaseFile '.png']));
saveas(h, char([cfg.phase14B4L.figureBaseFile '.pdf']));
end

function plot_lock_status(T)
locked = double(string(T.grid_lock_status) == "pass");
bar(locked, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylim([0 1]);
ylabel('locked = 1');
grid on;
for k = 1:height(T)
    if locked(k)
        label = "locked";
        color = [0.0 0.45 0.16];
    else
        label = "blocked";
        color = [0.55 0.08 0.08];
    end
    text(k, 0.55, label, 'HorizontalAlignment', 'center', ...
        'Color', color, 'FontWeight', 'bold');
end
end

function plot_axis_sizes(T)
bar([T.current_points T.temperature_points]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('axis points');
legend(["current", "temperature"], 'Location', 'best');
grid on;
end

function plot_duplicate_resolution(T)
labels = unique(string(T.resolution), 'stable');
counts = zeros(numel(labels), 1);
for k = 1:numel(labels)
    counts(k) = sum(string(T.resolution) == labels(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('candidate count');
grid on;
end

function plot_zero_current(T)
bar([T.current_min_A T.current_max_A]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('current (A)');
legend(["min", "max"], 'Location', 'best');
grid on;
end

function plot_matrix_validation(T)
bar([T.table_row_count T.expected_row_count]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('row count');
legend(["observed", "expected"], 'Location', 'best');
grid on;
yyaxis right;
plot(1:height(T), T.matrix_finite_fraction, 'ko-', ...
    'LineWidth', 1.2, 'MarkerFaceColor', 'w');
ylabel('finite fraction');
ylim([0 1.05]);
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
