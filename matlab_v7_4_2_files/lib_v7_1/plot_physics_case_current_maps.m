function h = plot_physics_case_current_maps(bestRuns)
%PLOT_PHYSICS_CASE_CURRENT_MAPS Current-flow maps for best v6.7 cases.

valid = arrayfun(@(s) isfield(s, 'run') && ~isempty(s.run), bestRuns);
bestRuns = bestRuns(valid);
nDev = numel(bestRuns);

h = figure('Name', 'v6.7 physics case current maps', 'Color', 'w', ...
    'Position', [80 80 1160 310*nDev]);
tiledlayout(nDev, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:nDev
    run = bestRuns(d).run;
    net = run.net;

    Tlow = min(run.result.T);
    Tmid = representative_transition_temperature(run);
    Thigh = max(run.result.T);
    Tlist = [Tlow, Tmid, Thigh];
    names = {'low T', 'near transition', 'high T'};

    for k = 1:3
        T = Tlist(k);
        [Ix, Iy] = solve_currents_at_T(run, T);
        Jnode = current_node_map(net, Ix, Iy);

        nexttile;
        imagesc(net.x_um, net.y_um, Jnode);
        set(gca, 'YDir', 'normal');
        axis image tight;
        colorbar;
        title(sprintf('%s, T=%.2g K', names{k}, T));
        xlabel('x [\mum]');
        if k == 1
            ylabel({run.device; 'y [\mum]'}, 'FontWeight', 'bold');
        else
            ylabel('y [\mum]');
        end
        hold on;
        draw_geometry_overlays(net, run.spec);
        apply_light_figure_style(gca);
    end
end

end

function Tmid = representative_transition_temperature(run)

pairName = run.modelPair;
if ~isfield(run.result.R4p, pairName)
    names = fieldnames(run.result.R4p);
    pairName = names{1};
end
metrics = compute_rt_curve_metrics(run.result.T, run.result.R4p.(pairName), make_metric_options());
Tmid = metrics.Tmid_K;
if ~isfinite(Tmid)
    Tmid = median(run.result.T);
end

end

function [Ix, Iy] = solve_currents_at_T(run, T)

[Rx, Ry] = link_resistance_T(run.params, run.spec, T);
gx = safe_conductance(Rx, run.net.link.activeX);
gy = safe_conductance(Ry, run.net.link.activeY);
[~, Ix, Iy] = solve_network_linear(run.net, gx, gy, run.spec.sim.Iprobe);

end

function Jnode = current_node_map(net, Ix, Iy)

Jnode = zeros(size(net.active));
count = zeros(size(net.active));
[Ny, Nx] = size(net.active);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            val = abs(Ix(row,col));
            Jnode(row,col) = Jnode(row,col) + val;
            Jnode(row,col+1) = Jnode(row,col+1) + val;
            count(row,col) = count(row,col) + 1;
            count(row,col+1) = count(row,col+1) + 1;
        end
    end
end
for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            val = abs(Iy(row,col));
            Jnode(row,col) = Jnode(row,col) + val;
            Jnode(row+1,col) = Jnode(row+1,col) + val;
            count(row,col) = count(row,col) + 1;
            count(row+1,col) = count(row+1,col) + 1;
        end
    end
end

valid = count > 0;
Jnode(valid) = Jnode(valid) ./ count(valid);
Jnode(~net.active) = NaN;
if any(valid(:))
    mx = max(Jnode(valid), [], 'omitnan');
    if isfinite(mx) && mx > 0
        Jnode(valid) = Jnode(valid) ./ mx;
    end
end

end

function draw_geometry_overlays(net, spec)

safe_mask_contour(net, net.coveredMask, [0.1 0.5 0.1], 0.8);
safe_mask_contour(net, net.boundaryMask, [0.9 0.6 0.1], 0.8);
if strcmp(spec.geometryClass, 'cracked_full')
    safe_mask_contour(net, net.crackMask, [0.9 0.0 0.0], 1.0);
end

end

function safe_mask_contour(net, mask, color, lineWidth)

z = double(mask);
if any(z(:) == 0) && any(z(:) == 1)
    contour(net.x_um, net.y_um, z, [0.5 0.5], ...
        'Color', color, 'LineWidth', lineWidth);
end

end
