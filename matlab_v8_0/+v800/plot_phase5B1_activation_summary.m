function h = plot_phase5B1_activation_summary(cfg, heldout, preservation, gates)
%PLOT_PHASE5B1_ACTIVATION_SUMMARY Diagnostics for global activation laws.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5B.1 activation-law summary', ...
    'Color', 'w', 'Position', [120 120 1500 860]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_heldout_scores(heldout);
title('heldout score: binary vs force law');

nexttile;
plot_activation_strengths(heldout);
title('predicted \lambda_W by heldout device');

nexttile;
plot_secondary_preservation(preservation);
title('secondary evidence preservation');

nexttile;
plot_gate_status(gates);
title('Phase 5B.1 gate status');

sgtitle('v8.0 Phase 5B.1 global activation-law validation');
apply_light_style(h);

saveas(h, [cfg.phase5B1.figureBaseFile '.png']);
saveas(h, [cfg.phase5B1.figureBaseFile '.pdf']);
end

function plot_heldout_scores(T)
if isempty(T)
    text(0.5, 0.5, 'no heldout rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
Y = [T.binary_score, T.force_modulated_score, ...
    T.best_protected_alternative_score];
bar(Y);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.withheld_device);
ylabel('score, lower is better');
legend({'binary','force-modulated','best protected'}, ...
    'Location', 'best');
grid on;
end

function plot_activation_strengths(T)
if isempty(T)
    text(0.5, 0.5, 'no activation rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
Y = [T.binary_lambda_W, T.force_lambda_W];
bar(Y);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.withheld_device);
ylabel('\lambda_W');
ylim([0 max(1, max(Y(:), [], 'omitnan') .* 1.1)]);
legend({'binary','force-modulated'}, 'Location', 'best');
grid on;
end

function plot_secondary_preservation(T)
if isempty(T)
    text(0.5, 0.5, 'no preservation rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
statusValues = ["fail"; "incomplete"; "pass"];
Z = zeros(height(T), 1);
for k = 1:height(T)
    hit = find(statusValues == string(T.preservation_status(k)), 1, 'first');
    if isempty(hit)
        hit = 2;
    end
    Z(k) = hit - 2;
end
bar(Z);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device, ...
    'YTick', -1:1, 'YTickLabel', ["fail"; "incomplete"; "pass"]);
ylim([-1.5 1.5]);
yline(0, 'k-');
ylabel('status');
grid on;
end

function plot_gate_status(T)
if isempty(T)
    text(0.5, 0.5, 'no gate rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
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

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 11, 'Box', 'on');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
end
