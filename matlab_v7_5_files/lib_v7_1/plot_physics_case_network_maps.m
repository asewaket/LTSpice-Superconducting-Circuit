function h = plot_physics_case_network_maps(bestRuns)
%PLOT_PHYSICS_CASE_NETWORK_MAPS Spatial maps for best v6.7 cases.

valid = arrayfun(@(s) isfield(s, 'run') && ~isempty(s.run), bestRuns);
bestRuns = bestRuns(valid);
nDev = numel(bestRuns);

h = figure('Name', 'v6.7 physics case network maps', 'Color', 'w', ...
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
    axis image tight; colorbar;
    title('hybrid proxy \eta');
    xlabel('x [\mum]'); ylabel({run.device; 'y [\mum]'}, 'FontWeight', 'bold');
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);

    nexttile;
    if isfield(run.caseInfo, 'effectNode')
        effectNode = run.caseInfo.effectNode;
        effectLabel = run.caseInfo.effectLabel;
    else
        effectNode = double(run.caseInfo.domainNode | run.caseInfo.contactNode);
        effectLabel = 'active case mask';
    end
    imagesc(net.x_um, net.y_um, effectNode);
    set(gca, 'YDir', 'normal');
    axis image tight; caxis([0 1]); colorbar;
    title(sprintf('%s effect', short_case_name(run.physicsCase.caseID)), 'Interpreter', 'none');
    xlabel('x [\mum]'); ylabel('y [\mum]');
    text(0.02, 0.03, short_effect_label(effectLabel), 'Units', 'normalized', ...
        'FontSize', 8, 'Color', [0.15 0.15 0.15], 'Interpreter', 'none', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);

    nexttile;
    imagesc(net.x_um, net.y_um, double(scNode));
    set(gca, 'YDir', 'normal');
    axis image tight; caxis([0 1]); colorbar;
    title(sprintf('SC-like links, T=%.2g K', Tlow));
    xlabel('x [\mum]'); ylabel('y [\mum]');
    hold on; draw_geometry_overlays(net, run.spec);
    apply_light_figure_style(gca);
end

end

function name = short_case_name(caseID)

caseID = char(caseID);
tok = regexp(caseID, 'case_([A-Z])_', 'tokens', 'once');
if isempty(tok)
    name = 'baseline';
else
    name = ['Case ' tok{1}];
end

end

function label = short_effect_label(effectLabel)

effectLabel = char(effectLabel);
if contains(effectLabel, 'weak-link')
    label = 'weak-link modulation';
elseif contains(effectLabel, 'boundary-channel')
    label = 'finite boundary channel';
elseif contains(effectLabel, 'interrupted')
    label = 'interrupted lane';
elseif contains(effectLabel, 'boundary-lane')
    label = 'boundary lane';
elseif contains(effectLabel, 'crack')
    label = 'crack edge';
elseif contains(effectLabel, 'contact')
    label = 'contact relaxation';
elseif contains(effectLabel, 'baseline')
    label = 'no added case mask';
else
    label = effectLabel;
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
