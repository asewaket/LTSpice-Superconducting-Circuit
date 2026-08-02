function h = plot_phase14B5_raw_nonlinear_execution_summary(cfg, ...
    fullMapResiduals, channelPerformance, switchingCurrentLedger, ...
    currentSymmetry, thermalTriggerAssessment, gates)
%PLOT_PHASE14B5_RAW_NONLINEAR_EXECUTION_SUMMARY Plot Phase 14B.5.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.5 raw nonlinear execution', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_full_map_residuals(fullMapResiduals);
title('raw full-map residuals');

nexttile;
plot_channel_improvement(channelPerformance);
title('NI improvement vs N0');

nexttile;
plot_switching_errors(switchingCurrentLedger);
title('switching-current error');

nexttile;
plot_current_symmetry(currentSymmetry);
title('current symmetry');

nexttile;
plot_thermal_trigger(thermalTriggerAssessment);
title('Phase 14C trigger assessment');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.5 gates');

titleHandle = sgtitle( ...
    'Phase 14B.5 raw AS001/AS004 current-only nonlinear execution');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14B5.figureBaseFile '.png']);
saveas(h, [cfg.phase14B5.figureBaseFile '.pdf']);
end

function plot_full_map_residuals(T)
devices = unique(string(T.device), 'stable');
variants = unique(string(T.variant_id), 'stable');
channels = unique(string(T.channel_role), 'stable');
labels = strings(numel(devices) * numel(channels), 1);
M = NaN(numel(labels), numel(variants));
idx = 0;
for d = 1:numel(devices)
    for c = 1:numel(channels)
        idx = idx + 1;
        labels(idx) = devices(d) + " " + channels(c);
        for v = 1:numel(variants)
            mask = string(T.device) == devices(d) & ...
                string(T.channel_role) == channels(c) & ...
                string(T.variant_id) == variants(v);
            if any(mask)
                M(idx, v) = T.mean_squared_residual(find(mask, 1));
            end
        end
    end
end
bar(M);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('mean squared residual');
legend(variants, 'Location', 'best');
grid on;
end

function plot_channel_improvement(T)
labels = string(T.device) + " " + string(T.channel_role);
bar(-T.Delta_NI_minus_N0, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(30);
ylabel('N0 residual - NI residual');
grid on;
end

function plot_switching_errors(T)
T = T(string(T.variant_id) == "NI", :);
devices = unique(string(T.device), 'stable');
channels = unique(string(T.channel_role), 'stable');
labels = strings(numel(devices) * numel(channels), 1);
values = NaN(numel(labels), 1);
idx = 0;
for d = 1:numel(devices)
    for c = 1:numel(channels)
        idx = idx + 1;
        labels(idx) = devices(d) + " " + channels(c);
        mask = string(T.device) == devices(d) & ...
            string(T.channel_role) == channels(c);
        vals = [T.positive_switch_error_A(mask); ...
            T.negative_switch_error_A(mask)];
        values(idx) = mean(vals, 'omitnan');
    end
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('mean |Ic error| (A)');
grid on;
end

function plot_current_symmetry(T)
labels = string(T.device) + " " + string(T.variant_id) + " " + ...
    string(T.channel_role);
bar(T.mean_symmetry_error, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(35);
ylabel('mean symmetry error');
grid on;
end

function plot_thermal_trigger(T)
items = [
    "up_sweep_available"
    "down_sweep_available"
    "sweep_rate_available"
    "switching_and_retrapping_distinguishable"
    "phase14C_trigger"
    ];
values = zeros(numel(items), 1);
for k = 1:numel(items)
    idx = string(T.item) == items(k);
    if any(idx)
        values(k) = double(lower(string(T.value(find(idx, 1)))) == "true");
    end
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(30);
ylabel('true = 1');
ylim([0 1]);
reason = lookup_assessment(T, "phase14C_trigger_reason");
text(1, 0.82, "reason: " + reason, 'Color', [0.45 0 0], ...
    'FontWeight', 'bold', 'Interpreter', 'none');
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

function status = lookup_assessment(T, item)
idx = string(T.item) == string(item);
if any(idx)
    status = string(T.value(find(idx, 1, 'first')));
else
    status = "";
end
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
