function h = plot_phase12B_reduced_mechanical_summary(cfg, spec, ...
    deviceInputs, boundaryResults, crackResults, uncertaintySensitivity, ...
    deviceSummary, gates)
%PLOT_PHASE12B_REDUCED_MECHANICAL_SUMMARY Plot Phase 12B diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 12B reduced mechanical forward model', ...
    'Color', 'w', 'Position', [120 120 1700 940]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_component_proxy(deviceSummary);
title('mechanical components by device');

nexttile;
plot_boundary_linecut(boundaryResults);
title('boundary-transfer proxy');

nexttile;
plot_crack_proxy(crackResults);
title('crack-relaxation proxy');

nexttile;
plot_uncertainty(uncertaintySensitivity);
title('uncertainty sensitivity');

nexttile;
plot_policy_panel(spec);
title('frozen model policy');

nexttile;
plot_gate_summary(gates);
title('Phase 12B gates');

titleHandle = sgtitle( ...
    'Phase 12B reduced geometry-driven mechanical forward model');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase12B.figureBaseFile '.png']);
saveas(h, [cfg.phase12B.figureBaseFile '.pdf']);
end

function plot_component_proxy(T)
if isempty(T)
    empty_panel('missing device summary');
    return;
end
Y = [
    T.coverage_transfer_proxy, ...
    T.boundary_gradient_proxy, ...
    T.crack_relaxation_proxy
    ];
bar(Y);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('normalized proxy');
legend(["coverage", "boundary", "crack"], 'Location', 'northwest');
grid on;
end

function plot_boundary_linecut(T)
if isempty(T)
    empty_panel('missing boundary results');
    return;
end
devices = unique(string(T.device), 'stable');
hold on;
for k = 1:numel(devices)
    rows = T(string(T.device) == devices(k), :);
    plot(rows.lambda_b_um, rows.boundary_gradient_proxy, '-o', ...
        'DisplayName', devices(k), 'LineWidth', 1.0);
end
hold off;
xlabel('\lambda_b (um)');
ylabel('boundary proxy');
legend('Location', 'eastoutside');
grid on;
end

function plot_crack_proxy(T)
if isempty(T)
    empty_panel('missing crack results');
    return;
end
active = T(T.crack_amplitude > 0, :);
if isempty(active)
    empty_panel('no crack proxy active');
    return;
end
plot(active.lambda_c_um, active.crack_relaxation_proxy, '-o', ...
    'LineWidth', 1.2, 'Color', [0.85 0.35 0.15]);
xlabel('\lambda_c (um)');
ylabel('AS005 crack proxy');
ylim([0, max(1, max(active.crack_relaxation_proxy) + 0.05)]);
grid on;
end

function plot_uncertainty(T)
if isempty(T)
    empty_panel('missing uncertainty table');
    return;
end
devices = unique(string(T.device), 'stable');
meanDelta = zeros(numel(devices), 1);
for k = 1:numel(devices)
    rows = T(string(T.device) == devices(k), :);
    meanDelta(k) = mean(rows.absolute_change, 'omitnan');
end
bar(meanDelta, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('mean absolute proxy change');
grid on;
end

function plot_policy_panel(spec)
if isempty(spec)
    empty_panel('missing model specification');
    return;
end
cla;
axis off;
text(0.05, 0.82, 'Common reduced components:', ...
    'FontWeight', 'bold', 'Color', 'k');
items = string(spec.component_id);
for k = 1:numel(items)
    text(0.08, 0.82 - 0.11 * k, "- " + items(k), ...
        'Color', 'k', 'Interpreter', 'none');
end
text(0.05, 0.23, 'Raman-derived 2D field: blocked', ...
    'Color', [0.70 0.05 0.05], 'FontWeight', 'bold');
text(0.05, 0.12, 'Transport relabeling: blocked', ...
    'Color', [0.70 0.05 0.05], 'FontWeight', 'bold');
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
