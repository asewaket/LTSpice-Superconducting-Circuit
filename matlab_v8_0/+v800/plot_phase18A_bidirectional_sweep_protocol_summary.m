function h = plot_phase18A_bidirectional_sweep_protocol_summary(cfg, ...
    protocol, sweepRateMatrix, metadataSchema, acceptanceCriteria, ...
    noFitPolicy, gateSummary)
%PLOT_PHASE18A_BIDIRECTIONAL_SWEEP_PROTOCOL_SUMMARY Plot Phase 18A.

h = figure('Name', 'v9 Phase 18A bidirectional sweep protocol', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_protocol_status(protocol);
plot_sweep_matrix(sweepRateMatrix);
plot_metadata_schema(metadataSchema);
plot_acceptance_criteria(acceptanceCriteria);
plot_policy(noFitPolicy);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 18A bidirectional sweep-rate protocol freeze', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase18A.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase18A.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_protocol_status(T)
nexttile;
items = [
    "selected_experiment_id"
    "current_sweep_requirement"
    "sweep_rate_requirement"
    "raw_grid_requirement"
    "blocked_use"
    ];
bar(double(ismember(items, T.item)));
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(35);
ylim([0 1.2]);
title('protocol contract');
ylabel('declared = 1');
grid on;
end

function plot_sweep_matrix(T)
nexttile;
devices = unique(T.device, 'stable');
tiers = unique(T.sweep_rate_tier, 'stable');
M = zeros(numel(devices), numel(tiers));
for i = 1:numel(devices)
    for j = 1:numel(tiers)
        M(i, j) = sum(T.device == devices(i) & ...
            T.sweep_rate_tier == tiers(j) & T.required);
    end
end
imagesc(M);
colormap(gca, parula);
colorbar;
set(gca, 'XTick', 1:numel(tiers), 'XTickLabel', tiers, ...
    'YTick', 1:numel(devices), 'YTickLabel', devices);
title('device by sweep-rate matrix');
xlabel('rate tier');
ylabel('device');
end

function plot_metadata_schema(T)
nexttile;
cats = ["required"; "optional"];
counts = [sum(T.required); sum(~T.required)];
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
ylabel('field count');
title('metadata requirements');
grid on;
end

function plot_acceptance_criteria(T)
nexttile;
passRequired = T.required_result == "pass";
bar([sum(passRequired); sum(~passRequired)]);
set(gca, 'XTick', 1:2, 'XTickLabel', ["must pass"; "other"]);
ylabel('criterion count');
title('future lock criteria');
grid on;
end

function plot_policy(T)
nexttile;
blocked = contains(T.status, "blocked");
allowed = contains(T.status, "metadata") | contains(T.status, "historical");
bar([sum(allowed); sum(blocked)]);
set(gca, 'XTick', 1:2, 'XTickLabel', ["allowed/closed"; "blocked"]);
ylabel('policy item count');
title('no-fit policy');
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
title('Phase 18A gates');
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
