function h = plot_v71_device_asymmetry_diagnostics(spec, asym, expData)
%PLOT_V71_DEVICE_ASYMMETRY_DIAGNOSTICS Plot top-bottom R(T) asymmetry.

if nargin < 3
    expData = struct();
end

h = figure('Name', sprintf('v7.1 %s top-bottom asymmetry diagnostic', spec.name), ...
    'Color', 'w', 'Position', [90 90 1120 430]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

curves = asym.curves;

nexttile;
hold on;
plot(curves.T_K, curves.model_top_4_10_norm, '-', ...
    'Color', [0.00 0.45 0.74], 'LineWidth', 2.2, ...
    'DisplayName', 'model top 4-10');
plot(curves.T_K, curves.model_bottom_3_9_norm, '-', ...
    'Color', [0.85 0.33 0.10], 'LineWidth', 2.2, ...
    'DisplayName', 'model bottom 3-9');

if asym.summary.experimentAvailable
    plot(curves.T_K, curves.exp_top_4_10_norm, 'o', ...
        'Color', [0.00 0.45 0.74], 'MarkerSize', 3.5, ...
        'DisplayName', 'exp top 4-10');
    plot(curves.T_K, curves.exp_bottom_3_9_norm, 'o', ...
        'Color', [0.85 0.33 0.10], 'MarkerSize', 3.5, ...
        'DisplayName', 'exp bottom 3-9');
else
    anyPartialPair = false;
    [TpartialTop, RpartialTop] = partial_experimental_pair_curve(expData, 'top_4_10');
    if ~isempty(TpartialTop)
        plot(TpartialTop, RpartialTop, 'o', ...
            'Color', [0.00 0.45 0.74], 'MarkerSize', 3.5, ...
            'DisplayName', 'exp top 4-10 partial');
        anyPartialPair = true;
    else
        plot(NaN, NaN, 'o', ...
            'Color', [0.00 0.45 0.74], 'MarkerSize', 3.5, ...
            'DisplayName', 'exp top 4-10 unavailable');
    end

    [TpartialBottom, RpartialBottom] = partial_experimental_pair_curve(expData, 'bottom_3_9');
    if ~isempty(TpartialBottom)
        plot(TpartialBottom, RpartialBottom, 'o', ...
            'Color', [0.85 0.33 0.10], 'MarkerSize', 3.5, ...
            'DisplayName', 'exp bottom 3-9 partial');
        anyPartialPair = true;
    else
        plot(NaN, NaN, 'o', ...
            'Color', [0.85 0.33 0.10], 'MarkerSize', 3.5, ...
            'DisplayName', 'exp bottom 3-9 unavailable');
    end

    [Tmain, Rmain] = main_experimental_curve(expData);
    if ~anyPartialPair && ~isempty(Tmain)
        plot(Tmain, Rmain, 'o', ...
            'Color', [0.45 0.45 0.45], 'MarkerSize', 3.5, ...
            'DisplayName', 'experiment main only');
    end
    add_missing_pair_note(asym.summary);
end

xlabel('Temperature T [K]');
ylabel('pair-normalized R/R_N');
title('top and bottom four-probe curves');
ylim([0 1.15]);
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

nexttile;
hold on;
plot(curves.T_K, curves.model_delta_bottom_minus_top, '-', ...
    'Color', [0.15 0.15 0.15], 'LineWidth', 2.4, ...
    'DisplayName', 'model \Delta r');

if asym.summary.experimentAvailable
    plot(curves.T_K, curves.exp_delta_bottom_minus_top, 'o', ...
        'Color', [0.55 0.15 0.65], 'MarkerSize', 3.5, ...
        'DisplayName', 'experiment \Delta r');
    plot(curves.T_K, curves.delta_model_minus_exp, '--', ...
        'Color', [0.30 0.30 0.30], 'LineWidth', 1.4, ...
        'DisplayName', 'model - experiment');
else
    plot(NaN, NaN, 'o', ...
        'Color', [0.55 0.15 0.65], 'MarkerSize', 3.5, ...
        'DisplayName', 'experiment \Delta r unavailable');
    add_missing_pair_note(asym.summary);
end

yline(0, ':', 'Color', [0.25 0.25 0.25], 'HandleVisibility', 'off');
xlabel('Temperature T [K]');
ylabel('\Delta r = r_{3-9} - r_{4-10}');
if asym.summary.experimentAvailable
    title(sprintf('\\Delta r mismatch RMS = %.3g', asym.summary.deltaMismatchRms));
else
    title('experimental \Delta r unavailable');
end
apply_light_figure_style(gca);
lgd = legend('Location', 'best');
apply_light_legend_style(lgd);

sgtitle(sprintf('v7.1 %s top-bottom asymmetry: %s', ...
    spec.name, spec.filmForceLabel), 'FontWeight', 'bold');

end

function [T, Rnorm] = main_experimental_curve(expData)

T = [];
Rnorm = [];
if isfield(expData, 'available') && expData.available && ...
        isfield(expData, 'R') && isfield(expData.R, 'main_4p')
    [T, Rnorm] = normalize_rt_curve(expData.T, expData.R.main_4p);
end

end

function [T, Rnorm] = partial_experimental_pair_curve(expData, pairName)

T = [];
Rnorm = [];
if isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available && isfield(expData.pairData, 'R') && ...
        isfield(expData.pairData.R, pairName)
    [T, Rnorm] = normalize_rt_curve(expData.pairData.T, expData.pairData.R.(pairName));
end

end

function add_missing_pair_note(summary)

note = missing_pair_note(summary);
if isempty(note)
    return;
end

text(0.03, 0.06, note, ...
    'Units', 'normalized', 'FontSize', 8, ...
    'Color', [0.18 0.18 0.18], 'BackgroundColor', [1 1 1], ...
    'Margin', 2, 'VerticalAlignment', 'bottom', ...
    'Interpreter', 'none');

end

function note = missing_pair_note(summary)

note = 'separate top/bottom experimental pair data unavailable';
if isfield(summary, 'experimentAvailabilityNote') && ...
        strlength(string(summary.experimentAvailabilityNote)) > 0
    note = char(summary.experimentAvailabilityNote);
end

maxChars = 95;
if numel(note) > maxChars
    note = [note(1:maxChars-3) '...'];
end

end
