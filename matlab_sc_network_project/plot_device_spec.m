function h = plot_device_spec(net, spec)
%PLOT_DEVICE_SPEC Visualize geometry/stressor/contact/probe masks.

h = figure('Color','w', 'Name', sprintf('%s masks', spec.name));

subplot(1,2,1);
hold on;
imagesc(net.x_um, net.y_um, double(net.active));
set(gca, 'YDir','normal');
axis image tight;
colormap(gca, gray);
title(sprintf('%s geometry, %s', spec.name, spec.filmForceLabel));
xlabel('x [\mum]');
ylabel('y [\mum]');

overlay_mask(net.x_um, net.y_um, net.coveredMask, [0.2 0.5 1.0], 0.25);
overlay_mask(net.x_um, net.y_um, net.boundaryMask, [1.0 0.7 0.1], 0.35);
overlay_mask(net.x_um, net.y_um, net.crackMask, [1.0 0.0 0.0], 0.55);
overlay_mask(net.x_um, net.y_um, net.sourceMask, [0.0 0.7 0.2], 0.45);
overlay_mask(net.x_um, net.y_um, net.drainMask, [0.0 0.7 0.2], 0.45);

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

subplot(1,2,2);
regionImage = zeros(size(net.active));
regionImage(net.edgeMask) = spec.region.edge;
regionImage(net.coveredMask) = spec.region.covered;
regionImage(net.boundaryMask) = spec.region.boundary;
regionImage(net.crackMask) = spec.region.crack;
imagesc(net.x_um, net.y_um, regionImage);
set(gca, 'YDir','normal');
axis image tight;
title('Node-region masks');
xlabel('x [\mum]');
ylabel('y [\mum]');
colorbar('Ticks',0:5, 'TickLabels', [{'none'}, spec.regionNames]);

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
