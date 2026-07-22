function h = plot_v741_weaklink_diagnostics(spec, net, weak, params)
%PLOT_V741_WEAKLINK_DIAGNOSTICS Visualize selected weak-link bottlenecks.

h = figure('Name', 'v7.4.1 weak-link bottleneck diagnostics', ...
    'Color', 'w', 'Position', [80 80 1300 760]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_node_map(net, net.etaNode, 'PDE/Raman network proxy \eta', 'network proxy \eta [0--1]');
draw_device_overlays(spec, net);

nexttile;
plot_node_map(net, weak.nodeMap, 'selected weak-link incidence', 'weak-link incidence [0--1]');
draw_device_overlays(spec, net);

nexttile;
plot_link_midpoint_scatter(net, weak.scoreX, weak.scoreY, ...
    'weak-link selection score', 'selection score [arb.]');
draw_device_overlays(spec, net);

nexttile;
plot_link_midpoint_scatter(net, params.IcX, params.IcY, ...
    'post-weak-link I_c map', 'I_c [A]');
draw_device_overlays(spec, net);

nexttile;
plot_link_midpoint_scatter(net, params.dI_fracX, params.dI_fracY, ...
    'current-switching width', '\Delta I / I_c');
draw_device_overlays(spec, net);

nexttile;
axis off;
text(0.02, 0.92, 'v7.4.1 weak-link layer', 'FontWeight', 'bold', ...
    'Units', 'normalized');
text(0.02, 0.78, sprintf('device: %s', spec.name), 'Units', 'normalized');
text(0.02, 0.66, sprintf('film force: %s', spec.filmForceLabel), ...
    'Units', 'normalized');
text(0.02, 0.54, sprintf('active weak-link fraction: %.3f', ...
    weak.activeLinkFraction), 'Units', 'normalized');
if isfield(params, 'weakLinkMaskX')
    weakIc = [params.IcX(params.weakLinkMaskX & net.link.activeX); ...
        params.IcY(params.weakLinkMaskY & net.link.activeY)];
    allIc = [params.IcX(net.link.activeX); params.IcY(net.link.activeY)];
    text(0.02, 0.42, sprintf('median weak I_c: %.3g A', ...
        median(weakIc, 'omitnan')), 'Units', 'normalized');
    text(0.02, 0.30, sprintf('median all-link I_c: %.3g A', ...
        median(allIc, 'omitnan')), 'Units', 'normalized');
end
text(0.02, 0.14, ['Interpretation: bright weak-link regions are coarse ', ...
    'Josephson-like bottlenecks with lower I_c and sharper current switching.'], ...
    'Units', 'normalized');

sgtitle(sprintf('v7.4.1 %s weak-link / Josephson-like bottleneck diagnostic', ...
    spec.name), 'FontWeight', 'bold');

end

function plot_node_map(net, Z, titleText, cbarText)

imagesc(net.x_um, net.y_um, Z);
set(gca, 'YDir', 'normal');
axis image;
xlabel('x [\mum]');
ylabel('y [\mum]');
title(titleText);
cb = colorbar;
ylabel(cb, cbarText);
apply_light_figure_style(gca);

end

function plot_link_midpoint_scatter(net, ZX, ZY, titleText, cbarText)

[midXx, midYx, midXy, midYy] = link_midpoints(net);
hold on;
scatter(midXx(net.link.activeX), midYx(net.link.activeX), 22, ...
    ZX(net.link.activeX), 's', 'filled');
scatter(midXy(net.link.activeY), midYy(net.link.activeY), 22, ...
    ZY(net.link.activeY), 'o', 'filled');
axis image;
xlabel('x [\mum]');
ylabel('y [\mum]');
title(titleText);
cb = colorbar;
ylabel(cb, cbarText);
apply_light_figure_style(gca);

end

function [midXx, midYx, midXy, midYy] = link_midpoints(net)

[X, Y] = meshgrid(net.x_um, net.y_um);
midXx = 0.5 .* (X(:,1:end-1) + X(:,2:end));
midYx = 0.5 .* (Y(:,1:end-1) + Y(:,2:end));
midXy = 0.5 .* (X(1:end-1,:) + X(2:end,:));
midYy = 0.5 .* (Y(1:end-1,:) + Y(2:end,:));

end

function draw_device_overlays(spec, net)

hold on;
if isfield(spec, 'boundaryY_um')
    yline(spec.boundaryY_um, '-', 'Color', [1 0.65 0], 'LineWidth', 1.3);
end
if isfield(spec, 'contact') && isfield(spec.contact, 'sourceX_um')
    xline(spec.contact.sourceX_um, '-', 'Color', [0.2 0.75 0.25], 'LineWidth', 1.0);
end
if isfield(spec, 'contact') && isfield(spec.contact, 'drainX_um')
    xline(spec.contact.drainX_um, '-', 'Color', [0.2 0.75 0.25], 'LineWidth', 1.0);
end
if isfield(spec, 'crack') && isfield(spec.crack, 'enabled') && spec.crack.enabled
    plot(spec.crack.x_um, spec.crack.y_um, 'r-', 'LineWidth', 1.4);
end
xlim([min(net.x_um) max(net.x_um)]);
ylim([min(net.y_um) max(net.y_um)]);

end
