function h = plot_raman_variant_best_rt_comparison(bestRuns)
%PLOT_RAMAN_VARIANT_BEST_RT_COMPARISON Show best v6.1 variant per device.

valid = arrayfun(@(s) isfield(s, 'run') && ~isempty(s.run), bestRuns);
bestRuns = bestRuns(valid);
nDev = numel(bestRuns);

h = figure('Name', 'Best Raman variant R(T) comparison', 'Color', 'w', ...
    'Position', [90 90 1050 320*nDev]);
tiledlayout(nDev, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    item = bestRuns(d);
    run = item.run;
    expData = item.expData;
    expName = first_fieldname(expData.R);
    [Texp, RexpNorm] = normalize_rt_curve(expData.T, expData.R.(expName));

    nexttile;
    hold on;
    plot(Texp, RexpNorm, 'ko', 'MarkerSize', 4, ...
        'DisplayName', 'experiment');

    pairName = expData.modelPair;
    if ~isfield(run.result.R4p, pairName)
        pairName = first_fieldname(run.result.R4p);
    end
    [Tmod, RmodNorm] = normalize_rt_curve(run.result.T, run.result.R4p.(pairName));
    plot(Tmod, RmodNorm, '-', 'LineWidth', 2.3, ...
        'Color', [0.0 0.45 0.74], 'DisplayName', 'best v6.1 Raman variant');

    v = run.variant;
    variantText = sprintf('%s, %s, %s, %s, \\alpha=%.2g', ...
        v.modeName, v.referenceName, v.representationName, v.couplingMode, v.alpha);
    title(sprintf('%s best v6.1 variant: %s', run.device, variantText), ...
        'Interpreter', 'none');
    xlabel('Temperature T [K]');
    ylabel('R/R_N');
    ylim([0 1.15]);
    grid on;
    box on;
    apply_light_figure_style(gca);
    lgd = legend('Location', 'best');
    apply_light_legend_style(lgd);
end

end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
