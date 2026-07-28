function h = plot_phase5B_secondary_summary(cfg, secondaryLedger, evidence, classHeldout, gates)
%PLOT_PHASE5B_SECONDARY_SUMMARY Held-out probe and hierarchy diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5B secondary and hierarchy summary', ...
    'Color', 'w', 'Position', [120 120 1500 860]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_secondary_heatmap(cfg, secondaryLedger, evidence);
title('secondary score by device and mechanism');

nexttile;
plot_preferred_models(evidence);
title('preferred nested model by device');

nexttile;
plot_class_heldout(classHeldout);
title('class-aware held-out validation');

nexttile;
plot_gate_status(gates);
title('Phase 5B hierarchical gate status');

sgtitle('v8.0 Phase 5B held-out secondary-probe diagnostics');
apply_light_style(h);

saveas(h, [cfg.phase5B.figureBaseFile '.png']);
saveas(h, [cfg.phase5B.figureBaseFile '.pdf']);
end

function plot_secondary_heatmap(cfg, T, evidence)
idx = T.run_status == "scored";
if ~any(idx)
    text(0.5, 0.5, 'no scored secondary probes', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
D = cfg.devices(:);
M = unique(T.mechanism(idx), 'stable');
Z = NaN(numel(D), numel(M));
for i = 1:numel(D)
    for j = 1:numel(M)
        sidx = idx & T.device == D(i) & T.mechanism == M(j);
        if any(sidx)
            Z(i, j) = min(T.penalized_secondary_score(sidx));
        end
    end
end
imagesc(Z, 'AlphaData', isfinite(Z));
colorbar;
set(gca, 'Color', [0.88 0.88 0.88], 'XTick', 1:numel(M), ...
    'XTickLabel', M, 'YTick', 1:numel(D), 'YTickLabel', D, ...
    'Tag', 'phase5B_heatmap_axes');
xtickangle(30);
ylabel('device');
for i = 1:numel(D)
    eidx = evidence.device == D(i);
    isNA = false;
    if any(eidx)
        status = string(evidence.secondary_probe_status(find(eidx, 1, 'first')));
        isNA = status == "not_applicable";
    else
        isNA = ~any(idx & T.device == D(i));
    end
    if isNA
        text(max(1, ceil(numel(M) ./ 2)), i, 'N/A', ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
            'Color', [0.15 0.15 0.15]);
    end
end
end

function plot_preferred_models(T)
if isempty(T)
    text(0.5, 0.5, 'no evidence rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
levels = ["M0"; "M1"; "M2"; "structured"; "unresolved"; "not_applicable"];
Z = zeros(height(T), 1);
for k = 1:height(T)
    hit = find(levels == string(T.preferred_model(k)), 1, 'first');
    if isempty(hit)
        hit = numel(levels);
    end
    Z(k) = hit;
end
bar(Z);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device, ...
    'YTick', 1:numel(levels), 'YTickLabel', levels);
ylabel('preferred model');
ylim([0.5 numel(levels)+0.5]);
grid on;
end

function plot_class_heldout(T)
if isempty(T)
    text(0.5, 0.5, 'no class-heldout rows', ...
        'HorizontalAlignment', 'center', 'Color', 'k');
    axis off;
    return;
end
bar(T.margin_vs_controls);
labels = strcat(T.test, " ", T.withheld_device);
set(gca, 'XTick', 1:height(T), 'XTickLabel', labels);
xtickangle(30);
ylabel('margin vs controls');
yline(0, 'k-');
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
    if strcmp(get(ax, 'Tag'), 'phase5B_heatmap_axes')
        axColor = [0.88 0.88 0.88];
    else
        axColor = 'w';
    end
    set(ax, 'Color', axColor, 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 11, 'Box', 'on');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
colorbarList = findall(h, 'Type', 'ColorBar');
for k = 1:numel(colorbarList)
    set(colorbarList(k), 'Color', 'k');
end
end
