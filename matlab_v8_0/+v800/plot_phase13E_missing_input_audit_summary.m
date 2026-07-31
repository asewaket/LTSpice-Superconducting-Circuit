function h = plot_phase13E_missing_input_audit_summary(cfg, ...
    deviceFailure, regionResiduals, layerDiagnosis, upgradeRanking, gates)
%PLOT_PHASE13E_MISSING_INPUT_AUDIT_SUMMARY Plot Phase 13E audit summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 13E missing-input audit', ...
    'Color', 'w', 'Position', [120 120 1750 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_device_residuals(deviceFailure);
title('device failure status');

nexttile;
plot_region_heatmap(regionResiduals);
title('temperature-region residuals');

nexttile;
plot_layer_diagnosis(layerDiagnosis);
title('diagnosed failure layer');

nexttile;
plot_upgrade_ranking(upgradeRanking);
title('candidate upgrade ranking');

nexttile;
plot_policy_note();
title('Phase 13E policy');

nexttile;
plot_gate_summary(gates);
title('Phase 13E gates');

titleHandle = sgtitle('Phase 13E missing-input/model-adequacy audit');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase13E.figureBaseFile '.png']);
saveas(h, [cfg.phase13E.figureBaseFile '.pdf']);
end

function plot_device_residuals(T)
bar(str2double(string(T.full_curve_residual)), ...
    'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
xtickangle(25);
ylabel('full-curve residual');
grid on;
end

function plot_region_heatmap(T)
devices = unique(string(T.device), 'stable');
regions = unique(string(T.temperature_region), 'stable');
M = nan(numel(devices), numel(regions));
for d = 1:numel(devices)
    for r = 1:numel(regions)
        mask = string(T.device) == devices(d) & ...
            string(T.temperature_region) == regions(r);
        if any(mask)
            M(d, r) = T.region_mse(find(mask, 1));
        end
    end
end
imagesc(M);
colorbar;
set(gca, 'XTick', 1:numel(regions), 'XTickLabel', regions, ...
    'YTick', 1:numel(devices), 'YTickLabel', devices);
xtickangle(25);
end

function plot_layer_diagnosis(T)
levels = strings(height(T), 1);
for k = 1:height(T)
    switch string(T.support_level(k))
        case "high"
            levels(k) = "3";
        case "moderate"
            levels(k) = "2";
        otherwise
            levels(k) = "1";
    end
end
bar(str2double(levels), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.layer));
xtickangle(25);
ylabel('support score');
ylim([0 3.5]);
grid on;
end

function plot_upgrade_ranking(T)
bar(T.score, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.upgrade));
xtickangle(25);
ylabel('ranking score');
grid on;
end

function plot_policy_note()
axis off;
text(0.05, 0.75, 'Diagnostic only: no optimizer rerun.', ...
    'FontWeight', 'bold', 'Color', 'k');
text(0.05, 0.55, 'Phase 13D partial-scope result is preserved.', ...
    'Color', 'k');
text(0.05, 0.35, 'Select at most two bounded future upgrades.', ...
    'Color', 'k');
text(0.05, 0.15, 'No device-specific mechanism fitting.', ...
    'Color', 'k');
end

function plot_gate_summary(T)
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
