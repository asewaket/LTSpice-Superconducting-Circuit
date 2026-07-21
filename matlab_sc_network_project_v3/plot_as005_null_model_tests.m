function h = plot_as005_null_model_tests(suite)
%PLOT_AS005_NULL_MODEL_TESTS Chapter-style AS005 null/dimensionality tests.

if nargin < 1 || isempty(suite)
    suite = run_as005_null_model_suite();
end

spec = suite.spec;
modes = suite.modes;

labels = struct();
labels.full = 'full 2D';
labels.central_lane = 'central-lane 1D-like';
labels.uniform = 'uniform-\eta';
labels.random_eta = 'randomized-\eta';
labels.crack_off = 'crack-off';

colors = struct();
colors.full = [0.0000 0.4470 0.7410];
colors.central_lane = [0.8500 0.3250 0.0980];
colors.uniform = [0.4660 0.6740 0.1880];
colors.random_eta = [0.4940 0.1840 0.5560];
colors.crack_off = [0.6350 0.0780 0.1840];

h = figure('Color','w', 'Name', 'AS005 geometry and null-model tests');
set(h, 'Units','inches', 'Position', [0.8 0.8 10.8 7.2]);

% Panel (a): normalized R(T) curves.
axMain = subplot(2,3,1);
hold(axMain, 'on');

for km = 1:numel(modes)
    mode = modes{km};
    result = suite.cases.(mode).result;
    [T, Rnorm] = normalize_rt_curve(result.T, result.R4p.top_4_10);
    plot(axMain, T, Rnorm, 'LineWidth', 2.0, ...
        'Color', colors.(mode), ...
        'DisplayName', labels.(mode));
end

xlabel(axMain, 'Temperature T [K]');
ylabel(axMain, 'R(T)/R_N');
title(axMain, '(a) normalized R(T)', 'FontWeight','bold');
xlim(axMain, [0 2.2]);
ylim(axMain, [0 1.08]);
apply_light_figure_style(axMain);
lgd = legend(axMain, 'Location','southwest');
apply_light_legend_style(lgd);

panelLetters = {'(b)','(c)','(d)','(e)','(f)'};
for km = 1:numel(modes)
    mode = modes{km};
    ax = subplot(2,3,km+1);
    plot_network_representation(ax, suite.cases.(mode).net, mode, ...
        sprintf('%s %s', panelLetters{km}, labels.(mode)));
end

try
    sgtitle(sprintf('AS005 geometry, dimensionality, and null-model tests, %s', ...
        spec.filmForceLabel), 'Color','k', 'FontWeight','bold');
catch
    annotation(h, 'textbox', [0.18 0.955 0.64 0.04], ...
        'String', sprintf('AS005 geometry, dimensionality, and null-model tests, %s', ...
        spec.filmForceLabel), ...
        'EdgeColor','none', 'HorizontalAlignment','center', ...
        'FontWeight','bold', 'Color','k');
end

end

function plot_network_representation(ax, net, mode, titleText)

axes(ax); %#ok<LAXES>
hold(ax, 'on');

eta = net.etaNode;
eta(~net.active) = NaN;
imagesc(ax, net.x_um, net.y_um, eta);
set(ax, 'YDir','normal');
axis(ax, 'image');
axis(ax, 'tight');
colormap(ax, parula);
caxis(ax, [0 1]);

% Draw active links as a light network overlay.
[Ny, Nx] = size(net.active);
for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            plot(ax, net.x_um([col col+1]), net.y_um([row row]), ...
                '-', 'Color', [0.70 0.70 0.70], 'LineWidth', 0.5);
        end
    end
end
for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            plot(ax, net.x_um([col col]), net.y_um([row row+1]), ...
                '-', 'Color', [0.78 0.78 0.78], 'LineWidth', 0.4);
        end
    end
end

% Source/drain/probe markers.
plot_mask_centroid(ax, net.sourceMask & net.active, net, 's', [0.1 0.6 0.1], 'S');
plot_mask_centroid(ax, net.drainMask & net.active, net, 's', [0.1 0.6 0.1], 'D');
plot_probe_labels(ax, net);

title(ax, titleText, 'FontWeight','bold');
xlabel(ax, 'x [\mum]');
ylabel(ax, 'y [\mum]');
apply_light_figure_style(ax);

if strcmp(mode, 'central_lane')
    text(ax, 0.02, 0.08, 'transverse links removed', ...
        'Units','normalized', 'Color','k', 'BackgroundColor','w', ...
        'FontSize', 8);
elseif strcmp(mode, 'crack_off')
    text(ax, 0.02, 0.08, 'crack enhancement removed', ...
        'Units','normalized', 'Color','k', 'BackgroundColor','w', ...
        'FontSize', 8);
elseif strcmp(mode, 'uniform')
    text(ax, 0.02, 0.08, 'spatial proxy uniform', ...
        'Units','normalized', 'Color','k', 'BackgroundColor','w', ...
        'FontSize', 8);
elseif strcmp(mode, 'random_eta')
    text(ax, 0.02, 0.08, 'proxy values shuffled', ...
        'Units','normalized', 'Color','k', 'BackgroundColor','w', ...
        'FontSize', 8);
end

end

function plot_mask_centroid(ax, mask, net, marker, color, labelText)

[rr, cc] = find(mask);
if isempty(rr)
    return;
end

x = mean(net.x_um(cc));
y = mean(net.y_um(rr));
plot(ax, x, y, marker, 'MarkerSize', 7, ...
    'MarkerFaceColor', color, 'MarkerEdgeColor', 'k');
text(ax, x, y, labelText, 'Color','w', 'FontWeight','bold', ...
    'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
    'FontSize', 7);

end

function plot_probe_labels(ax, net)

probeNames = fieldnames(net.probeMasks);
for kp = 1:numel(probeNames)
    pName = probeNames{kp};
    mask = net.probeMasks.(pName) & net.active;
    [rr, cc] = find(mask);
    if isempty(rr)
        continue;
    end
    x = mean(net.x_um(cc));
    y = mean(net.y_um(rr));
    plot(ax, x, y, 'o', 'MarkerSize', 4, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor','k');
    text(ax, x, y, erase(pName,'P'), 'Color','k', ...
        'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
        'FontSize', 7, 'FontWeight','bold');
end

end
