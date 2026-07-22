function h = plot_v741_as006_field_summary(spec, field, expField, score)
%PLOT_V741_AS006_FIELD_SUMMARY Thesis-style AS006 weak-link field-map comparison.

if nargin < 4
    score = struct('available', false, 'combined', NaN);
end

h = figure('Name', 'v7.4.1 AS006 weak-link magnetic-field dVdI maps', ...
    'Color', 'w', 'Position', [60 60 1500 980]);
tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

pairs = {'top_4_10','bottom_3_9'};
pairLabels = {'top 4-10','bottom 3-9'};

for kp = 1:2
    pairName = pairs{kp};
    pairLabel = pairLabels{kp};

    nexttile(kp);
    plot_exp_field_map(expField, pairName);
    title(sprintf('experiment %s', pairLabel));

    nexttile(kp + 3);
    plot_model_field_map(field, pairName);
    title(sprintf('model %s', pairLabel));

    nexttile(kp + 6);
    plot_residual_field_map(field, expField, pairName);
    title(sprintf('model - experiment, %s', pairLabel));
end

nexttile(3);
plot_zero_bias_field(field, expField);
title('zero-bias dV/dI(B)');

nexttile(6);
plot_selected_field_cuts(field, expField);
title('selected dV/dI(I) cuts');

nexttile(9);
plot_field_diagnostics(field);
title('field suppression / weak-link switching');

if isfield(score, 'available') && score.available
    scoreText = sprintf('field score %.3g', score.combined);
else
    scoreText = 'field score unavailable';
end
sgtitle(sprintf('v7.4.1 %s weak-link out-of-plane field scaffold: %s, %s', ...
    spec.name, spec.filmForceLabel, scoreText), 'FontWeight', 'bold');

end

function plot_exp_field_map(expField, pairName)

if ~has_pair(expField, pairName)
    text(0.1, 0.5, sprintf('no experiment %s', pairName), ...
        'Units', 'normalized');
    axis off;
    return;
end

imagesc(1e3 .* expField.B_T, 1e6 .* expField.I_A, expField.Rnorm.(pairName));
set(gca, 'YDir', 'normal');
xlabel('B_\perp [mT]');
ylabel('current I [\muA]');
cb = colorbar;
ylabel(cb, 'dV/dI / R_N');
caxis(percentile_limits(expField.Rnorm.(pairName), [2 98], [0 1.5]));
apply_light_figure_style(gca);

end

function plot_model_field_map(field, pairName)

Z = normalize_map(field.dVdI.(pairName));
imagesc(1e3 .* field.B_T, 1e6 .* field.I_A, Z);
set(gca, 'YDir', 'normal');
xlabel('B_\perp [mT]');
ylabel('current I [\muA]');
cb = colorbar;
ylabel(cb, 'dV/dI / R_N');
caxis(percentile_limits(Z, [2 98], [0 1.5]));
apply_light_figure_style(gca);

end

function plot_residual_field_map(field, expField, pairName)

if ~has_pair(expField, pairName)
    text(0.1, 0.5, sprintf('no experiment %s', pairName), ...
        'Units', 'normalized');
    axis off;
    return;
end

modelNorm = normalize_map(field.dVdI.(pairName));
expOnModel = interp_exp_to_model(expField, expField.Rnorm.(pairName), field);
Z = modelNorm - expOnModel;

imagesc(1e3 .* field.B_T, 1e6 .* field.I_A, Z);
set(gca, 'YDir', 'normal');
xlabel('B_\perp [mT]');
ylabel('current I [\muA]');
cb = colorbar;
ylabel(cb, '\Delta normalized dV/dI');
colormap(gca, redblue_local());
caxis(symmetric_limits(Z, 0.8));
apply_light_figure_style(gca);

end

function plot_zero_bias_field(field, expField)

hold on;
pairs = {'top_4_10','bottom_3_9'};
labels = {'top 4-10','bottom 3-9'};
colors = [0.00 0.45 0.74; 0.85 0.33 0.10];

for kp = 1:numel(pairs)
    pairName = pairs{kp};
    modelNorm = normalize_map(field.dVdI.(pairName));
    zbm = zero_bias_trace(field.I_A, modelNorm);
    plot(1e3 .* field.B_T, zbm, '-', 'LineWidth', 1.8, ...
        'Color', colors(kp,:), ...
        'DisplayName', sprintf('model %s', labels{kp}));

    if has_pair(expField, pairName)
        zbe = zero_bias_trace(expField.I_A, expField.Rnorm.(pairName));
        plot(1e3 .* expField.B_T, zbe, 'o', 'MarkerSize', 2.5, ...
            'Color', colors(kp,:), ...
            'DisplayName', sprintf('experiment %s', labels{kp}));
    end
end

xlabel('B_\perp [mT]');
ylabel('zero-bias dV/dI / R_N');
grid on; box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end

function plot_selected_field_cuts(field, expField)

hold on;
Bcuts = choose_field_cuts(field.B_T, expField);
pairs = {'top_4_10','bottom_3_9'};
labels = {'top','bottom'};
styles = {'-','--'};
markers = {'o','s'};
colors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

for kp = 1:numel(pairs)
    pairName = pairs{kp};
    modelNorm = normalize_map(field.dVdI.(pairName));
    for kb = 1:numel(Bcuts)
        [~, idx] = min(abs(field.B_T - Bcuts(kb)));
        plot(1e6 .* field.I_A, modelNorm(:,idx), styles{kp}, ...
            'Color', colors(kb,:), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('model %s, B=%.1f mT', ...
            labels{kp}, 1e3 .* field.B_T(idx)));
    end

    if has_pair(expField, pairName)
        for kb = 1:numel(Bcuts)
            [~, idxExp] = min(abs(expField.B_T - Bcuts(kb)));
            plot(1e6 .* expField.I_A, expField.Rnorm.(pairName)(:,idxExp), ...
                markers{kp}, 'Color', colors(kb,:), 'MarkerSize', 2.2, ...
                'LineWidth', 0.7, ...
                'DisplayName', sprintf('exp %s, B=%.1f mT', ...
                labels{kp}, 1e3 .* expField.B_T(idxExp)));
        end
    end
end

xlabel('current I [\muA]');
ylabel('dV/dI / R_N');
ylim([0 1.8]);
grid on; box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end

function plot_field_diagnostics(field)

yyaxis left;
plot(1e3 .* field.B_T, field.meanTcFactor, '-', 'LineWidth', 1.8, ...
    'DisplayName', '\langle T_c(B)/T_c(0)\rangle');
hold on;
plot(1e3 .* field.B_T, field.meanIcFactor, '--', 'LineWidth', 1.8, ...
    'DisplayName', '\langle I_c(B)/I_c(0)\rangle');
ylabel('mean suppression factor');
ylim([0 1.05]);

yyaxis right;
plot(1e3 .* field.B_T, max(field.switchedFraction, [], 1), ':', ...
    'LineWidth', 1.8, 'DisplayName', 'max switched fraction');
if isfield(field, 'weakSwitchedFraction')
    hold on;
    plot(1e3 .* field.B_T, max(field.weakSwitchedFraction, [], 1), '-.', ...
        'LineWidth', 1.8, 'DisplayName', 'max weak-link switched fraction');
end
ylabel('max switched fraction');
ylim([0 1]);

xlabel('B_\perp [mT]');
grid on; box on;
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

end

function tf = has_pair(expField, pairName)

tf = isfield(expField, 'available') && expField.available && ...
    isfield(expField, 'Rnorm') && isfield(expField.Rnorm, pairName);

end

function Z = normalize_map(Z)

vals = Z(isfinite(Z));
if isempty(vals)
    return;
end
rn = percentile_local(vals, 95);
Z = Z ./ max(rn, eps);

end

function Zq = interp_exp_to_model(expField, Zexp, field)

[Bexp, Iexp] = meshgrid(expField.B_T, expField.I_A);
[Bq, Iq] = meshgrid(field.B_T, field.I_A);
Zq = interp2(Bexp, Iexp, Zexp, Bq, Iq, 'linear', NaN);

end

function zb = zero_bias_trace(I, Z)

[~, idx] = min(abs(I));
zb = Z(idx, :);

end

function Bcuts = choose_field_cuts(Bmodel, expField)

Bmin = min(Bmodel);
Bmax = max(Bmodel);
if isfield(expField, 'available') && expField.available
    Bmin = max(Bmin, min(expField.B_T));
    Bmax = min(Bmax, max(expField.B_T));
end
Bcuts = [Bmin, 0, Bmax];

end

function lim = percentile_limits(Z, pct, fallback)

vals = Z(isfinite(Z));
if isempty(vals)
    lim = fallback;
    return;
end
lo = percentile_local(vals, pct(1));
hi = percentile_local(vals, pct(2));
if isfinite(lo) && isfinite(hi) && hi > lo
    lim = [lo hi];
else
    lim = fallback;
end

end

function lim = symmetric_limits(Z, fallbackMax)

vals = Z(isfinite(Z));
if isempty(vals)
    lim = [-fallbackMax fallbackMax];
    return;
end
m = percentile_local(abs(vals), 98);
if ~(isfinite(m) && m > 0)
    m = fallbackMax;
end
lim = [-m m];

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
