function h = plot_raman_registration_overlays(devices, registered, registration)
%PLOT_RAMAN_REGISTRATION_OVERLAYS Show Raman scans on Hall-bar geometry.

if nargin < 1 || isempty(devices)
    devices = unique(registered.device, 'stable');
end
if ischar(devices) || isstring(devices)
    devices = string(devices);
end

nDev = numel(devices);
h = figure('Name', 'Raman scan registration overlays', 'Color', 'w', ...
    'Position', [60 60 1750 360 * nDev]);
tiledlayout(nDev, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    device = string(devices(d));
    spec = make_device_spec(device);
    net = build_hallbar_network(spec);
    model = make_shared_model_params();
    net = apply_mechanical_proxy(net, spec, model);
    T = registered(registered.device == device & ...
        registered.registration_status == "registered", :);

    nexttile;
    plot_geometry_panel(net, spec);
    title(sprintf('%s geometry + Raman paths', device));
    overlay_scan_paths(registration(registration.device == device, :), T, true, false);

    nexttile;
    plot_registered_points(net, T, 'signed_shift_proxy');
    title(sprintf('%s signed Raman line constraints', device));

    nexttile;
    opts = struct('valueColumn', 'abs_shift_proxy', ...
        'sigma_um', 0.85, 'minCoverageNorm', 0.08);
    ramanMap = build_raman_proxy_map(net, registered, device, opts);
    plot_interpolated_proxy(net, spec, ramanMap);
    overlay_scan_paths(registration(registration.device == device, :), T, false, false);
    title(sprintf('%s supported |Raman proxy|', device));

    nexttile;
    plot_coverage_map(net, spec, ramanMap);
    overlay_scan_paths(registration(registration.device == device, :), T, false, false);
    title(sprintf('%s interpolation support', device));
end

sgtitle('Registered Raman line-scan constraints on simplified Hall-bar coordinates');
set(h, 'Color', 'w');

end

function plot_geometry_panel(net, spec)

imagesc(net.x_um, net.y_um, double(net.active));
set(gca, 'YDir', 'normal');
axis image tight;
hold on;
colormap(gca, gray);
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

overlay_mask(net.x_um, net.y_um, net.coveredMask, [0.2 0.5 1.0], 0.18);
overlay_mask(net.x_um, net.y_um, net.boundaryMask, [1.0 0.7 0.1], 0.35);
overlay_mask(net.x_um, net.y_um, net.crackMask, [1.0 0.0 0.0], 0.50);
overlay_mask(net.x_um, net.y_um, net.sourceMask, [0.0 0.65 0.15], 0.35);
overlay_mask(net.x_um, net.y_um, net.drainMask, [0.0 0.65 0.15], 0.35);

probeNames = fieldnames(net.probeMasks);
for kp = 1:numel(probeNames)
    pName = probeNames{kp};
    mask = net.probeMasks.(pName);
    [yy, xx] = find(mask);
    if ~isempty(xx)
        text(mean(net.x_um(xx)), mean(net.y_um(yy)), pName, ...
            'Color','k', 'FontWeight','bold', 'HorizontalAlignment','center', ...
            'BackgroundColor','w', 'Margin',1);
    end
end

end

function plot_registered_points(net, T, valueColumn)

plot_empty_geometry_background(net);

modes = unique(T.mode, 'stable');
markers = {'o','s','^','d','v','>'};
vals = T.(valueColumn);
for km = 1:numel(modes)
    idx = T.mode == modes(km);
    marker = markers{1 + mod(km-1, numel(markers))};
    scatter(T.x_um(idx), T.y_um(idx), 34, vals(idx), ...
        marker, 'filled', ...
        'MarkerEdgeColor', [0.15 0.15 0.15], ...
        'DisplayName', char(modes(km)));
end
cb = colorbar;
cb.Label.String = strrep(valueColumn, '_', ' ');
caxis([-1 1]);
colormap(gca, redblue_colormap(256));
lgd = legend('Location', 'southoutside', 'NumColumns', max(1, numel(modes)), ...
    'Interpreter', 'none');
apply_light_legend_style(lgd);

end

function plot_interpolated_proxy(net, spec, ramanMap)

plot_empty_geometry_background(net, spec);
hold on;
hImg = imagesc(net.x_um, net.y_um, ramanMap.nodeMapDisplay);
set(gca, 'YDir', 'normal');
axis image tight;
alphaData = zeros(size(ramanMap.nodeMapDisplay));
finiteMask = isfinite(ramanMap.nodeMapDisplay);
alphaData(finiteMask) = 0.25 + 0.70 * ramanMap.coverageNorm(finiteMask);
alphaData(~isfinite(alphaData)) = 0;
set(hImg, 'AlphaData', alphaData, 'HandleVisibility', 'off');
colormap(gca, parula(256));
caxis([0 1]);
cb = colorbar;
cb.Label.String = 'normalized |Raman proxy|';
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

end

function plot_coverage_map(net, spec, ramanMap)

plot_empty_geometry_background(net, spec);
hold on;
hImg = imagesc(net.x_um, net.y_um, ramanMap.coverageNorm);
set(gca, 'YDir', 'normal');
axis image tight;
alphaData = double(isfinite(ramanMap.coverageNorm) & ramanMap.coverageNorm > 0);
alphaData = 0.15 + 0.75 * alphaData .* ramanMap.coverageNorm;
alphaData(~isfinite(alphaData)) = 0;
set(hImg, 'AlphaData', alphaData, 'HandleVisibility', 'off');
colormap(gca, hot(256));
caxis([0 1]);
cb = colorbar;
cb.Label.String = 'relative support';
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

end

function plot_empty_geometry_background(net, spec)

if nargin < 2
    spec = struct();
end

cla;
hold on;
axis image;
set(gca, 'YDir', 'normal');
xlim([min(net.x_um), max(net.x_um)]);
ylim([min(net.y_um), max(net.y_um)]);
hPatch = patch([min(net.x_um), max(net.x_um), max(net.x_um), min(net.x_um)], ...
    [min(net.y_um), min(net.y_um), max(net.y_um), max(net.y_um)], ...
    [0.96 0.96 0.96], 'EdgeColor', [0.35 0.35 0.35], ...
    'LineWidth', 0.9);
set(hPatch, 'HandleVisibility', 'off');
if nargin >= 2 && isfield(spec, 'geometryClass')
    overlay_mask(net.x_um, net.y_um, net.coveredMask, [0.2 0.5 1.0], 0.10);
    overlay_mask(net.x_um, net.y_um, net.boundaryMask, [1.0 0.7 0.1], 0.18);
    overlay_mask(net.x_um, net.y_um, net.crackMask, [1.0 0.0 0.0], 0.25);
end
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

end

function overlay_scan_paths(regRows, T, labelScans, showPoints)

if nargin < 3
    labelScans = true;
end
if nargin < 4
    showPoints = true;
end

scanRows = regRows;
for k = 1:height(scanRows)
    plot([scanRows.x0_um(k), scanRows.x1_um(k)], ...
        [scanRows.y0_um(k), scanRows.y1_um(k)], ...
        '-', 'Color', [0.05 0.05 0.05], 'LineWidth', 2.0);
    plot(scanRows.x0_um(k), scanRows.y0_um(k), 'o', ...
        'MarkerFaceColor', [0.1 0.6 0.1], 'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);
    plot(scanRows.x1_um(k), scanRows.y1_um(k), 's', ...
        'MarkerFaceColor', [0.8 0.1 0.1], 'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);
    if labelScans
        text(scanRows.x0_um(k), scanRows.y0_um(k), " " + scanRows.scan_id(k), ...
            'Color', 'k', 'BackgroundColor', 'w', 'Margin', 1, ...
            'Interpreter', 'none');
    end
end

if showPoints && nargin >= 2 && ~isempty(T)
    scatter(T.x_um, T.y_um, 12, T.abs_shift_proxy, 'filled', ...
        'MarkerEdgeColor', 'none');
end

end

function overlay_mask(x, y, mask, color, alphaVal)

if ~any(mask(:))
    return;
end

rgb = zeros([size(mask), 3]);
for c = 1:3
    rgb(:,:,c) = color(c);
end

hImg = image(x, y, rgb);
set(hImg, 'AlphaData', alphaVal * double(mask), 'HandleVisibility', 'off');

end

function cmap = redblue_colormap(n)

if nargin < 1
    n = 256;
end
n1 = floor(n/2);
n2 = n - n1;
blue = [linspace(0.1, 1, n1)', linspace(0.25, 1, n1)', ones(n1,1)];
red = [ones(n2,1), linspace(1, 0.15, n2)', linspace(1, 0.1, n2)'];
cmap = [blue; red];

end
