function h = plot_raman_hybrid_rt_comparison(allSweeps, sweepTable)
%PLOT_RAMAN_HYBRID_RT_COMPARISON Compare experiment, geometry-only, best hybrid.

devices = string({allSweeps.device});
devices = devices(devices ~= "");
nDev = numel(devices);

h = figure('Name', 'Raman-hybrid R(T) comparison', 'Color', 'w', ...
    'Position', [80 80 1050 320 * nDev]);
tiledlayout(nDev, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    item = allSweeps(d);
    device = string(item.device);
    expData = item.expData;
    expName = first_fieldname(expData.R);
    [Texp, RexpNorm] = normalize_rt_curve(expData.T, expData.R.(expName));

    Tdev = sweepTable(string(sweepTable.device) == device, :);
    [~, bestRowLocal] = min(Tdev.score);
    bestAlpha = Tdev.alpha(bestRowLocal);

    nexttile;
    hold on;
    plot(Texp, RexpNorm, 'ko', 'MarkerSize', 4, ...
        'DisplayName', 'experiment');

    run0 = find_run_by_alpha(item.runs, 0);
    plot_model_run(run0, item.runs(1).modelPair, '-', [0.35 0.35 0.35], ...
        sprintf('geometry only, \\alpha=0'));

    runBest = find_run_by_alpha(item.runs, bestAlpha);
    plot_model_run(runBest, runBest.modelPair, '-', [0.00 0.45 0.74], ...
        sprintf('best Raman hybrid, \\alpha=%.2g', bestAlpha));

    if bestAlpha ~= 1
        runPure = find_run_by_alpha(item.runs, 1);
        if ~isempty(runPure)
            plot_model_run(runPure, runPure.modelPair, '--', [0.85 0.33 0.10], ...
                'Raman-heavy, \alpha=1');
        end
    end

    xlabel('Temperature T [K]');
    ylabel('R/R_N');
    title(sprintf('%s normalized R(T): experiment vs geometry-only vs Raman-hybrid', device));
    ylim([0 1.15]);
    grid on;
    box on;
    apply_light_figure_style(gca);
    lgd = legend('Location', 'best');
    apply_light_legend_style(lgd);
end

end

function plot_model_run(runEntry, pairName, lineStyle, color, labelText)
if isempty(runEntry)
    return;
end
ens = runEntry.ensemble;
if ~isfield(ens.R4pMean, pairName)
    pairName = first_fieldname(ens.R4pMean);
end
[T, Rnorm] = normalize_rt_curve(ens.T, ens.R4pMean.(pairName));
plot(T, Rnorm, lineStyle, 'LineWidth', 2.2, 'Color', color, ...
    'DisplayName', labelText);
end

function runEntry = find_run_by_alpha(runs, alpha)
runEntry = [];
for k = 1:numel(runs)
    if abs(runs(k).alpha - alpha) < 1e-10
        runEntry = runs(k);
        return;
    end
end
end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
