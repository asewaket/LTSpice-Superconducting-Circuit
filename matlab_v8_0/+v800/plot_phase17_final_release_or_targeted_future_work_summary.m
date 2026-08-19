function h = plot_phase17_final_release_or_targeted_future_work_summary(cfg, ...
    releaseBoundaryManifest, finalClaimTable, futureWorkQueue, ...
    scopePolicy, gateSummary)
%PLOT_PHASE17_FINAL_RELEASE_OR_TARGETED_FUTURE_WORK_SUMMARY Plot Phase 17.

h = figure('Name', 'v9 Phase 17 final release/future-work handoff', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_release_boundary(releaseBoundaryManifest);
plot_claim_split(finalClaimTable);
plot_future_work(futureWorkQueue);
plot_scope_policy(scopePolicy);
plot_closed_model(releaseBoundaryManifest);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 17 final release boundary and targeted future-work handoff', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase17.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase17.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_release_boundary(T)
nexttile;
closed = double(T.status == "frozen" | T.status == "declared" | ...
    contains(T.status, "preserved") | contains(T.status, "separated"));
bar(closed);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.item);
xtickangle(35);
ylim([0 1.2]);
ylabel('frozen = 1');
title('release boundary');
grid on;
end

function plot_claim_split(T)
nexttile;
counts = [sum(T.allowed_in_closed_model); ...
    sum(~T.allowed_in_closed_model)];
bar(counts);
set(gca, 'XTick', 1:2, 'XTickLabel', ["allowed", "blocked"]);
ylabel('claim count');
title('closed claim split');
grid on;
end

function plot_future_work(T)
nexttile;
bar(T.priority);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.work_item);
xtickangle(35);
ylabel('priority');
title('targeted future-work queue');
grid on;
end

function plot_scope_policy(T)
nexttile;
bar(ones(height(T), 1));
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.policy_item);
xtickangle(35);
ylim([0 1.2]);
title('scope policy recorded');
grid on;
end

function plot_closed_model(T)
nexttile;
items = ["closed_model_family"; "primary_field_model"; ...
    "preferred_spatial_representation"];
bar(double(ismember(items, T.item)));
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(30);
ylim([0 1.2]);
title('closed model identifiers');
grid on;
end

function plot_gate_summary(T)
nexttile;
cats = ["pass"; "fail"; "not_run"];
counts = zeros(numel(cats), 1);
for i = 1:numel(cats)
    counts(i) = sum(string(T.outcome) == cats(i));
end
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
ylabel('gate count');
title('Phase 17 gates');
grid on;
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
