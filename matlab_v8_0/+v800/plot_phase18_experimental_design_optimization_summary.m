function h = plot_phase18_experimental_design_optimization_summary(cfg, ...
    unresolvedTargets, candidateLibrary, informationGain, ...
    experimentRanking, recommendationFreeze, gateSummary)
%PLOT_PHASE18_EXPERIMENTAL_DESIGN_OPTIMIZATION_SUMMARY Plot Phase 18.

h = figure('Name', 'v9 Phase 18 experimental design optimization', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_unresolved_targets(unresolvedTargets);
plot_information_gain(experimentRanking);
plot_value_cost(candidateLibrary, informationGain);
plot_degeneracy_reduction(experimentRanking, informationGain);
plot_recommendations(recommendationFreeze);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 18 experimental design optimization after closed v9 model', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase18.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase18.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_unresolved_targets(T)
nexttile;
classes = unique(T.target_class, 'stable');
counts = zeros(numel(classes), 1);
for k = 1:numel(classes)
    counts(k) = sum(T.target_class == classes(k));
end
bar(counts);
set(gca, 'XTick', 1:numel(classes), 'XTickLabel', classes);
xtickangle(35);
ylabel('target count');
title('unresolved discrimination targets');
grid on;
end

function plot_information_gain(T)
nexttile;
topN = min(6, height(T));
bar(T.information_gain_score(1:topN));
set(gca, 'XTick', 1:topN, ...
    'XTickLabel', T.candidate_measurement(1:topN));
xtickangle(35);
ylabel('information-gain proxy');
title('top experiment scores');
grid on;
end

function plot_value_cost(library, informationGain)
nexttile;
scatter(double(library.experimental_difficulty), ...
    informationGain.information_gain_score, 80, 'filled');
text(double(library.experimental_difficulty) + 0.05, ...
    informationGain.information_gain_score, library.experiment_id, ...
    'FontSize', 8);
xlabel('experimental difficulty');
ylabel('information-gain proxy');
title('value versus difficulty');
grid on;
end

function plot_degeneracy_reduction(ranking, informationGain)
nexttile;
[~, order] = ismember(ranking.experiment_id, informationGain.experiment_id);
vals = informationGain.targeted_degeneracy_reduction(order);
topN = min(6, height(ranking));
bar(vals(1:topN));
set(gca, 'XTick', 1:topN, ...
    'XTickLabel', ranking.candidate_measurement(1:topN));
xtickangle(35);
ylabel('drop in |rho|');
title('boundary/coverage degeneracy reduction');
grid on;
end

function plot_recommendations(T)
nexttile;
items = [
    "highest_value_near_term"
    "highest_value_transport_only"
    "highest_value_dynamic_test"
    "highest_value_phase_test"
    "highest_value_strain_tensor_test"
    ];
bar(double(ismember(items, T.item)));
set(gca, 'XTick', 1:numel(items), 'XTickLabel', items);
xtickangle(35);
ylim([0 1.2]);
title('recommendation freeze');
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
title('Phase 18 gates');
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
