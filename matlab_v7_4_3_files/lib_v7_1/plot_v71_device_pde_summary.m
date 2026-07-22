function h = plot_v71_device_pde_summary(spec, netPDE, pde, pdeMap, result, expData, scoreInfo)
%PLOT_V71_DEVICE_PDE_SUMMARY Thesis-facing PDE scaffold diagnostic.

h = figure('Name', sprintf('v7.1 %s PDE-informed scaffold', spec.name), ...
    'Color', 'w', 'Position', [60 60 1320 850]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_geometry_masks(netPDE, spec);
title('geometry, contacts, stressor');

nexttile;
pdemesh(pde.model);
axis equal tight;
title('PDE finite-element mesh');
xlabel('x [\mum]');
ylabel('y [\mum]');
apply_light_figure_style(gca);

nexttile;
imagesc(netPDE.x_um, netPDE.y_um, hypot(pdeMap.Ux, pdeMap.Uy));
set(gca, 'YDir', 'normal');
axis image tight;
cb = colorbar;
ylabel(cb, 'relative displacement magnitude [arb.]');
title('PDE displacement magnitude');
xlabel('x [\mum]');
ylabel('y [\mum]');
hold on; draw_device_overlays(netPDE, spec);
apply_light_figure_style(gca);

nexttile;
imagesc(netPDE.x_um, netPDE.y_um, pdeMap.contactRelaxationMask);
set(gca, 'YDir', 'normal');
axis image tight;
caxis([0 1]);
cb = colorbar;
ylabel(cb, 'contact-relaxation mask [0--1]');
title('metal-contact relaxation mask');
xlabel('x [\mum]');
ylabel('y [\mum]');
hold on; draw_device_overlays(netPDE, spec);
apply_light_figure_style(gca);

nexttile;
imagesc(netPDE.x_um, netPDE.y_um, pdeMap.etaNode);
set(gca, 'YDir', 'normal');
axis image tight;
caxis([0 1]);
cb = colorbar;
ylabel(cb, 'network proxy \eta [0--1]');
title('PDE-informed network proxy \eta');
xlabel('x [\mum]');
ylabel('y [\mum]');
hold on; draw_device_overlays(netPDE, spec);
apply_light_figure_style(gca);

nexttile;
plot_rt_comparison(spec, result, expData, scoreInfo);

sgtitle(sprintf('v7.1 %s PDE-informed scaffold: %s', ...
    spec.name, spec.filmForceLabel), 'FontWeight', 'bold');

end

function plot_geometry_masks(net, spec)

imagesc(net.x_um, net.y_um, double(net.coveredMask));
set(gca, 'YDir', 'normal');
axis image tight;
colormap(gca, parula);
caxis([0 1]);
hold on;

overlay_mask(net, net.boundaryMask, [1.0 0.65 0.0], 0.45);
overlay_mask(net, net.sourceMask | net.drainMask, [0.1 0.65 0.25], 0.50);
if isfield(net, 'nominalSourceMask') && isfield(net, 'nominalDrainMask')
    overlay_mask(net, (net.nominalSourceMask | net.nominalDrainMask) & ~net.active, ...
        [0.1 0.65 0.25], 0.20);
end

probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    mask = net.probeMasks.(probeNames{k});
    overlay_mask(net, mask, [0.85 0.05 0.10], 0.85);
    [yy, xx] = find(mask);
    if ~isempty(xx)
        text(mean(net.x_um(xx)), mean(net.y_um(yy)), probeNames{k}, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
            'Color', 'w', 'FontSize', 8);
    end
end

draw_device_overlays(net, spec);
xlabel('x [\mum]');
ylabel('y [\mum]');
add_probe_overlap_note(net);
apply_light_figure_style(gca);

end

function plot_rt_comparison(spec, result, expData, scoreInfo)

hold on;
if expData.available && isfield(expData.R, 'main_4p')
    [Texp, RexpNorm] = normalize_rt_curve(expData.T, expData.R.main_4p);
    plot(Texp, RexpNorm, 'ko', 'MarkerSize', 4, ...
        'DisplayName', sprintf('experiment main (%s)', prettify_pair(expData.modelPair)));
end

pairs = {'top_4_10','bottom_3_9'};
pairColors = [0.00 0.45 0.74; 0.85 0.33 0.10];
for k = 1:numel(pairs)
    pairName = pairs{k};
    if isfield(result.R4p, pairName)
        [Tmod, RmodNorm] = normalize_rt_curve(result.T, result.R4p.(pairName));
        plot(Tmod, RmodNorm, '-', 'LineWidth', 2.4, ...
            'Color', pairColors(k,:), ...
            'DisplayName', sprintf('model %s', prettify_pair(pairName)));
    end

    [Tp, Rp] = experimental_pair_curve_v71(expData, pairName);
    if ~isempty(Tp) && ~isempty(Rp)
        [Tp, RpNorm] = normalize_rt_curve(Tp, Rp);
        plot(Tp, RpNorm, '.', 'MarkerSize', 9, ...
            'Color', pairColors(k,:), ...
            'DisplayName', sprintf('raw exp %s', prettify_pair(pairName)));
    else
        plot(NaN, NaN, '.', 'MarkerSize', 9, ...
            'Color', pairColors(k,:), ...
            'DisplayName', sprintf('raw exp %s unavailable', prettify_pair(pairName)));
    end
end

pairNote = experimental_pair_availability_note(expData);
if ~isempty(pairNote)
    text(0.03, 0.05, pairNote, ...
        'Units', 'normalized', 'FontSize', 7.5, ...
        'Color', [0.18 0.18 0.18], 'BackgroundColor', [1 1 1], ...
        'Margin', 2, 'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none');
end

xlabel('Temperature T [K]');
ylabel('R/R_N');
ylim([0 1.15]);
title(sprintf('%s normalized R(T), selected score %.3g', ...
    spec.name, scoreInfo.combinedScore));
grid on; box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end

function [T, R] = experimental_pair_curve_v71(expData, pairName)

T = [];
R = [];

if isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available && isfield(expData.pairData.R, pairName)
    T = expData.pairData.T;
    R = expData.pairData.R.(pairName);
end

end

function label = prettify_pair(pairName)

label = strrep(pairName, 'top_4_10', 'top 4-10');
label = strrep(label, 'bottom_3_9', 'bottom 3-9');
label = strrep(label, '_', ' ');

end

function note = experimental_pair_availability_note(expData)

note = '';
if ~(isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available)
    note = 'no experimental pair file loaded';
    return;
end

fields = fieldnames(expData.pairData.R);
hasTop = isfield(expData.pairData.R, 'top_4_10');
hasBottom = isfield(expData.pairData.R, 'bottom_3_9');
if hasTop && hasBottom
    return;
end

if isempty(fields)
    channelText = 'none';
else
    channelText = strjoin(fields, ', ');
end
note = sprintf('pair-data incomplete: available exp channels = %s', channelText);

end

function overlay_mask(net, mask, color, alphaVal)

if ~any(mask(:))
    return;
end
rgb = zeros([size(mask), 3]);
for k = 1:3
    rgb(:,:,k) = color(k);
end
hImg = image(net.x_um, net.y_um, rgb);
set(hImg, 'AlphaData', alphaVal * double(mask));

end

function draw_device_overlays(net, spec)

if isfield(net, 'nominalSourceMask') && isfield(net, 'nominalDrainMask')
    safe_mask_contour(net, net.nominalSourceMask | net.nominalDrainMask, ...
        [0.35 0.35 0.35], 0.75, '--');
end
if isfield(net, 'nominalProbeMasks')
    probeNames = fieldnames(net.nominalProbeMasks);
    for k = 1:numel(probeNames)
        safe_mask_contour(net, net.nominalProbeMasks.(probeNames{k}), ...
            [0.45 0.45 0.45], 0.75, '--');
    end
end

safe_mask_contour(net, net.active, [0.1 0.1 0.1], 0.8, '-');
safe_mask_contour(net, net.coveredMask, [0.1 0.35 0.8], 0.8, '-');
safe_mask_contour(net, net.boundaryMask, [0.95 0.55 0.0], 1.0, '-');
safe_mask_contour(net, net.sourceMask | net.drainMask, [0.1 0.55 0.2], 1.0, '-');

probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    safe_mask_contour(net, net.probeMasks.(probeNames{k}), [0.85 0.05 0.10], 1.1, '-');
end

if strcmp(spec.geometryClass, 'cracked_full')
    safe_mask_contour(net, net.crackMask, [0.9 0.0 0.0], 1.0, '-');
end

end

function safe_mask_contour(net, mask, color, lineWidth, lineStyle)

if nargin < 5 || isempty(lineStyle)
    lineStyle = '-';
end

z = double(mask);
if any(z(:) == 0) && any(z(:) == 1)
    contour(net.x_um, net.y_um, z, [0.5 0.5], ...
        'Color', color, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
end

end

function add_probe_overlap_note(net)

if ~isfield(net, 'probeOverlap')
    return;
end

probeNames = fieldnames(net.probeOverlap);
parts = cell(1, numel(probeNames));
for k = 1:numel(probeNames)
    name = probeNames{k};
    S = net.probeOverlap.(name);
    parts{k} = sprintf('%s %.0f%%', name, 100 * S.activeFraction);
end

text(0.02, 0.03, ['active probe overlap: ' strjoin(parts, ', ')], ...
    'Units', 'normalized', 'FontSize', 7, 'Color', [0.1 0.1 0.1], ...
    'BackgroundColor', [1 1 1], 'Margin', 2, ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');

end
