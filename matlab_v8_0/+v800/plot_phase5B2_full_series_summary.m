function h = plot_phase5B2_full_series_summary(cfg, predictions, joint, ...
    as004Profile, uncertaintySummary, gates)
%PLOT_PHASE5B2_FULL_SERIES_SUMMARY Full-series activation diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5B.2 full-series activation summary', ...
    'Color', 'w', 'Position', [120 120 1550 900]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_lambda_progression(predictions);
title('one-law \lambda_W progression');

nexttile;
plot_joint_comparison(joint);
title('joint half-series model comparison');

nexttile;
plot_as004_profile(as004Profile);
title('AS004 S(\lambda_W) profile');

nexttile;
plot_device_margins(predictions);
title('force law margin vs protected');

nexttile;
plot_uncertainty(uncertaintySummary);
title('seed uncertainty intervals');

nexttile;
plot_gate_status(gates);
title('Phase 5B.2 stopping gates');

sgtitle('v8.0 Phase 5B.2 full-series global activation consolidation');
apply_light_style(h);

saveas(h, [cfg.phase5B2.figureBaseFile '.png']);
saveas(h, [cfg.phase5B2.figureBaseFile '.pdf']);
end

function plot_lambda_progression(T)
if isempty(T)
    empty_panel('no device predictions');
    return;
end
bar(T.force_lambda_W);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
ylabel('\lambda_W');
ylim([0 max(1, max(T.force_lambda_W, [], 'omitnan') .* 1.1)]);
grid on;
end

function plot_joint_comparison(T)
if isempty(T)
    empty_panel('no joint comparison');
    return;
end
bar(T.joint_penalized_score);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.model);
xtickangle(30);
ylabel('joint penalized score');
grid on;
end

function plot_as004_profile(T)
if isempty(T)
    empty_panel('no AS004 profile');
    return;
end
plot(T.lambda_W, T.score, '-o', 'LineWidth', 1.4, 'MarkerSize', 4);
xlabel('\lambda_W');
ylabel('score, lower is better');
grid on;
end

function plot_device_margins(T)
if isempty(T)
    empty_panel('no margins');
    return;
end
bar(T.force_margin_vs_protected);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
yline(0, 'k-');
ylabel('protected score - force score');
grid on;
end

function plot_uncertainty(T)
if isempty(T)
    empty_panel('no uncertainty rows');
    return;
end
x = 1:height(T);
mid = T.median;
lo = T.p16;
hi = T.p84;
errLo = mid - lo;
errHi = hi - mid;
bar(x, mid);
hold on;
errorbar(x, mid, errLo, errHi, 'k.', 'LineWidth', 1.2);
hold off;
set(gca, 'XTick', x, 'XTickLabel', T.parameter);
xtickangle(30);
ylabel('median and 16-84% interval');
grid on;
end

function plot_gate_status(T)
if isempty(T)
    empty_panel('no gate rows');
    return;
end
statuses = ["pass"; "fail"; "incomplete"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.status == statuses(k));
end
bar(counts);
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
