function h = plot_phase16D_spatial_model_reduction_summary(cfg, ...
    spatialCandidateHierarchy, candidatePredictiveScores, ...
    spatialAblationSummary, connectivityReparameterization, ...
    ensembleComponentSupport, regionSupportSummary, gateSummary)
%PLOT_PHASE16D_SPATIAL_MODEL_REDUCTION_SUMMARY Plot Phase 16D diagnostics.

h = figure('Name', 'v9 Phase 16D spatial model reduction', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_score_complexity(candidatePredictiveScores);
plot_spatial_ablation(spatialAblationSummary);
plot_ensemble_support(ensembleComponentSupport);
plot_correlation_reduction(connectivityReparameterization);
plot_region_support(regionSupportSummary);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 16D geometry-aware spatial model reduction', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase16D.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase16D.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_score_complexity(T)
nexttile;
scatter(T.effective_spatial_dof, T.total_reduction_score, 90, 'filled');
hold on;
for i = 1:height(T)
    text(T.effective_spatial_dof(i) + 0.15, ...
        T.total_reduction_score(i), string(T.candidate_id(i)), ...
        'Interpreter', 'none', 'FontSize', 8);
end
pref = T.preferred;
scatter(T.effective_spatial_dof(pref), T.total_reduction_score(pref), ...
    180, 'p', 'filled');
xlabel('effective spatial degrees of freedom');
ylabel('penalized reduction score');
title('predictive score vs complexity');
grid on;
end

function plot_spatial_ablation(T)
nexttile;
bar(T.delta_score_when_removed);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.component);
xtickangle(35);
ylabel('score loss when removed');
title('geometry-component ablation');
grid on;
end

function plot_ensemble_support(T)
nexttile;
bar(T.support_probability);
yline(0.75, '--', 'robust', 'Color', [0.3 0.3 0.3]);
yline(0.55, ':', 'frequent', 'Color', [0.3 0.3 0.3]);
ylim([0 1]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.component);
xtickangle(35);
ylabel('support probability');
title('Phase 16C ensemble component support');
grid on;
end

function plot_correlation_reduction(T)
nexttile;
rows = ~isnan(T.before_reduction_mean_abs_correlation);
bar([T.before_reduction_mean_abs_correlation(rows), ...
    T.after_reduction_mean_abs_correlation(rows)]);
legend({'before reduction','after reduction'}, 'Location', 'best');
set(gca, 'XTick', 1:sum(rows), ...
    'XTickLabel', T.latent_component(rows));
xtickangle(35);
ylabel('mean |correlation|');
title('connectivity correlation reduction');
grid on;
end

function plot_region_support(T)
nexttile;
devices = unique(string(T.device), 'stable');
regions = unique(string(T.region_class), 'stable');
M = nan(numel(devices), numel(regions));
for i = 1:numel(devices)
    for j = 1:numel(regions)
        idx = string(T.device) == devices(i) & ...
            string(T.region_class) == regions(j);
        if any(idx)
            M(i, j) = T.transport_sensitive_support(find(idx, 1));
        end
    end
end
imagesc(M, [0 1]);
colorbar;
set(gca, 'XTick', 1:numel(regions), 'XTickLabel', regions);
set(gca, 'YTick', 1:numel(devices), 'YTickLabel', devices);
xtickangle(35);
title('region-level transport-sensitive support');
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
title('Phase 16D gates');
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
