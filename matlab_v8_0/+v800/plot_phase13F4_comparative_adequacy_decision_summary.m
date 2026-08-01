function h = plot_phase13F4_comparative_adequacy_decision_summary(cfg, ...
    variantSummary, upgradeDecision, parsimonyDecision, gates)
%PLOT_PHASE13F4_COMPARATIVE_ADEQUACY_DECISION_SUMMARY Plot 13F.4.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13F.4 comparative adequacy decision', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_median_delta(variantSummary);
title('held-out improvement vs F0');

nexttile;
plot_devices_improved(variantSummary, cfg);
title('selected-device improvement');

nexttile;
plot_crossing_recovery(variantSummary);
title('threshold-crossing recovery');

nexttile;
plot_parsimony_text(parsimonyDecision);
title('parsimony decision');

nexttile;
plot_upgrade_status(upgradeDecision);
title('upgrade support');

nexttile;
plot_gate_summary(gates);
title('Phase 13F.4 gates');

titleHandle = sgtitle('Phase 13F.4 read-only comparative adequacy decision');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13F4.figureBaseFile '.png']);
saveas(h, [cfg.phase13F4.figureBaseFile '.pdf']);
end

function plot_median_delta(T)
Tc = T(string(T.variant_id) ~= "F0", :);
bar(Tc.median_delta_vs_F0, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(Tc), 'XTickLabel', string(Tc.variant_id));
ylabel('median \DeltaS vs F0');
grid on;
end

function plot_devices_improved(T, cfg)
Tc = T(string(T.variant_id) ~= "F0", :);
bar(Tc.devices_improved_vs_F0, 'FaceColor', [0.25 0.55 0.85]);
yline(cfg.phase13F4.minimumSelectedDeviceImprovement, '--', ...
    'minimum selected-device target', 'Color', [0.45 0.45 0.45]);
set(gca, 'XTick', 1:height(Tc), 'XTickLabel', string(Tc.variant_id));
ylabel('devices improved');
ylim([0 max(6, cfg.phase13F4.minimumSelectedDeviceImprovement + 1)]);
grid on;
end

function plot_crossing_recovery(T)
Tc = T(string(T.variant_id) ~= "F0", :);
bar([Tc.crossing_recovery_gain_vs_F0 Tc.false_predicted_cross_count]);
set(gca, 'XTick', 1:height(Tc), 'XTickLabel', string(Tc.variant_id));
ylabel('count');
legend(["both-cross gain"; "false predicted cross"], ...
    'Location', 'best');
grid on;
end

function plot_parsimony_text(T)
axis off;
preferred = lookup(T, "preferred_revised_variant");
decision = lookup(T, "phase13F4_decision");
predictor = lookup(T, "shared_quantitative_RT_predictor");
interface = lookup(T, "interface_transfer_upgrade");
lines = [
    "Decision: " + decision
    "Preferred variant: " + preferred
    "Interface term: " + interface
    "Shared quantitative predictor: " + predictor
    "Phase 13D limitation preserved"
    ];
for k = 1:numel(lines)
    text(0.05, 0.90 - 0.14 * (k - 1), lines(k), ...
        'Units', 'normalized', 'Color', 'k', 'FontWeight', 'bold', ...
        'Interpreter', 'none');
end
end

function value = lookup(T, key)
idx = string(T.item) == string(key);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function plot_upgrade_status(T)
statuses = string(T.status);
supportScore = zeros(height(T), 1);
for k = 1:height(T)
    if statuses(k) == "supported_with_limited_transfer" || ...
            statuses(k) == "supported"
        supportScore(k) = 1;
    elseif statuses(k) == "improves_same_devices_as_baseline_shunt"
        supportScore(k) = 0.5;
    elseif statuses(k) == "false" || statuses(k) == "not_identifiable"
        supportScore(k) = 0;
    else
        supportScore(k) = 0.25;
    end
end
bar(supportScore, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.upgrade));
xtickangle(30);
ylabel('support score');
ylim([0 1.1]);
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
