function h = plot_phase14B4_raw_nonlinear_data_resolution_summary(cfg, ...
    rawLedger, axisIntegrity, resolutionDecision, gates)
%PLOT_PHASE14B4_RAW_NONLINEAR_DATA_RESOLUTION_SUMMARY Plot 14B.4.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.4 raw nonlinear data resolution', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_raw_status(rawLedger);
title('raw source status');

nexttile;
plot_integrity_counts(axisIntegrity);
title('integrity checks');

nexttile;
plot_device_decision(resolutionDecision);
title('Phase 14B.5 release decision');

nexttile;
plot_required_metadata(rawLedger);
title('resolved metadata fields');

nexttile;
plot_policy_note();
title('Phase 14B.4 policy');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.4 gates');

titleHandle = sgtitle( ...
    'Phase 14B.4 raw AS001/AS004 nonlinear data-resolution lock');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14B4.figureBaseFile '.png']);
saveas(h, [cfg.phase14B4.figureBaseFile '.pdf']);
end

function plot_raw_status(T)
statuses = ["raw_data_resolved"; "raw_data_partially_resolved"; ...
    "raw_data_ambiguous"; "raw_data_unavailable"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.raw_data_status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(30);
ylabel('device count');
grid on;
end

function plot_integrity_counts(T)
checks = unique(string(T.check_name), 'stable');
passCounts = zeros(numel(checks), 1);
failCounts = zeros(numel(checks), 1);
for k = 1:numel(checks)
    mask = string(T.check_name) == checks(k);
    passCounts(k) = sum(string(T.status(mask)) == "pass");
    failCounts(k) = sum(string(T.status(mask)) == "fail");
end
bar([passCounts failCounts]);
set(gca, 'XTick', 1:numel(checks), 'XTickLabel', checks);
xtickangle(35);
ylabel('device count');
legend(["pass", "fail"], 'Location', 'best');
grid on;
end

function plot_device_decision(T)
allowed = double(T.allowed_for_phase14B5);
bar(allowed, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylim([0 1]);
ylabel('released to 14B.5 = 1');
grid on;
for k = 1:height(T)
    label = "blocked";
    if T.allowed_for_phase14B5(k)
        label = "released";
    end
    text(k, 0.55, label, 'HorizontalAlignment', 'center', ...
        'Color', [0.55 0.08 0.08], 'FontWeight', 'bold');
end
end

function plot_required_metadata(T)
fields = [
    "raw_file"
    "raw_variable"
    "current_axis"
    "temperature_axis"
    "dVdI_matrix"
    "matrix_dimensions"
    "units"
    "field_condition"
    "sweep_direction"
    "probe_mapping"
    ];
resolved = zeros(numel(fields), 1);
resolved(1) = sum(string(T.raw_file) ~= "unresolved");
resolved(2) = sum(strlength(string(T.raw_variable)) > 0);
resolved(3) = sum(T.current_axis_resolved);
resolved(4) = sum(T.temperature_axis_resolved);
resolved(5) = sum(T.dVdI_matrix_resolved);
resolved(6) = sum(T.matrix_dimensions_match);
resolved(7) = sum(string(T.current_units) ~= "unresolved" & ...
    string(T.temperature_units) ~= "unresolved" & ...
    string(T.dVdI_units) ~= "unresolved");
resolved(8) = sum(strlength(string(T.field_condition)) > 0);
resolved(9) = sum(strlength(string(T.sweep_direction)) > 0);
resolved(10) = sum(strlength(string(T.probe_mapping)) > 0);
bar(resolved, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(fields), 'XTickLabel', fields);
xtickangle(35);
ylabel('resolved device count');
grid on;
end

function plot_policy_note()
axis off;
text(0.08, 0.78, 'No fitting performed', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
text(0.08, 0.58, 'No synthetic or proxy substitution', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.55 0.08 0.08]);
text(0.08, 0.38, 'Raw adequacy remains deferred', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
text(0.08, 0.18, '14B.5 requires locked raw grids', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
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
