function h = plot_as005_caseB_weaklink_sweep(sweepTable, bestRun)
%PLOT_AS005_CASEB_WEAKLINK_SWEEP Summary figure for v6.6 AS005 Case B sweep.

residualVals = unique(sweepTable.residualSuppression, 'stable');
icVals = unique(sweepTable.IcMultiplier, 'stable');
scoreGrid = nan(numel(residualVals), numel(icVals));
percGrid = nan(numel(residualVals), numel(icVals));

for ir = 1:numel(residualVals)
    for ii = 1:numel(icVals)
        idx = sweepTable.residualSuppression == residualVals(ir) & ...
            sweepTable.IcMultiplier == icVals(ii);
        if any(idx)
            T = sortrows(sweepTable(idx,:), 'combinedScore');
            scoreGrid(ir,ii) = T.combinedScore(1);
            percGrid(ir,ii) = T.sourceDrainPercOnset_K(1);
        end
    end
end

h = figure('Name', 'AS005 Case B weak-link sweep', 'Color', 'w', ...
    'Position', [80 80 1200 760]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
imagesc(icVals, residualVals, scoreGrid);
set(gca, 'YDir', 'normal');
colorbar;
xlabel('Ic multiplier');
ylabel('residual suppression');
title('best combined score, lower is better');
grid on; box on; apply_light_figure_style(gca);

nexttile;
imagesc(icVals, residualVals, percGrid);
set(gca, 'YDir', 'normal');
colorbar;
xlabel('Ic multiplier');
ylabel('residual suppression');
title('source-drain percolation onset [K]');
grid on; box on; apply_light_figure_style(gca);

nexttile;
hold on;
plot(sweepTable.model_rLow, sweepTable.combinedScore, 'o', ...
    'MarkerSize', 5, 'DisplayName', 'sweep points');
plot(bestRun.combinedScore .* 0 + sweepTable.exp_rLow(1), min(sweepTable.combinedScore), ...
    'kp', 'MarkerSize', 10, 'MarkerFaceColor', 'y', ...
    'DisplayName', 'experimental r_{low}');
xlabel('modeled low-T residual R/R_N');
ylabel('combined score');
title('score versus residual resistance');
grid on; box on; apply_light_figure_style(gca);
lgd = legend('Location', 'best'); apply_light_legend_style(lgd);

nexttile;
hold on;
expData = bestRun.expData;
expName = bestRun.expCurveName;
[Texp, RexpNorm] = normalize_rt_curve(expData.T, expData.R.(expName));
pairName = bestRun.modelPair;
if ~isfield(bestRun.result.R4p, pairName)
    pairName = first_fieldname(bestRun.result.R4p);
end
[Tmod, RmodNorm] = normalize_rt_curve(bestRun.result.T, bestRun.result.R4p.(pairName));
plot(Texp, RexpNorm, 'ko', 'MarkerSize', 4, 'DisplayName', 'experiment');
plot(Tmod, RmodNorm, '-', 'LineWidth', 2.2, 'Color', [0.0 0.45 0.74], ...
    'DisplayName', 'best Case B sweep');
xlabel('Temperature T [K]');
ylabel('R/R_N');
ylim([0 1.15]);
title('AS005 best Case B sweep R(T)');
grid on; box on; apply_light_figure_style(gca);
lgd = legend('Location', 'best'); apply_light_legend_style(lgd);

sgtitle('v6.6 AS005 out-of-plane/weak-link diagnostic sweep');

end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
