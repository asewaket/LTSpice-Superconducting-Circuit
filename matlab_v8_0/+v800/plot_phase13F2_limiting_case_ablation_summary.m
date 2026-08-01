function h = plot_phase13F2_limiting_case_ablation_summary(cfg, response, ...
    ablations, identifiability, sanity, firewall, gates)
%PLOT_PHASE13F2_LIMITING_CASE_ABLATION_SUMMARY Plot Phase 13F.2 checks.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13F.2 limiting-case ablations', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_variant_channels(response);
title('variant response channels');

nexttile;
plot_ablation_deltas(ablations);
title('ablation verification');

nexttile;
plot_identifiability(identifiability);
title('identifiability checks');

nexttile;
plot_numerical_sanity(sanity);
title('numerical sanity');

nexttile;
plot_firewall(firewall);
title('calibration firewall');

nexttile;
plot_gate_summary(gates);
title('Phase 13F.2 gates');

titleHandle = sgtitle( ...
    'Phase 13F.2 pre-fit limiting-case and ablation verification');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13F2.figureBaseFile '.png']);
saveas(h, [cfg.phase13F2.figureBaseFile '.pdf']);
end

function plot_variant_channels(T)
if isempty(T)
    empty_panel('missing variant response');
    return;
end
variants = unique(string(T.variant_id), 'stable');
normalState = zeros(numel(variants), 1);
lowT = zeros(numel(variants), 1);
transitionShift = zeros(numel(variants), 1);
f0Mid = metric(T, "F0", "combined_shunt_low_transfer", ...
    "transition_midpoint");
for k = 1:numel(variants)
    normalState(k) = metric(T, variants(k), "normal_baseline_slope", ...
        "normal_state_mean");
    lowT(k) = metric(T, variants(k), "lowT_residual_shunt", ...
        "lowT_mean");
    transitionShift(k) = abs(metric(T, variants(k), ...
        "combined_shunt_low_transfer", "transition_midpoint") - f0Mid);
end
bar([normalState, lowT, transitionShift]);
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants);
ylabel('synthetic proxy metric');
legend({'normal baseline', 'low-T floor', 'transition shift'}, ...
    'Location', 'northwest', 'Interpreter', 'none');
grid on;
end

function plot_ablation_deltas(T)
if isempty(T)
    empty_panel('missing ablation checks');
    return;
end
bar(T.observed_delta, 'FaceColor', [0.25 0.55 0.85]);
hold on;
plot(T.threshold, 'k--', 'LineWidth', 1.0);
hold off;
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.test_id));
xtickangle(30);
ylabel('observed delta');
legend({'observed', 'threshold'}, 'Location', 'best', ...
    'Interpreter', 'none');
grid on;
end

function plot_identifiability(T)
plot_status_bars(T.outcome, string(T.check_id), 'pass = 1');
end

function plot_numerical_sanity(T)
if isempty(T)
    empty_panel('missing numerical sanity');
    return;
end
variants = unique(string(T.variant_id), 'stable');
passFraction = zeros(numel(variants), 1);
for k = 1:numel(variants)
    mask = string(T.variant_id) == variants(k);
    passFraction(k) = mean(string(T.outcome(mask)) == "pass");
end
bar(passFraction, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(variants), 'XTickLabel', variants);
ylim([0 1.1]);
ylabel('pass fraction');
grid on;
end

function plot_firewall(T)
if isempty(T)
    empty_panel('missing firewall');
    return;
end
blocked = double(~logical(T.allowed) & string(T.status) == "false");
bar(blocked, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.item));
xtickangle(30);
ylim([0 1.2]);
ylabel('blocked cleanly = 1');
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
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

function plot_status_bars(outcome, labels, yLabelText)
if isempty(outcome)
    empty_panel('missing status checks');
    return;
end
isPass = double(string(outcome) == "pass");
bar(isPass, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylim([0 1.2]);
ylabel(yLabelText);
grid on;
end

function value = metric(T, variantId, caseId, metricName)
mask = string(T.variant_id) == string(variantId) & ...
    string(T.case_id) == string(caseId);
if any(mask)
    value = T.(char(metricName))(find(mask, 1));
else
    value = NaN;
end
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', ...
    'Color', 'k');
axis off;
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
