function h = plot_six_device_normalized_comparison(allResults)
%PLOT_SIX_DEVICE_NORMALIZED_COMPARISON Chapter-style 2x3 normalized R(T).
%
% The experimental curve and each simulated disorder realization are
% independently normalized by their own high-temperature resistance. The solid
% model line is the ensemble mean of normalized simulations, and the shaded
% region is one standard deviation.

if nargin < 1 || isempty(allResults)
    resultsFile = fullfile(fileparts(mfilename('fullpath')), ...
        'outputs', 'six_device_scaffold_results.mat');
    if ~exist(resultsFile, 'file')
        error(['No allResults input and no saved results file found. ', ...
            'Run run_six_device_scaffold first.']);
    end
    S = load(resultsFile, 'allResults');
    allResults = S.allResults;
end

deviceNames = {'AS001','AS002','AS003','AS004','AS005','AS006'};
panelLetters = {'(a)','(b)','(c)','(d)','(e)','(f)'};

h = figure('Color','w', 'Name', 'six-device normalized model-experiment comparison');
set(h, 'Units','inches', 'Position', [1 1 10.5 6.6]);

modelColor = [0.0000 0.4470 0.7410];
expColor = [0.10 0.10 0.10];

for kd = 1:numel(deviceNames)
    name = deviceNames{kd};
    idx = find(strcmp({allResults.name}, name), 1, 'first');
    if isempty(idx)
        warning('No result found for %s.', name);
        continue;
    end

    item = allResults(idx);
    spec = item.spec;
    ensemble = item.ensemble;
    expData = item.expData;

    ax = subplot(2,3,kd);
    hold(ax, 'on');

    modelPair = choose_model_pair(ensemble, expData);
    [Tmodel, muNorm, sigNorm] = normalized_ensemble_curve(ensemble, modelPair);

    fill(ax, [Tmodel fliplr(Tmodel)], ...
        [muNorm - sigNorm fliplr(muNorm + sigNorm)], ...
        modelColor, ...
        'FaceAlpha', 0.16, ...
        'EdgeColor', 'none', ...
        'DisplayName', 'model \pm 1\sigma');

    plot(ax, Tmodel, muNorm, '-', ...
        'LineWidth', 2.0, ...
        'Color', modelColor, ...
        'DisplayName', 'model mean');

    if expData.available
        [Texp, RexpNorm] = normalized_experiment_curve(expData);
        plot(ax, Texp, RexpNorm, 'o', ...
            'MarkerSize', 4.0, ...
            'LineWidth', 0.9, ...
            'Color', expColor, ...
            'MarkerFaceColor', 'w', ...
            'DisplayName', 'experiment');
    end

    title(ax, sprintf('%s %s, %s', panelLetters{kd}, spec.name, spec.filmForceLabel), ...
        'FontWeight','bold');
    xlabel(ax, 'Temperature T [K]');
    ylabel(ax, 'R(T)/R_N');
    xlim(ax, [0 2.2]);
    ylim(ax, [0 1.08]);
    apply_light_figure_style(ax);

    if kd == 1
        lgd = legend(ax, 'Location','southwest');
        apply_light_legend_style(lgd);
    end
end

try
    sgtitle('Normalized four-probe resistance: experiment and 2D MATLAB network model', ...
        'Color','k', 'FontWeight','bold');
catch
    annotation(h, 'textbox', [0.18 0.955 0.64 0.04], ...
        'String', 'Normalized four-probe resistance: experiment and 2D MATLAB network model', ...
        'EdgeColor','none', 'HorizontalAlignment','center', ...
        'FontWeight','bold', 'Color','k');
end

end

function modelPair = choose_model_pair(ensemble, expData)

pairNames = fieldnames(ensemble.R4pAll);
modelPair = pairNames{1};

if isfield(expData, 'modelPair') && isfield(ensemble.R4pAll, expData.modelPair)
    modelPair = expData.modelPair;
end

end

function [T, muNorm, sigNorm] = normalized_ensemble_curve(ensemble, pairName)

T = ensemble.T(:)';
Rall = ensemble.R4pAll.(pairName);

Rnorm = NaN(size(Rall));
for k = 1:size(Rall,1)
    [~, rn, ~] = normalize_rt_curve(T, Rall(k,:));
    Rnorm(k,:) = rn(:)';
end

muNorm = local_nanmean_dim(Rnorm, 1);
sigNorm = local_nanstd_dim(Rnorm, 1);

end

function [T, Rnorm] = normalized_experiment_curve(expData)

rNames = fieldnames(expData.R);
rName = rNames{1};

T = local_numeric_vector(expData.T);
R = local_numeric_vector(expData.R.(rName));

n = min(numel(T), numel(R));
T = T(1:n);
R = R(1:n);

valid = isfinite(T) & isfinite(R);
T = T(valid);
R = R(valid);

[T, Rnorm, ~] = normalize_rt_curve(T, R);

end

function m = local_nanmean_dim(x, dim)

mask = isfinite(x);
x0 = x;
x0(~mask) = 0;
count = sum(mask, dim);
m = sum(x0, dim) ./ count;
m(count == 0) = NaN;

end

function s = local_nanstd_dim(x, dim)

m = local_nanmean_dim(x, dim);
if dim == 1
    mRep = repmat(m, size(x,1), 1);
    count = sum(isfinite(x), 1);
elseif dim == 2
    mRep = repmat(m, 1, size(x,2));
    count = sum(isfinite(x), 2);
else
    error('Unsupported dimension.');
end

diff2 = (x - mRep).^2;
diff2(~isfinite(diff2)) = 0;
denom = max(count - 1, 1);
s = sqrt(sum(diff2, dim) ./ denom);
s(count <= 1) = 0;

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
