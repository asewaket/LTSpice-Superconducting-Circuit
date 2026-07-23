function h = plot_v72_as006_nonlinear_summary(spec, net, pdeMap, nl, maps, expData, expDvdI)
%PLOT_V72_AS006_NONLINEAR_SUMMARY Plot dV/dI and current-map diagnostics.

if nargin < 6
    error(['plot_v72_as006_nonlinear_summary is a helper function and needs ', ...
        'precomputed inputs. Run run_v72_as006_nonlinear_maps instead.']);
end
if nargin < 7
    expDvdI = struct('available', false);
end

h = figure('Name', 'v7.2.2 AS006 nonlinear dVdI/current maps', ...
    'Color', 'w', 'Position', [50 50 1450 980]);
tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_dvdi_map(nl, 'top_4_10', spec);
title('model dV/dI, top 4-10');

nexttile;
plot_dvdi_map(nl, 'bottom_3_9', spec);
title('model dV/dI, bottom 3-9');

nexttile;
plot_switched_fraction_map(nl);
title(sprintf('switched-link fraction; max |I_{link}|/I_c = %.2g', ...
    max(nl.maxAbsIOverIc(:), [], 'omitnan')));

nexttile;
plot_spatial_map(net, maps.high.switchedNode, [0 1], ...
    'incident switched-link fraction');
title(sprintf('switched links, T=%.2g K, I=%.2g \\muA', ...
    maps.T_K, 1e6 * maps.I_high_A));

nexttile;
plot_spatial_map(net, maps.low.currentDensityCommonNorm, [0 1], ...
    'normalized |J|');
title(sprintf('current density, low I=%.2g \\muA', 1e6 * maps.I_low_A));

nexttile;
plot_spatial_map(net, maps.high.currentDensityCommonNorm, [0 1], ...
    'normalized |J|');
title(sprintf('current density, high I=%.2g \\muA', 1e6 * maps.I_high_A));

nexttile;
plot_spatial_map(net, pdeMap.etaNode, [0 1], 'network proxy \eta');
title('PDE-informed network proxy \eta');

nexttile;
plot_spatial_map(net, maps.redistributionNorm, [-1 1], ...
    'normalized \Delta |J|');
colormap(gca, redblue_local());
title('current redistribution: high I - low I');

nexttile;
plot_iv_cuts(nl, expData, expDvdI, spec);
title('selected top/bottom dV/dI(I) cuts');

sgtitle(sprintf('v7.2.2 %s nonlinear Ic/current-redistribution scaffold: %s', ...
    spec.name, spec.filmForceLabel), 'FontWeight', 'bold');

end

function plot_dvdi_map(nl, pairName, spec)

Z = nl.dVdI.(pairName) ./ max(spec.targetRN_ohm, eps);
imagesc(nl.T, 1e6 * nl.I, Z);
set(gca, 'YDir', 'normal');
xlabel('Temperature T [K]');
ylabel('current I [\muA]');
cb = colorbar;
ylabel(cb, 'dV/dI / R_N');
caxis(percentile_limits(Z, [2 98], [0 2]));
apply_light_figure_style(gca);

end

function plot_switched_fraction_map(nl)

imagesc(nl.T, 1e6 * nl.I, nl.switchedFraction);
set(gca, 'YDir', 'normal');
xlabel('Temperature T [K]');
ylabel('current I [\muA]');
cb = colorbar;
ylabel(cb, 'fraction of links with |I_{link}| \geq I_c');
caxis([0 1]);
apply_light_figure_style(gca);

end

function plot_spatial_map(net, Z, clim, cbLabel)

imagesc(net.x_um, net.y_um, Z);
set(gca, 'YDir', 'normal');
axis image tight;
if ~isempty(clim)
    caxis(clim);
end
xlabel('x [\mum]');
ylabel('y [\mum]');
cb = colorbar;
ylabel(cb, cbLabel);
hold on;
draw_overlays(net);
apply_light_figure_style(gca);

end

function plot_iv_cuts(nl, expData, expDvdI, spec) %#ok<INUSD>

hold on;
pairs = {'top_4_10','bottom_3_9'};
pairLabels = {'top 4-10','bottom 3-9'};
lineStyles = {'-','--'};
markers = {'o','s'};
Tcuts = choose_temperature_cuts(nl.T, expDvdI);
colors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

for kp = 1:numel(pairs)
    pairName = pairs{kp};
    if ~isfield(nl.dVdI, pairName)
        continue;
    end
    for k = 1:numel(Tcuts)
        [~, idx] = min(abs(nl.T - Tcuts(k)));
        Rmodel = nl.dVdI.(pairName)(:, idx) ./ max(spec.targetRN_ohm, eps);
        plot(1e6 * nl.I, Rmodel, lineStyles{kp}, 'LineWidth', 1.8, ...
            'Color', colors(k,:), ...
            'DisplayName', sprintf('model %s, T=%.2g K', ...
            pairLabels{kp}, nl.T(idx)));
    end
end

hasExpDvdI = isfield(expDvdI, 'available') && expDvdI.available && ...
    isfield(expDvdI, 'Rnorm');

if hasExpDvdI
    for kp = 1:numel(pairs)
        pairName = pairs{kp};
        if ~isfield(expDvdI.Rnorm, pairName)
            continue;
        end
        Zexp = expDvdI.Rnorm.(pairName);
        for k = 1:numel(Tcuts)
            [~, idxExp] = min(abs(expDvdI.T - Tcuts(k)));
            plot(1e6 * expDvdI.I, Zexp(:, idxExp), markers{kp}, ...
                'MarkerSize', 3.0, 'LineWidth', 0.8, ...
                'Color', colors(k,:), ...
                'DisplayName', sprintf('experiment %s, T=%.2g K', ...
                pairLabels{kp}, expDvdI.T(idxExp)));
        end
    end
else
    text(0.02, 0.92, 'no experimental dV/dI(I,T) grid loaded', ...
        'Units', 'normalized', 'Color', [0.25 0.25 0.25], ...
        'FontSize', 9, 'Interpreter', 'none');
end

xlabel('current I [\muA]');
ylabel('dV/dI / R_N');
ylim([0 2.2]);
grid on; box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end

function Tcuts = choose_temperature_cuts(T, expDvdI)

Tmin = min(T);
Tmax = max(T);
if isfield(expDvdI, 'available') && expDvdI.available && ...
        isfield(expDvdI, 'T') && ~isempty(expDvdI.T)
    Tmin = max(Tmin, min(expDvdI.T));
    Tmax = min(Tmax, max(expDvdI.T));
end
if ~(isfinite(Tmin) && isfinite(Tmax) && Tmax > Tmin)
    Tmin = min(T);
    Tmax = max(T);
end
Tcuts = [Tmin + 0.10*(Tmax-Tmin), Tmin + 0.45*(Tmax-Tmin), ...
    Tmin + 0.80*(Tmax-Tmin)];

end

function draw_overlays(net)

safe_contour(net, net.active, [0.10 0.10 0.10], 0.8, '-');
safe_contour(net, net.boundaryMask, [0.95 0.55 0.0], 1.0, '-');
safe_contour(net, net.sourceMask | net.drainMask, [0.1 0.55 0.2], 1.0, '-');
probeNames = fieldnames(net.probeMasks);
for k = 1:numel(probeNames)
    safe_contour(net, net.probeMasks.(probeNames{k}), [0.85 0.05 0.10], 1.0, '-');
end

end

function safe_contour(net, mask, color, lw, style)

z = double(mask);
if any(z(:) == 0) && any(z(:) == 1)
    contour(net.x_um, net.y_um, z, [0.5 0.5], ...
        'Color', color, 'LineWidth', lw, 'LineStyle', style);
end

end

function lim = percentile_limits(Z, pct, fallback)

vals = Z(isfinite(Z));
if isempty(vals)
    lim = fallback;
    return;
end
lo = percentile_local(vals, pct(1));
hi = percentile_local(vals, pct(2));
if ~(isfinite(lo) && isfinite(hi) && hi > lo)
    lim = fallback;
else
    lim = [lo hi];
end

end

function p = percentile_local(x, pct)

x = sort(x(:));
q = 1 + (numel(x)-1) * pct / 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (q-lo) * (x(hi)-x(lo));
end

end

function cmap = redblue_local()

n = 256;
r = [(0:n/2-1)'/(n/2); ones(n/2,1)];
g = [(0:n/2-1)'/(n/2); flipud((0:n/2-1)'/(n/2))];
b = [ones(n/2,1); flipud((0:n/2-1)'/(n/2))];
cmap = [r g b];

end
