function h = plot_raman_registration_device_summary(device, registered, registration)
%PLOT_RAMAN_REGISTRATION_DEVICE_SUMMARY Thesis-friendly per-device Raman figure.
%
% The figure separates the measured line-scan constraints from interpolation
% and interpolation support. This keeps the visual message honest: the Raman
% data are sparse registered constraints, not a dense measured 2D strain map.

device = string(device);
spec = make_device_spec(device);
net = build_hallbar_network(spec);
model = make_shared_model_params();
net = apply_mechanical_proxy(net, spec, model);

T = registered(registered.device == device & ...
    registered.registration_status == "registered", :);
regRows = registration(registration.device == device, :);

opts = struct('valueColumn', 'abs_shift_proxy', ...
    'sigma_um', 0.85, 'minCoverageNorm', 0.08);
ramanMap = build_raman_proxy_map(net, registered, device, opts);

h = figure('Name', sprintf('%s Raman registration summary', device), ...
    'Color', 'w', 'Position', [80 80 1220 900]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_geometry_background(net, spec, true);
plot_scan_lines(regRows, true);
title('(a) Hall-bar registration');

nexttile;
plot_geometry_background(net, spec, false);
plot_signed_points(T);
title('(b) Signed Raman line-scan constraints');

nexttile;
plot_supported_proxy(net, spec, ramanMap);
plot_scan_lines(regRows, false);
title('(c) Support-masked |Raman proxy|');

nexttile;
plot_support_map(net, spec, ramanMap);
plot_scan_lines(regRows, false);
title('(d) Interpolation support');

sgtitle(sprintf('%s Raman registration on simplified Hall-bar geometry, %s', ...
    device, spec.filmForceLabel), 'Interpreter', 'none');
set(h, 'Color', 'w');

end

function plot_geometry_background(net, spec, showProbeLabels)

cla;
hold on;
axis image;
set(gca, 'YDir', 'normal');
xlim([min(net.x_um), max(net.x_um)]);
ylim([min(net.y_um), max(net.y_um)]);

hPatch = patch([min(net.x_um), max(net.x_um), max(net.x_um), min(net.x_um)], ...
    [min(net.y_um), min(net.y_um), max(net.y_um), max(net.y_um)], ...
    [0.97 0.97 0.97], 'EdgeColor', [0.35 0.35 0.35], ...
    'LineWidth', 0.9);
set(hPatch, 'HandleVisibility', 'off');

overlay_mask(net.x_um, net.y_um, net.coveredMask, [0.25 0.50 0.95], 0.13);
overlay_mask(net.x_um, net.y_um, net.boundaryMask, [1.00 0.72 0.12], 0.24);
overlay_mask(net.x_um, net.y_um, net.crackMask, [1.00 0.00 0.00], 0.35);
overlay_mask(net.x_um, net.y_um, net.sourceMask, [0.00 0.62 0.18], 0.20);
overlay_mask(net.x_um, net.y_um, net.drainMask, [0.00 0.62 0.18], 0.20);

if showProbeLabels
    probeNames = fieldnames(net.probeMasks);
    for kp = 1:numel(probeNames)
        pName = probeNames{kp};
        mask = net.probeMasks.(pName);
        [yy, xx] = find(mask);
        if ~isempty(xx)
            text(mean(net.x_um(xx)), mean(net.y_um(yy)), pName, ...
                'Color','k', 'FontWeight','bold', 'FontSize', 9, ...
                'HorizontalAlignment','center', ...
                'BackgroundColor','w', 'Margin',1);
        end
    end
end

xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

end

function plot_scan_lines(regRows, includeLegend)

if isempty(regRows)
    return;
end

colors = lines(height(regRows));
hold on;
hScans = gobjects(height(regRows), 1);
for k = 1:height(regRows)
    hScans(k) = plot([regRows.x0_um(k), regRows.x1_um(k)], ...
        [regRows.y0_um(k), regRows.y1_um(k)], ...
        '-', 'Color', colors(k,:), 'LineWidth', 2.1, ...
        'DisplayName', char(regRows.scan_id(k)));
    plot(regRows.x0_um(k), regRows.y0_um(k), 'o', ...
        'MarkerFaceColor', [0.0 0.55 0.15], ...
        'MarkerEdgeColor', 'k', 'MarkerSize', 5, ...
        'HandleVisibility', 'off');
    plot(regRows.x1_um(k), regRows.y1_um(k), 's', ...
        'MarkerFaceColor', [0.85 0.1 0.1], ...
        'MarkerEdgeColor', 'k', 'MarkerSize', 5, ...
        'HandleVisibility', 'off');
end

if includeLegend
    hCovered = plot(nan, nan, 's', 'MarkerFaceColor', [0.25 0.50 0.95], ...
        'MarkerEdgeColor', 'none', 'MarkerSize', 7, 'DisplayName', 'covered/stressor');
    hBoundary = plot(nan, nan, 's', 'MarkerFaceColor', [1.00 0.72 0.12], ...
        'MarkerEdgeColor', 'none', 'MarkerSize', 7, 'DisplayName', 'boundary');
    hCrack = plot(nan, nan, 's', 'MarkerFaceColor', [1.00 0.00 0.00], ...
        'MarkerEdgeColor', 'none', 'MarkerSize', 7, 'DisplayName', 'crack');
    hStart = plot(nan, nan, 'o', 'MarkerFaceColor', [0.0 0.55 0.15], ...
        'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'DisplayName', 'scan start');
    hEnd = plot(nan, nan, 's', 'MarkerFaceColor', [0.85 0.1 0.1], ...
        'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'DisplayName', 'scan end');
    lgd = legend([hScans; hStart; hEnd; hCovered; hBoundary; hCrack], ...
        'Location', 'southoutside', ...
        'NumColumns', min(4, height(regRows) + 5), 'Interpreter', 'none');
    apply_light_legend_style(lgd);
end

end

function plot_signed_points(T)

modes = unique(T.mode, 'stable');
markers = {'o','s','^','d','v','>'};
hold on;
vals = T.signed_shift_proxy;
for km = 1:numel(modes)
    idx = T.mode == modes(km);
    marker = markers{1 + mod(km-1, numel(markers))};
    scatter(T.x_um(idx), T.y_um(idx), 32, vals(idx), ...
        marker, 'filled', 'MarkerEdgeColor', [0.15 0.15 0.15], ...
        'DisplayName', char(modes(km)));
end
colormap(gca, redblue_colormap(256));
caxis([-1 1]);
cb = colorbar;
cb.Label.String = 'signed Raman-shift proxy';
cb.Label.FontSize = 9;
lgd = legend('Location', 'southoutside', 'NumColumns', max(1, numel(modes)), ...
    'Interpreter', 'none');
apply_light_legend_style(lgd);

end

function plot_supported_proxy(net, spec, ramanMap)

plot_geometry_background(net, spec, false);
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
cb.Label.FontSize = 9;

end

function plot_support_map(net, spec, ramanMap)

plot_geometry_background(net, spec, false);
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
cb.Label.String = 'relative interpolation support';
cb.Label.FontSize = 9;

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
