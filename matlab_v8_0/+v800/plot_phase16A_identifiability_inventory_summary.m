function h = plot_phase16A_identifiability_inventory_summary(cfg, ...
    inventory, constraints, recoverability, degeneracy, reductionQueue, ...
    gateSummary)
%PLOT_PHASE16A_IDENTIFIABILITY_INVENTORY_SUMMARY Plot Phase 16A summary.

h = figure('Name', 'v9 Phase 16A identifiability inventory', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1800 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_recoverability_counts(inventory);
plot_constraint_matrix(constraints);
plot_claim_policy(recoverability);
plot_degeneracy_actions(degeneracy);
plot_reduction_queue(reductionQueue);
plot_gate_summary(gateSummary);

titleHandle = sgtitle('Phase 16A global identifiability and model-reduction inventory', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase16A.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase16A.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_recoverability_counts(T)
nexttile;
classes = ["supported"; "partially_constrained"; "weakly_constrained"; ...
    "fixed_by_external_input"; "fixed_by_model_policy"; ...
    "non_identifiable"; "not_tested"];
counts = zeros(numel(classes), 1);
for i = 1:numel(classes)
    counts(i) = sum(string(T.classification) == classes(i) | ...
        contains(string(T.classification), classes(i)));
end
bar(counts);
set(gca, 'XTickLabel', classes);
xtickangle(35);
ylabel('quantity count');
title('latent-quantity recoverability');
grid on;
end

function plot_constraint_matrix(T)
nexttile;
M = [T.RT_primary, T.RT_secondary, T.dVdI_IT, T.dVdI_IB, ...
    T.Raman_geometry];
imagesc(M);
colormap(gca, parula(4));
colorbar;
set(gca, 'XTick', 1:5, 'XTickLabel', ...
    ["R(T) primary"; "R(T) secondary"; "dV/dI(I,T)"; ...
    "dV/dI(I,B)"; "Raman/geometry"]);
set(gca, 'YTick', 1:height(T), 'YTickLabel', string(T.quantity));
xtickangle(35);
title('observable constraint strength');
end

function plot_claim_policy(T)
nexttile;
policies = unique(string(T.claim_policy), 'stable');
counts = zeros(numel(policies), 1);
for i = 1:numel(policies)
    counts(i) = sum(string(T.claim_policy) == policies(i));
end
bar(counts);
set(gca, 'XTickLabel', policies);
xtickangle(35);
ylabel('quantity count');
title('claim-policy map');
grid on;
end

function plot_degeneracy_actions(T)
nexttile;
actions = unique(string(T.phase16B_action), 'stable');
counts = zeros(numel(actions), 1);
for i = 1:numel(actions)
    counts(i) = sum(string(T.phase16B_action) == actions(i));
end
bar(counts);
set(gca, 'XTickLabel', actions);
xtickangle(35);
ylabel('degeneracy count');
title('Phase 16B targets');
grid on;
end

function plot_reduction_queue(T)
nexttile;
bar(T.priority);
set(gca, 'XTickLabel', string(T.candidate_reduction));
xtickangle(35);
ylabel('priority rank');
title('model-reduction queue');
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
set(gca, 'XTickLabel', cats);
ylabel('gate count');
title('Phase 16A gates');
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
