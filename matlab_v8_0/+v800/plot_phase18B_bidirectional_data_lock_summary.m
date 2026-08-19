function h = plot_phase18B_bidirectional_data_lock_summary(cfg, ...
    rawDataLock, branchCoverage, importIntegrityAudit, gateSummary)
%PLOT_PHASE18B_BIDIRECTIONAL_DATA_LOCK_SUMMARY Plot Phase 18B data lock.

h = figure('Name', 'v9 Phase 18B bidirectional data lock', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_raw_lock_status(rawDataLock);
plot_branch_matrix(branchCoverage);
plot_import_audit(importIntegrityAudit);
plot_branch_coverage_status(branchCoverage);
plot_policy_status(importIntegrityAudit);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 18B bidirectional sweep-rate raw data lock', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase18B.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase18B.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_raw_lock_status(T)
nexttile;
cats = ["locked"; "pending_raw_data"; "incomplete_or_invalid"];
counts = count_strings(T.row_status, cats);
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
xtickangle(35);
ylabel('row count');
title('raw ledger lock status');
grid on;
end

function plot_branch_matrix(T)
nexttile;
devices = unique(T.device, 'stable');
tiers = unique(T.sweep_rate_tier, 'stable');
M = zeros(numel(devices), numel(tiers));
for i = 1:numel(devices)
    for j = 1:numel(tiers)
        mask = T.device == devices(i) & T.sweep_rate_tier == tiers(j);
        if any(mask)
            M(i, j) = mean(double(T.both_branches_retained(mask)));
        end
    end
end
imagesc(M, [0 1]);
colormap(gca, parula);
colorbar;
set(gca, 'XTick', 1:numel(tiers), 'XTickLabel', tiers, ...
    'YTick', 1:numel(devices), 'YTickLabel', devices);
title('device/rate branch coverage');
xlabel('rate tier');
ylabel('device');
end

function plot_import_audit(T)
nexttile;
bar(double(T.condition));
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.item);
xtickangle(35);
ylim([0 1.2]);
ylabel('condition true = 1');
title('import integrity audit');
grid on;
end

function plot_branch_coverage_status(T)
nexttile;
cats = ["complete"; "partial"; "missing"];
counts = count_strings(T.coverage_status, cats);
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
ylabel('coverage cell count');
title('branch coverage status');
grid on;
end

function plot_policy_status(T)
nexttile;
items = [
    "no_branch_averaging"
    "no_proxy_substitution"
    "no_fitting"
    "no_model_execution"
    ];
values = zeros(numel(items), 1);
for i = 1:numel(items)
    idx = string(T.item) == items(i);
    if any(idx)
        values(i) = double(T.condition(find(idx, 1, 'first')));
    end
end
bar(values);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(35);
ylim([0 1.2]);
ylabel('policy satisfied = 1');
title('no-fit/no-proxy policy');
grid on;
end

function plot_gate_summary(T)
nexttile;
cats = ["pass"; "fail"; "not_run"];
counts = count_strings(T.outcome, cats);
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
ylabel('gate count');
title('Phase 18B gates');
grid on;
end

function counts = count_strings(values, cats)
values = string(values);
counts = zeros(numel(cats), 1);
for i = 1:numel(cats)
    counts(i) = sum(values == cats(i));
end
end

function force_light_theme(h)
axesHandles = findall(h, 'Type', 'axes');
for ax = reshape(axesHandles, 1, [])
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82 0.82 0.82], ...
        'MinorGridColor', [0.90 0.90 0.90]);
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
    if ~isempty(ax.ZLabel)
        ax.ZLabel.Color = 'k';
    end
end
end
