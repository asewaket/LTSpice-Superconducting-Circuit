function h = plot_phase15E_field_model_adequacy_decision_summary( ...
    cfg, variantResiduals, currentRegion, criticalEnvelope, ...
    oscillationMorphology, predictionBounds, preferredVariant, gateSummary)
%PLOT_PHASE15E_FIELD_MODEL_ADEQUACY_DECISION_SUMMARY Plot Phase 15E summary.

h = figure('Name', 'v9 Phase 15E field-model adequacy decision', ...
    'Color', 'w', 'Position', [80 80 1800 1050]);
tiledlayout(h, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_residual_comparison(variantResiduals);
plot_incremental_gain(variantResiduals);
plot_current_region_transfer(currentRegion);
plot_oscillation_morphology(oscillationMorphology);
plot_prediction_bounds(predictionBounds);
plot_decision_panel(preferredVariant, gateSummary);

sgtitle('Phase 15E read-only AS006 field-model adequacy decision', ...
    'FontWeight', 'bold');

pngPath = [cfg.phase15E.figureBaseFile '.png'];
pdfPath = [cfg.phase15E.figureBaseFile '.pdf'];
exportgraphics(h, pngPath, 'Resolution', 200);
exportgraphics(h, pdfPath, 'ContentType', 'vector');
end

function plot_residual_comparison(T)
nexttile;
variants = ["P0"; "PB"; "Pphi"];
channels = ["R1"; "R2"];
M = nan(numel(channels), numel(variants));
for i = 1:numel(channels)
    for j = 1:numel(variants)
        idx = string(T.channel) == channels(i) & string(T.variant) == variants(j);
        if any(idx)
            M(i, j) = T.mean_squared_residual(idx);
        end
    end
end
bar(M);
set(gca, 'XTickLabel', channels);
ylabel('normalized MSE');
title('full-map residuals');
legend(variants, 'Location', 'best');
grid on;
end

function plot_incremental_gain(T)
nexttile;
channels = ["R1"; "R2"];
gain = nan(numel(channels), 1);
for i = 1:numel(channels)
    idx = string(T.channel) == channels(i) & string(T.variant) == "Pphi";
    if any(idx)
        pbIdx = string(T.channel) == channels(i) & string(T.variant) == "PB";
        gain(i) = T.Pphi_MSE_gain_vs_PB(idx) ./ ...
            T.mean_squared_residual(pbIdx);
    end
end
bar(gain);
set(gca, 'XTickLabel', channels);
ylabel('fractional MSE gain');
title('P_{\phi} incremental gain vs P_B');
yline(0, 'k-');
grid on;
end

function plot_current_region_transfer(T)
nexttile;
variants = ["PB"; "Pphi"];
channels = ["R1"; "R2"];
low = nan(numel(channels), numel(variants));
high = nan(numel(channels), numel(variants));
for i = 1:numel(channels)
    for j = 1:numel(variants)
        idx = string(T.channel) == channels(i) & string(T.variant) == variants(j);
        if any(idx)
            low(i, j) = T.low_current_fractional_gain(idx);
            high(i, j) = T.high_current_fractional_gain(idx);
        end
    end
end
bar([low(:), high(:)]);
labels = strings(numel(channels) * numel(variants), 1);
k = 0;
for i = 1:numel(channels)
    for j = 1:numel(variants)
        k = k + 1;
        labels(k) = variants(j) + " " + channels(i);
    end
end
set(gca, 'XTickLabel', labels);
xtickangle(35);
ylabel('fractional gain vs P0');
title('current-region transfer');
legend(["low |I|"; "high |I|"], 'Location', 'best');
yline(0, 'k-');
grid on;
end

function plot_oscillation_morphology(T)
nexttile;
channels = unique(string(T.channel), 'stable');
observed = nan(numel(channels), 1);
pphi = nan(numel(channels), 1);
for i = 1:numel(channels)
    pphiIdx = string(T.channel) == channels(i) & ...
        string(T.variant) == "Pphi";
    if any(pphiIdx)
        observed(i) = T.observed_turning_points(pphiIdx);
        pphi(i) = T.model_turning_points(pphiIdx);
    end
end
bar([observed, pphi]);
set(gca, 'XTickLabel', channels);
ylabel('turning-point count');
title('oscillation morphology');
legend(["observed"; "P_{\phi}"], 'Location', 'best');
grid on;
end

function plot_prediction_bounds(T)
nexttile;
variants = ["P0"; "PB"; "Pphi"];
channels = ["R1"; "R2"];
M = nan(numel(channels), numel(variants));
for i = 1:numel(channels)
    for j = 1:numel(variants)
        idx = string(T.channel) == channels(i) & string(T.variant) == variants(j);
        if any(idx)
            M(i, j) = T.fraction_outside_bounds(idx);
        end
    end
end
bar(M);
set(gca, 'XTickLabel', channels);
ylabel('fraction outside bounds');
title('prediction-bound limitation');
legend(variants, 'Location', 'best');
grid on;
end

function plot_decision_panel(preferredVariant, gateSummary)
nexttile;
status = string(gateSummary.outcome);
cats = ["pass"; "fail"; "not_run"];
counts = zeros(size(cats));
for i = 1:numel(cats)
    counts(i) = sum(status == cats(i));
end
bar(counts);
set(gca, 'XTickLabel', cats);
ylabel('gate count');
title('Phase 15E gates');
grid on;

decision = lookup_value(preferredVariant, "phase15E_decision");
preferred = lookup_value(preferredVariant, "preferred_field_variant");
text(0.65, max(counts) * 0.82, "decision: " + decision, ...
    'FontWeight', 'bold', 'Color', [0.45 0 0]);
text(0.65, max(counts) * 0.68, "preferred: " + preferred, ...
    'FontWeight', 'bold');
end

function value = lookup_value(T, item)
value = "";
if ~ismember("item", string(T.Properties.VariableNames)) || ...
        ~ismember("value", string(T.Properties.VariableNames))
    return;
end
idx = string(T.item) == item;
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
end
end
