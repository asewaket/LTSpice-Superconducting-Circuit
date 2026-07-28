function h = plot_phase5D_calibration_summary(cfg, nuisanceLedger, ...
    deltaS, thresholds, boundaryCurves, gates)
%PLOT_PHASE5D_CALIBRATION_SUMMARY Plot Phase 5D.1 calibration diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5D.1 M0star calibration summary', ...
    'Color', 'w', 'Position', [120 120 1550 900]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_nuisance_profile_counts(nuisanceLedger);
title('selected M0* nuisance profiles');

nexttile;
plot_deltaS(deltaS);
title('\DeltaS by evidence tier');

nexttile;
plot_zcrit(thresholds);
title('frozen calibration thresholds');

nexttile;
plot_boundary_curves(boundaryCurves);
title('boundary-strength detection');

nexttile;
plot_state_confusion(deltaS);
title('calibration state by true group');

nexttile;
plot_gate_status(gates);
title('Phase 5D.1 gates');

sgtitle('v8.0 Phase 5D.1 nuisance-aware calibration');
apply_light_style(h);

saveas(h, [cfg.phase5D.calibrationSummaryFigureBaseFile '.png']);
saveas(h, [cfg.phase5D.calibrationSummaryFigureBaseFile '.pdf']);
end

function plot_nuisance_profile_counts(T)
if isempty(T)
    empty_panel('no nuisance ledger');
    return;
end
cases = unique(T(:, {'synthetic_id','profile_id'}), 'rows');
profiles = unique(cases.profile_id, 'stable');
counts = zeros(numel(profiles), 1);
for k = 1:numel(profiles)
    counts(k) = sum(cases.profile_id == profiles(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(profiles), 'XTickLabel', profiles);
xtickangle(35);
ylabel('selected case count');
grid on;
end

function plot_deltaS(T)
if isempty(T)
    empty_panel('no Delta-S rows');
    return;
end
tiers = unique(T.evidence_tier, 'stable');
groups = unique(T.true_group, 'stable');
Z = NaN(numel(groups), numel(tiers));
for i = 1:numel(groups)
    for j = 1:numel(tiers)
        idx = T.true_group == groups(i) & T.evidence_tier == tiers(j);
        Z(i, j) = mean(T.deltaS(idx), 'omitnan');
    end
end
bar(Z);
set(gca, 'XTick', 1:numel(groups), 'XTickLabel', groups);
xtickangle(30);
ylabel('mean \DeltaS');
legend(tiers, 'Location', 'best');
yline(0, 'k-');
grid on;
end

function plot_zcrit(T)
if isempty(T)
    empty_panel('no thresholds');
    return;
end
bar(T.Zcrit);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.evidence_tier);
xtickangle(25);
ylabel('Zcrit');
grid on;
end

function plot_boundary_curves(T)
if isempty(T)
    empty_panel('no boundary curves');
    return;
end
tiers = unique(T.evidence_tier, 'stable');
colors = lines(numel(tiers));
hold on;
for k = 1:numel(tiers)
    idx = T.evidence_tier == tiers(k);
    plot(T.lambda_W(idx), T.P_structured(idx), '-o', ...
        'Color', colors(k, :), 'DisplayName', tiers(k));
end
hold off;
xlabel('\lambda_W');
ylabel('P(structured supported)');
ylim([0 1]);
legend('Location', 'best');
grid on;
end

function plot_state_confusion(T)
if isempty(T)
    empty_panel('no classified rows');
    return;
end
groups = unique(T.true_group, 'stable');
states = ["M0star_supported"; "unresolved"; "structured_supported"];
Z = NaN(numel(groups), numel(states));
for i = 1:numel(groups)
    idxGroup = T.true_group == groups(i);
    denom = sum(idxGroup);
    for j = 1:numel(states)
        Z(i, j) = sum(idxGroup & T.selected_state == states(j)) ./ ...
            max(1, denom);
    end
end
bar(Z, 'stacked');
set(gca, 'XTick', 1:numel(groups), 'XTickLabel', groups);
xtickangle(30);
ylim([0 1]);
ylabel('fraction');
legend(states, 'Location', 'best');
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
legendList = findall(h, 'Type', 'Legend');
for k = 1:numel(legendList)
    set(legendList(k), 'TextColor', 'k', 'Color', 'w', ...
        'EdgeColor', [0.4 0.4 0.4]);
end
end
