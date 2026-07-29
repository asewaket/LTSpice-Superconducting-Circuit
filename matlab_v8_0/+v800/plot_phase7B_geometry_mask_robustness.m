function h = plot_phase7B_geometry_mask_robustness(cfg, annotations, ...
    crackSensitivity, geometrySensitivity, gates)
%PLOT_PHASE7B_GEOMETRY_MASK_ROBUSTNESS Plot Phase 7B-G summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 7B-G geometry/mask robustness', ...
    'Color', 'w', 'Position', [120 120 1500 820]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_device_sensitivity(annotations);
title('device prior sensitivity');

nexttile;
plot_crack_boundary_sensitivity(crackSensitivity, geometrySensitivity);
title('crack and boundary variants');

nexttile;
plot_registration_availability(gates);
title('registered Raman rescore status');

nexttile;
plot_gate_summary(gates);
title('Phase 7B-G gates');

titleHandle = sgtitle( ...
    'v8.0 Phase 7B-G geometry/mechanical-mask robustness');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase7B.figureBaseFile '.png']);
saveas(h, [cfg.phase7B.figureBaseFile '.pdf']);
end

function plot_device_sensitivity(T)
if isempty(T)
    empty_panel('missing annotation table');
    return;
end
bar(T.max_abs_score_change, 'FaceColor', [0.25 0.55 0.85]);
yline(0.05, 'k--', 'sensitivity marker');
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
xtickangle(25);
ylabel('max |\DeltaS_{prior}|');
grid on;
end

function plot_crack_boundary_sensitivity(crackT, geomT)
hold on;
if ~isempty(crackT)
    completed = crackT.prior_data_available;
    scatter(repmat(1, sum(completed), 1), ...
        crackT.score_change(completed), 90, 'filled', ...
        'DisplayName', 'AS005 crack');
end
if ~isempty(geomT)
    boundaryIdx = startsWith(geomT.variant_id, "boundary_") & ...
        geomT.prior_data_available;
    scatter(repmat(2, sum(boundaryIdx), 1), ...
        geomT.score_change(boundaryIdx), 90, 'filled', ...
        'DisplayName', 'AS004/AS006 boundary');
end
yline(0, 'k-', 'HandleVisibility', 'off');
hold off;
set(gca, 'XTick', [1 2], 'XTickLabel', ["crack", "boundary"]);
xlim([0.5 2.5]);
allY = [];
if ~isempty(crackT)
    allY = [allY; crackT.score_change(crackT.prior_data_available)];
end
if ~isempty(geomT)
    allY = [allY; geomT.score_change(boundaryIdx)];
end
if ~isempty(allY)
    yMax = max([0; allY]);
    yMin = min([0; allY]);
    pad = max(0.015, 0.15 * (yMax - yMin));
    ylim([yMin - pad, yMax + pad]);
end
ylabel('\DeltaS_{variant-reference}');
legend('Location', 'best');
grid on;
end

function plot_registration_availability(gates)
if isempty(gates)
    empty_panel('missing gate table');
    return;
end
idx = gates.component == "Registration robustness";
if any(idx)
    status = gates.outcome(find(idx, 1));
    text(0.5, 0.78, "Quantitative registered Raman rescore", ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'FontSize', 12, 'Color', 'k');
    text(0.5, 0.62, upper(strrep(status, "_", " ")), ...
        'HorizontalAlignment', 'center', 'FontSize', 18, ...
        'FontWeight', 'bold', 'Color', [0.65 0.05 0.05]);
    text(0.5, 0.42, ...
        "Reason: no defensible device-to-model spatial transforms", ...
        'HorizontalAlignment', 'center', 'FontSize', 10, ...
        'Color', 'k');
    text(0.5, 0.29, ...
        "Raman role: qualitative independent mechanical context", ...
        'HorizontalAlignment', 'center', 'FontSize', 10, ...
        'Color', 'k');
else
    text(0.5, 0.5, "not recorded", 'HorizontalAlignment', 'center', ...
        'Color', 'k');
end
axis([0 1 0 1]);
set(gca, 'XTick', [], 'YTick', []);
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
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
legendList = findall(h, 'Type', 'Legend');
for k = 1:numel(legendList)
    set(legendList(k), 'TextColor', 'k', 'Color', 'w', ...
        'EdgeColor', [0.4 0.4 0.4]);
end
end
