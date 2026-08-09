function h = plot_phase16E_final_recoverability_claim_freeze_summary(cfg, ...
    phaseChainManifest, recoverabilityClaimMatrix, finalModelClaims, ...
    preferredReducedModel, evidenceSynthesis, limitationLedger, gateSummary)
%PLOT_PHASE16E_FINAL_RECOVERABILITY_CLAIM_FREEZE_SUMMARY Plot Phase 16E.

h = figure('Name', 'v9 Phase 16E final recoverability claim freeze', ...
    'Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [80 80 1850 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_phase_chain(phaseChainManifest);
plot_claim_matrix(recoverabilityClaimMatrix);
plot_allowed_claims(finalModelClaims);
plot_preferred_model(preferredReducedModel);
plot_limitation_ledger(limitationLedger);
plot_gate_summary(gateSummary);

titleHandle = sgtitle( ...
    'Phase 16E final recoverability and model-claim freeze', ...
    'FontWeight', 'bold');
titleHandle.Color = 'k';
force_light_theme(h);

exportgraphics(h, [cfg.phase16E.figureBaseFile '.png'], 'Resolution', 200);
exportgraphics(h, [cfg.phase16E.figureBaseFile '.pdf'], ...
    'ContentType', 'vector');
end

function plot_phase_chain(T)
nexttile;
bar(double(contains(string(T.closure), "pass")));
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.phase);
xtickangle(35);
ylim([0 1.2]);
ylabel('closed = 1');
title('Phase 15E/16 chain consumed');
grid on;
end

function plot_claim_matrix(T)
nexttile;
allowed = double(T.claim_allowed);
bar(allowed);
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.quantity);
xtickangle(35);
ylim([0 1.2]);
ylabel('claim allowed');
title('recoverability claim matrix');
grid on;
end

function plot_allowed_claims(T)
nexttile;
cats = ["allowed"; "blocked"];
counts = [
    sum(T.allowed_in_manuscript)
    sum(~T.allowed_in_manuscript)
    ];
bar(counts);
set(gca, 'XTick', 1:numel(cats), 'XTickLabel', cats);
ylabel('claim count');
title('final model claims');
grid on;
end

function plot_preferred_model(T)
nexttile;
values = [
    T.effective_spatial_dof(1)
    T.structured_support(1)
    double(~T.unique_Wij_recovery(1))
    double(~T.dense_Pphi_primary(1))
    ];
bar(values);
labels = ["spatial DOF"; "structured support"; "Wij blocked"; "dense Pphi blocked"];
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
title('preferred reduced model');
grid on;
end

function plot_limitation_ledger(T)
nexttile;
bar(double(T.preserved_as_scientific_result));
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.limitation);
xtickangle(35);
ylim([0 1.2]);
ylabel('preserved = 1');
title('scientific limitations preserved');
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
title('Phase 16E gates');
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
