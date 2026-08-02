function h = plot_phase14D_current_only_adequacy_decision_summary(cfg, ...
    relativeImprovement, absoluteResidual, predictionBounds, ...
    sharedLawTransfer, thermalIdentifiability, gates)
%PLOT_PHASE14D_CURRENT_ONLY_ADEQUACY_DECISION_SUMMARY Plot Phase 14D.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14D current-only adequacy decision', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_residuals(absoluteResidual);
title('NI absolute residual by channel');

nexttile;
plot_improvement(relativeImprovement);
title('relative NI improvement');

nexttile;
plot_bounds(predictionBounds);
title('prediction-bound violations');

nexttile;
plot_claim(sharedLawTransfer);
title('shared-law claim limits');

nexttile;
plot_thermal(thermalIdentifiability);
title('Phase 14C identifiability');

nexttile;
plot_gates(gates);
title('Phase 14D gates');

titleHandle = sgtitle( ...
    'Phase 14D read-only AS001/AS004 current-only nonlinear adequacy decision');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase14D.figureBaseFile '.png']);
saveas(h, [cfg.phase14D.figureBaseFile '.pdf']);
end

function plot_residuals(T)
labels = string(T.device) + " " + string(T.channel_role);
bar(T.NI_MSE, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(30);
ylabel('NI mean squared residual');
grid on;
for k = 1:height(T)
    txt = string(T.adequacy_class(k));
    text(k, T.NI_MSE(k), txt, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'Interpreter', 'none', ...
        'FontSize', 8);
end
end

function plot_improvement(T)
labels = string(T.device) + " " + string(T.channel_role);
bar(T.improvement_fraction, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(30);
ylabel('fractional MSE improvement');
ylim([0 max([0.8; T.improvement_fraction(:) + 0.08])]);
grid on;
end

function plot_bounds(T)
labels = string(T.device) + " " + string(T.channel_role);
bar(T.fraction_out_of_bounds, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(30);
ylabel('fraction out of bounds');
grid on;
for k = 1:height(T)
    text(k, T.fraction_out_of_bounds(k), string(T.bounds_status(k)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none', 'FontSize', 8);
end
end

function plot_claim(T)
items = [
    "current_switching_directionally_supported"
    "shared_raw_nonlinear_predictor"
    "AS004_primary_quantitative_adequacy"
    "prediction_bounds_limitation"
    ];
values = NaN(numel(items), 1);
for k = 1:numel(items)
    value = lookup_value(T, items(k));
    if value == "true" || value == "retained"
        values(k) = 1;
    elseif value == "false" || value == "fail"
        values(k) = 0;
    end
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1.1]);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(30);
ylabel('true/retained = 1');
grid on;
end

function plot_thermal(T)
items = [
    "up_sweep_available"
    "down_sweep_available"
    "sweep_rate_available"
    "switching_and_retrapping_distinguishable"
    "phase14C_trigger"
    ];
values = zeros(numel(items), 1);
for k = 1:numel(items)
    values(k) = double(lookup_value(T, items(k)) == "true");
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1]);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(30);
ylabel('true = 1');
reason = lookup_value(T, "phase14C_trigger_reason");
text(1, 0.82, "reason: " + reason, 'Color', [0.45 0 0], ...
    'FontWeight', 'bold', 'Interpreter', 'none');
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

function value = lookup_value(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
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
