function [hAbs, hNorm] = plot_model_experiment_overlay(spec, result, ensemble, expData)
%PLOT_MODEL_EXPERIMENT_OVERLAY Plot model and experimental R(T), absolute/normalized.

colors = lines(4);

hAbs = figure('Color','w', 'Name', sprintf('%s model-exp absolute', spec.name));
hold on;
plot_model_curves(result, [], false, colors);
if expData.available
    plot_experiment_curves(expData, false, colors);
end
xlabel('Temperature T [K]');
ylabel('Four-probe resistance [\Omega]');
title(sprintf('%s absolute R(T), %s', spec.name, spec.filmForceLabel));
apply_light_figure_style(gca);
lgd = legend('Location','best');
apply_light_legend_style(lgd);

hNorm = figure('Color','w', 'Name', sprintf('%s model-exp normalized', spec.name));
hold on;
plot_model_curves(result, [], true, colors);
if expData.available
    plot_experiment_curves(expData, true, colors);
end
xlabel('Temperature T [K]');
ylabel('R(T)/R_N');
title(sprintf('%s normalized R(T), %s', spec.name, spec.filmForceLabel));
apply_light_figure_style(gca);
lgd = legend('Location','best');
apply_light_legend_style(lgd);

if ~expData.available
    annotation(hAbs, 'textbox', [0.15 0.78 0.7 0.12], ...
        'String', sprintf('No mapped experimental R(T) file yet. %s', expData.note), ...
        'FitBoxToText','on', 'BackgroundColor','w');
    annotation(hNorm, 'textbox', [0.15 0.78 0.7 0.12], ...
        'String', sprintf('No mapped experimental R(T) file yet. %s', expData.note), ...
        'FitBoxToText','on', 'BackgroundColor','w');
end

end

function plot_model_curves(result, ensemble, doNormalize, colors)

pairNames = fieldnames(result.R4p);

for kp = 1:numel(pairNames)
    p = pairNames{kp};
    T = result.T;
    R = result.R4p.(p);

    if doNormalize
        [T, R, ~] = normalize_rt_curve(T, R);
        ylab = sprintf('model %s', strrep(p, '_', '\_'));
    else
        ylab = sprintf('model %s', strrep(p, '_', '\_'));
    end

    plot(T, R, '-', 'LineWidth', 1.8, 'Color', colors(kp,:), ...
        'DisplayName', ylab);

    if nargin >= 2 && ~isempty(ensemble) && isfield(ensemble, 'R4pMean') && isfield(ensemble.R4pMean, p)
        mu = ensemble.R4pMean.(p);
        sig = ensemble.R4pStd.(p);
        if doNormalize
            [~, mu, RN] = normalize_rt_curve(ensemble.T, mu);
            sig = sig ./ RN;
        end
        fill([ensemble.T fliplr(ensemble.T)], [mu-sig fliplr(mu+sig)], colors(kp,:), ...
            'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility','off');
    end
end

end

function plot_experiment_curves(expData, doNormalize, colors)

rNames = fieldnames(expData.R);

for kr = 1:numel(rNames)
    rName = rNames{kr};
    T = local_numeric_vector(expData.T);
    R = local_numeric_vector(expData.R.(rName));

    n = min(numel(T), numel(R));
    T = T(1:n);
    R = R(1:n);

    valid = isfinite(T) & isfinite(R);
    T = T(valid);
    R = R(valid);

    if isempty(T) || isempty(R)
        warning('Skipping experimental field %s for %s because it is not numeric.', ...
            rName, expData.device);
        continue;
    end

    if doNormalize
        [T, R, ~] = normalize_rt_curve(T, R);
    end

    cIdx = min(kr, size(colors,1));
    plot(T, R, 'o', 'MarkerSize', 4, 'LineWidth', 1.0, ...
        'Color', colors(cIdx,:), ...
        'DisplayName', sprintf('exp %s', strrep(rName, '_', '\_')));
end

end

function y = local_numeric_vector(x)

if istable(x)
    x = table2array(x);
end

if isnumeric(x) || islogical(x)
    y = double(x);
elseif iscell(x)
    if all(cellfun(@(c) isnumeric(c) && isscalar(c), x(:)))
        y = cellfun(@double, x);
    else
        y = str2double(x);
    end
elseif ischar(x)
    y = str2double(cellstr(x));
elseif isstring(x)
    y = str2double(cellstr(x));
elseif iscategorical(x)
    y = str2double(cellstr(x));
else
    try
        y = double(x);
    catch
        y = str2double(cellstr(x));
    end
end

y = y(:);

end
