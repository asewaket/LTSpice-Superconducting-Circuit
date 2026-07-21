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
    'Position', [80 80 1200 350 * nDev]);
tiledlayout(nDev, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

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
    overlay_scan_paths(registration(registration.device == device, :), T);

    nexttile;
    plot_registered_points(net, T, 'signed_shift_proxy');
    title(sprintf('%s signed Raman proxy', device));

    nexttile;
    opts = struct('valueColumn', 'abs_shift_proxy', 'sigma_um', 0.85);
    ramanMap = build_raman_proxy_map(net, registered, device, opts);
    imagesc(net.x_um, net.y_um, ramanMap.nodeMapNorm);
    set(gca, 'YDir', 'normal');
    axis image tight;
    hold on;
    overlay_scan_paths(registration(registration.device == device, :), T, false);
    xlabel('x [\mum]');
    ylabel('y [\mum]');
    title(sprintf('%s interpolated |Raman proxy|', device));
    cb = colorbar;
    cb.Label.String = 'normalized local proxy';
    apply_light_figure_style(gca);
end

sgtitle('Registered Raman line scans on simplified Hall-bar coordinates');
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

txt = sprintf('%s, %s', spec.geometryClass, spec.filmForceLabel);
text(min(net.x_um) + 0.2, max(net.y_um) - 0.25, txt, ...
    'Color', 'k', 'BackgroundColor', 'w', 'Margin', 1, ...
    'Interpreter', 'none');

end

function plot_registered_points(net, T, valueColumn)

imagesc(net.x_um, net.y_um, nan(size(net.active)));
set(gca, 'YDir', 'normal');
axis image tight;
hold on;
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

scatter(T.x_um, T.y_um, 35, T.(valueColumn), 'filled', ...
    'MarkerEdgeColor', [0.15 0.15 0.15]);
cb = colorbar;
cb.Label.String = strrep(valueColumn, '_', ' ');
caxis([-1 1]);
colormap(gca, redblue_colormap(256));

end

function overlay_scan_paths(regRows, T, labelScans)

if nargin < 3
    labelScans = true;
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

if nargin >= 2 && ~isempty(T)
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
set(hImg, 'AlphaData', alphaVal * double(mask));

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
