function h = plot_phase15A_as006_field_data_lock_summary(cfg, ...
    rawSourceLock, axisMetadataLock, channelLock, sweepHistoryAudit, gates)
%PLOT_PHASE15A_AS006_FIELD_DATA_LOCK_SUMMARY Plot Phase 15A.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 15A AS006 field data lock', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_source(rawSourceLock);
title('raw field source');

nexttile;
plot_axis_counts(axisMetadataLock);
title('axis sizes');

nexttile;
plot_axis_ranges(axisMetadataLock);
title('axis spans');

nexttile;
plot_channels(channelLock);
title('R1/R2 channel lock');

nexttile;
plot_sweep_history(sweepHistoryAudit);
title('sweep metadata availability');

nexttile;
plot_gates(gates);
title('Phase 15A gates');

titleHandle = sgtitle( ...
    'Phase 15A AS006 dV/dI(I,B,T) raw observable lock');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase15A.figureBaseFile '.png']);
saveas(h, [cfg.phase15A.figureBaseFile '.pdf']);
end

function plot_source(T)
statuses = ["raw_file_exists"; "required_columns_present"; ...
    "legacy_loader_exists"];
values = [
    string(T.raw_file_exists(1)) == "true"
    string(T.required_columns_present(1)) == "true"
    string(T.legacy_loader_exists(1)) == "true"
    ];
bar(double(values), 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1.1]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(30);
ylabel('true = 1');
grid on;
text(1, 0.55, string(T.source_label(1)), 'HorizontalAlignment', 'center', ...
    'Interpreter', 'none', 'FontWeight', 'bold');
end

function plot_axis_counts(T)
labels = ["current"; "field"; "grid rows"];
values = [T.current_point_count(1); T.field_point_count(1); ...
    T.grid_point_count(1)];
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
ylabel('count');
grid on;
end

function plot_axis_ranges(T)
labels = ["I min"; "I max"; "B min"; "B max"];
values = [T.current_min_A(1); T.current_max_A(1); ...
    T.field_min_T(1); T.field_max_T(1)];
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('A or T');
yline(0, 'k-');
grid on;
end

function plot_channels(T)
labels = string(T.channel_role);
bar(T.finite_fraction, 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1.1]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
ylabel('finite fraction');
grid on;
for k = 1:height(T)
    text(k, T.finite_fraction(k), string(T.matrix_column(k)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none');
end
end

function plot_sweep_history(T)
items = ["current_axis"; "field_axis"; "up_down_current_branches"; ...
    "up_down_field_branches"; "sweep_rate_metadata"];
values = zeros(numel(items), 1);
for k = 1:numel(items)
    idx = string(T.item) == items(k);
    if any(idx)
        status = string(T.status(find(idx, 1, 'first')));
        values(k) = double(status == "locked" || ...
            status == "single_branch_inferred");
    end
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1.1]);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(30);
ylabel('available/inferred = 1');
grid on;
text(1, 0.18, 'up/down and rate metadata unavailable', ...
    'Color', [0.45 0 0], 'FontWeight', 'bold');
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
