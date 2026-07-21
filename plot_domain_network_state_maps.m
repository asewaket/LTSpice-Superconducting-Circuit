function h = plot_domain_network_state_maps(bestRuns)
%PLOT_DOMAIN_NETWORK_STATE_MAPS Spatial maps for best v6.4 domain variants.

valid = arrayfun(@(s) isfield(s, 'run') && ~isempty(s.run), bestRuns);
bestRuns = bestRuns(valid);
nDev = numel(bestRuns);

h = figure('Name', 'v6.4 domain network state maps', 'Color', 'w', ...
    'Position', [80 80 1180 300*nDev]);
tiledlayout(nDev, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    run = bestRuns(d).run;
    net = run.net;
    Tlow = min(run.result.T);
    [Rx, Ry] = link_resistance_T(run.params, run.spec, Tlow);
    frac = 0.20;
    scX = net.link.activeX & isfinite(Rx) & run.params.RnX > 0 & (Rx ./ run.params.RnX) <= frac;
    scY = net.link.activeY & isfinite(Ry) & run.params.RnY > 0 & (Ry ./ run.params.RnY) <= frac;
    scNode = link_mask_to_node_mask_local(net, scX, scY);

    nexttile;
    imagesc(net.x_um, net.y_um, net.etaNode);
    set(gca, 'YDir', 'normal');
    axis image tight;
    colorbar;
    title(sprintf('%s hybrid proxy \\eta', run.device));
    xlabel('x [\mum]'); ylabel('y [\mum]');
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);

    nexttile;
    imagesc(net.x_um, net.y_um, double(run.domain.domainNode));
    set(gca, 'YDir', 'normal');
    axis image tight;
    caxis([0 1]);
    colorbar;
    title(sprintf('%s nucleated domains', run.domainVariant), 'Interpreter', 'none');
    xlabel('x [\mum]'); ylabel('y [\mum]');
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);

    nexttile;
    imagesc(net.x_um, net.y_um, double(scNode));
    set(gca, 'YDir', 'normal');
    axis image tight;
    caxis([0 1]);
    colorbar;
    title(sprintf('SC-like cluster map, T=%.2g K', Tlow));
    xlabel('x [\mum]'); ylabel('y [\mum]');
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);
end

end

function nodeMask = link_mask_to_node_mask_local(net, maskX, maskY)

nodeMask = false(size(net.active));
[Ny, Nx] = size(net.active);
for row = 1:Ny
    for col = 1:Nx-1
        if maskX(row,col)
            nodeMask(row,col) = true;
            nodeMask(row,col+1) = true;
        end
    end
end
for row = 1:Ny-1
    for col = 1:Nx
        if maskY(row,col)
            nodeMask(row,col) = true;
            nodeMask(row+1,col) = true;
        end
    end
end
nodeMask = nodeMask & net.active;

end

function draw_geometry_overlays(net, spec)

contour(net.x_um, net.y_um, double(net.coveredMask), [0.5 0.5], ...
    'Color', [0.1 0.5 0.1], 'LineWidth', 0.8);
contour(net.x_um, net.y_um, double(net.boundaryMask), [0.5 0.5], ...
    'Color', [0.9 0.6 0.1], 'LineWidth', 0.8);
if strcmp(spec.geometryClass, 'cracked_full')
    contour(net.x_um, net.y_um, double(net.crackMask), [0.5 0.5], ...
        'Color', [0.9 0.0 0.0], 'LineWidth', 1.0);
end

end
