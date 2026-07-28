function h = plot_phase5C_synthetic_recovery_summary(cfg, recovery, summary, ...
    misspecSummary, gates)
%PLOT_PHASE5C_SYNTHETIC_RECOVERY_SUMMARY Mechanism-recovery diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 5C synthetic recovery summary', ...
    'Color', 'w', 'Position', [120 120 1550 900]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_confusion(recovery, "primary_only");
title('primary-only recovery');

nexttile;
plot_confusion(recovery, "primary_secondary_noise_disorder");
title('two-probe noisy/disordered recovery');

nexttile;
plot_structured_rates(summary);
title('structured-vs-M0 recovery');

nexttile;
plot_exact_rates(summary);
title('exact nested-model recovery');

nexttile;
plot_misspec_rates(misspecSummary);
title('misspecification challenge');

nexttile;
plot_gate_status(gates);
title('Phase 5C gates');

sgtitle('v8.0 Phase 5C synthetic mechanism-recovery study');
apply_light_style(h);

saveas(h, [cfg.phase5C.figureBaseFile '.png']);
saveas(h, [cfg.phase5C.figureBaseFile '.pdf']);
end

function plot_confusion(T, evidenceConfig)
idx = T.evidence_config == string(evidenceConfig);
if ~any(idx)
    empty_panel('no recovery rows');
    return;
end
trueModels = unique(T.true_model(idx), 'stable');
selectedModels = unique(T.selected_model(idx), 'stable');
Z = NaN(numel(trueModels), numel(selectedModels));
for i = 1:numel(trueModels)
    for j = 1:numel(selectedModels)
        ridx = idx & T.true_model == trueModels(i) & ...
            T.selected_model == selectedModels(j);
        if any(ridx)
            Z(i, j) = T.probability(find(ridx, 1, 'first'));
        end
    end
end
imagesc(Z, [0 1]);
colorbar;
set(gca, 'XTick', 1:numel(selectedModels), 'XTickLabel', selectedModels, ...
    'YTick', 1:numel(trueModels), 'YTickLabel', trueModels);
xlabel('selected model');
ylabel('true model');
for i = 1:numel(trueModels)
    for j = 1:numel(selectedModels)
        if isfinite(Z(i, j))
            text(j, i, sprintf('%.2f', Z(i, j)), ...
                'HorizontalAlignment', 'center', 'Color', 'k', ...
                'FontWeight', 'bold');
        end
    end
end
end

function plot_structured_rates(T)
if isempty(T)
    empty_panel('no summary rows');
    return;
end
bar(T.structured_vs_M0_recovery_rate);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.evidence_config);
xtickangle(30);
ylim([0 1]);
ylabel('recovery rate');
yline(0.8, 'k--');
grid on;
end

function plot_exact_rates(T)
if isempty(T)
    empty_panel('no summary rows');
    return;
end
bar(T.exact_recovery_rate);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.evidence_config);
xtickangle(30);
ylim([0 1]);
ylabel('exact recovery rate');
grid on;
end

function plot_misspec_rates(T)
if isempty(T)
    empty_panel('no misspecification rows');
    return;
end
Z = [T.M0_false_structured_rate, ...
    T.weak_structured_unresolved_rate, ...
    T.weak_structured_confident_M0_rate, ...
    T.structured_binary_recovery_rate];
bar(Z);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.evidence_config);
xtickangle(30);
ylim([0 1]);
ylabel('rate');
legend(["M0 false structured", "weak unresolved", ...
    "weak confident M0", "structured recovered"], ...
    'Location', 'best');
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
colorbarList = findall(h, 'Type', 'ColorBar');
for k = 1:numel(colorbarList)
    set(colorbarList(k), 'Color', 'k');
end
end
