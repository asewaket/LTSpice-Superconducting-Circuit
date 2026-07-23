function h = plot_ensemble_rt(spec, ensemble)
%PLOT_ENSEMBLE_RT Plot ensemble mean +/- one standard deviation.

h = figure('Color','w', 'Name', sprintf('%s ensemble R(T)', spec.name));
hold on;

pairNames = fieldnames(ensemble.R4pMean);
colors = lines(numel(pairNames));

for kp = 1:numel(pairNames)
    p = pairNames{kp};
    T = ensemble.T;
    mu = ensemble.R4pMean.(p);
    sig = ensemble.R4pStd.(p);

    fill([T fliplr(T)], [mu-sig fliplr(mu+sig)], colors(kp,:), ...
        'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
        'HandleVisibility','off');
    plot(T, mu, 'LineWidth', 2, 'Color', colors(kp,:), ...
        'DisplayName', strrep(p, '_', '\_'));
end

xlabel('Temperature T [K]');
ylabel('Four-probe resistance [\Omega]');
title(sprintf('%s ensemble R(T), %s, N = %d', ...
    spec.name, spec.filmForceLabel, ensemble.N));
apply_light_figure_style(gca);
lgd = legend('Location','best');
apply_light_legend_style(lgd);

end
