function h = plot_phase7_raman_mechanical_prior_robustness(cfg, ...
    deviceRobustness, perturbationScenarios, gates)
%PLOT_PHASE7_RAMAN_MECHANICAL_PRIOR_ROBUSTNESS Plot Phase 7A audit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 7 Raman/mechanical prior robustness', ...
    'Color', 'w', 'Position', [120 120 1500 820]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_status_axis(deviceRobustness);
title('frozen status under prior audit');

nexttile;
plot_prior_dependency(deviceRobustness);
title('prior dependency by device');

nexttile;
plot_scenario_counts(perturbationScenarios);
title('declared perturbation scenarios');

nexttile;
plot_gate_summary(gates);
title('Phase 7A gates');

sgtitle('v8.0 Phase 7A Raman/mechanical prior robustness start');
apply_light_style(h);

saveas(h, [cfg.phase7.figureBaseFile '.png']);
saveas(h, [cfg.phase7.figureBaseFile '.pdf']);
end

function plot_status_axis(T)
if isempty(T)
    empty_panel('missing Phase 7 device robustness table');
    return;
end
x = zeros(height(T), 1);
for k = 1:height(T)
    switch string(T.phase6_model_status(k))
        case "M0star_sufficient"
            x(k) = -1;
        case "structured_supported"
            x(k) = 1;
        otherwise
            x(k) = 0;
    end
end
y = (1:height(T)).';
hold on;
for k = 1:height(T)
    scatter(x(k), y(k), 110, 'MarkerFaceColor', status_color(x(k)), ...
        'MarkerEdgeColor', 'k');
    text(x(k) + 0.05, y(k), T.device(k), ...
        'VerticalAlignment', 'middle', 'FontWeight', 'bold');
end
hold off;
xlim([-1.35 1.35]);
ylim([0.4 height(T) + 0.6]);
set(gca, 'XTick', [-1 0 1], ...
    'XTickLabel', ["M0* sufficient", "unresolved", "structured"]);
set(gca, 'YTick', []);
xlabel('Phase 6 status, frozen');
grid on;
end

function c = status_color(x)
if x < 0
    c = [0.35 0.45 0.85];
elseif x > 0
    c = [0.10 0.55 0.25];
else
    c = [0.75 0.35 0.75];
end
end

function plot_prior_dependency(T)
if isempty(T)
    empty_panel('missing Phase 7 device robustness table');
    return;
end
levels = strings(height(T), 1);
for k = 1:height(T)
    dep = string(T.prior_dependency(k));
    if contains(dep, "high")
        levels(k) = "high";
    elseif contains(dep, "moderate")
        levels(k) = "moderate";
    else
        levels(k) = "low";
    end
end
order = ["low"; "moderate"; "high"];
values = zeros(size(levels));
for k = 1:numel(order)
    values(levels == order(k)) = k;
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device, ...
    'YTick', 1:numel(order), 'YTickLabel', order);
xtickangle(25);
ylim([0.5 3.5]);
ylabel('qualitative dependency');
grid on;
end

function plot_scenario_counts(T)
if isempty(T)
    empty_panel('missing perturbation scenario table');
    return;
end
cats = unique(T.category, 'stable');
counts = zeros(numel(cats), 1);
for k = 1:numel(cats)
    counts(k) = sum(T.category == cats(k));
end
bar(counts, 'FaceColor', [0.95 0.55 0.15]);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
xtickangle(25);
ylabel('scenario count');
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
    counts(k) = sum(T.outcome == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', 'Color', 'k');
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
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
end
