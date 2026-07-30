function h = plot_phase10_reproducible_release(cfg, releaseManifest, ...
    checksums, gates, provenance)
%PLOT_PHASE10_REPRODUCIBLE_RELEASE Plot final release dossier diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 10 reproducible release', ...
    'Color', 'w', 'Position', [100 100 1600 900]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_manifest_status(releaseManifest);
title('release manifest');

nexttile;
plot_checksum_status(checksums);
title('artifact checksums');

nexttile;
plot_provenance(provenance);
title('source provenance');

nexttile;
plot_gate_summary(gates);
title('Phase 10 gates');

titleHandle = sgtitle('v8.0 Phase 10 reproducible release dossier');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase10.figureBaseFile '.png']);
saveas(h, [cfg.phase10.figureBaseFile '.pdf']);
end

function plot_manifest_status(T)
if isempty(T)
    empty_panel('missing release manifest');
    return;
end
statuses = ["present"; "missing"];
counts = [sum(T.exists); sum(~T.exists)];
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('artifact count');
grid on;
end

function plot_checksum_status(T)
if isempty(T)
    empty_panel('missing checksum table');
    return;
end
statuses = ["computed"; "missing_file"; "unavailable"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.checksum_status == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(20);
ylabel('artifact count');
grid on;
end

function plot_provenance(T)
if isempty(T)
    empty_panel('missing provenance');
    return;
end
items = [
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    ];
values = zeros(numel(items), 1);
for k = 1:numel(items)
    values(k) = lookup_value(T, items(k), "false") == "true";
end
bar(values, 'FaceColor', [0.25 0.55 0.85]);
ylim([0 1]);
set(gca, 'XTick', 1:numel(items), 'XTickLabel', ...
    ["tracked", "untracked", "full"]);
ylabel('clean = 1');
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

function value = lookup_value(T, itemName, defaultValue)
value = string(defaultValue);
if isempty(T) || ~all(ismember(["item", "value"], string(T.Properties.VariableNames)))
    return;
end
idx = string(T.item) == string(itemName);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
end
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
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
end
