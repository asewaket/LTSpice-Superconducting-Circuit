function h = plot_phase13B_limiting_case_summary(cfg, response, behavior, ...
    ablations, checks, firewall, gates)
%PLOT_PHASE13B_LIMITING_CASE_SUMMARY Plot Phase 13B diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13B limiting-case verification', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_limiting_response(response);
title('synthetic limiting-case response');

nexttile;
plot_device_expected_behavior(behavior);
title('device proxy response');

nexttile;
plot_required_ablations(ablations);
title('required ablations');

nexttile;
plot_monotonicity(checks);
title('monotonicity checks');

nexttile;
plot_firewall(firewall);
title('calibration firewall');

nexttile;
plot_gate_summary(gates);
title('Phase 13B gates');

titleHandle = sgtitle( ...
    'Phase 13B limiting cases, synthetic behavior, and ablations');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13B.figureBaseFile '.png']);
saveas(h, [cfg.phase13B.figureBaseFile '.pdf']);
end

function plot_limiting_response(T)
if isempty(T)
    empty_panel('missing limiting response');
    return;
end
vals = [T.delta_Tc_vs_zero_K, T.delta_W_vs_zero];
bar(vals);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.case_id));
xtickangle(30);
ylabel('proxy delta vs zero');
legend({'\Delta Tc support', '\Delta W support'}, ...
    'Location', 'northwest', 'Interpreter', 'none');
grid on;
end

function plot_device_expected_behavior(T)
if isempty(T)
    empty_panel('missing device behavior');
    return;
end
vals = [T.Tc_support_K, T.W_support];
bar(vals);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylabel('proxy value');
legend({'Tc support K', 'W support'}, ...
    'Location', 'northwest', 'Interpreter', 'none');
grid on;
end

function plot_required_ablations(T)
if isempty(T)
    empty_panel('missing ablations');
    return;
end
mask = (string(T.device) == "AS005" & ...
    string(T.removed_component) == "crack") | ...
    (string(T.device) == "AS006" & ...
    string(T.removed_component) == "boundary");
S = T(mask, :);
if isempty(S)
    empty_panel('missing required ablations');
    return;
end
labels = string(S.device) + " remove " + string(S.removed_component);
bar([S.delta_Tc_support_K, S.delta_W_support]);
set(gca, 'XTick', 1:height(S), 'XTickLabel', labels);
xtickangle(25);
ylabel('full minus ablated');
legend({'\Delta Tc support', '\Delta W support'}, ...
    'Location', 'northwest', 'Interpreter', 'none');
grid on;
end

function plot_monotonicity(T)
if isempty(T)
    empty_panel('missing monotonicity checks');
    return;
end
isPass = double(string(T.outcome) == "pass");
bar(isPass, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.check_id));
xtickangle(30);
ylim([0 1.2]);
ylabel('pass = 1');
grid on;
end

function plot_firewall(T)
if isempty(T)
    empty_panel('missing firewall');
    return;
end
blocked = double(~T.allowed & string(T.status) == "false");
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
