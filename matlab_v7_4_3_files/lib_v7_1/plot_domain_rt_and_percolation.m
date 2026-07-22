function h = plot_domain_rt_and_percolation(bestRuns)
%PLOT_DOMAIN_RT_AND_PERCOLATION Best v6.4 R(T) plus connectivity diagnostics.

valid = arrayfun(@(s) isfield(s, 'run') && ~isempty(s.run), bestRuns);
bestRuns = bestRuns(valid);
nDev = numel(bestRuns);

h = figure('Name', 'v6.4 R(T) and percolation comparison', 'Color', 'w', ...
    'Position', [80 80 1120 340*nDev]);
tiledlayout(nDev, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    run = bestRuns(d).run;
    expData = bestRuns(d).expData;
    expName = first_fieldname(expData.R);
    pairName = expData.modelPair;
    if ~isfield(run.result.R4p, pairName)
        pairName = first_fieldname(run.result.R4p);
    end

    nexttile;
    hold on;
    [Texp, RexpNorm] = normalize_rt_curve(expData.T, expData.R.(expName));
    [Tmod, RmodNorm] = normalize_rt_curve(run.result.T, run.result.R4p.(pairName));
    plot(Texp, RexpNorm, 'ko', 'MarkerSize', 4, 'DisplayName', 'experiment');
    plot(Tmod, RmodNorm, '-', 'LineWidth', 2.2, ...
        'Color', [0.0 0.45 0.74], 'DisplayName', 'best v6.4 domain model');
    xlabel('Temperature T [K]');
    ylabel('R/R_N');
    ylim([0 1.15]);
    title(sprintf('%s R(T), %s', run.device, run.domainVariant), 'Interpreter', 'none');
    grid on; box on; apply_light_figure_style(gca);
    lgd = legend('Location', 'best'); apply_light_legend_style(lgd);

    nexttile;
    hold on;
    plot(run.percolation.T, run.percolation.scLinkFraction, '-', 'LineWidth', 1.8, ...
        'DisplayName', 'SC-like link fraction');
    plot(run.percolation.T, run.percolation.largestClusterFraction, '-', 'LineWidth', 1.8, ...
        'DisplayName', 'largest SC cluster fraction');
    stairs(run.percolation.T, double(run.percolation.sourceDrainConnected), '--', ...
        'LineWidth', 1.8, 'DisplayName', 'source-drain connected');
    xlabel('Temperature T [K]');
    ylabel('fraction / connected');
    ylim([-0.05 1.05]);
    title(sprintf('%s percolation diagnostics', run.device));
    grid on; box on; apply_light_figure_style(gca);
    lgd = legend('Location', 'best'); apply_light_legend_style(lgd);
end

end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
