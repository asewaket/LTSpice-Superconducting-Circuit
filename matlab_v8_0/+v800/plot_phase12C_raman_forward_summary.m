function h = plot_phase12C_raman_forward_summary(cfg, priors, predictions, ...
    nonstrainLedger, registeredStatus, uncertaintySensitivity, gates)
%PLOT_PHASE12C_RAMAN_FORWARD_SUMMARY Plot Phase 12C diagnostics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 12C Raman forward feasibility', ...
    'Color', 'w', 'Position', [120 120 1700 940]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_mode_component_priors(priors);
title('mode-component response priors');

nexttile;
plot_device_predictions(predictions);
title('device-level mode predictions');

nexttile;
plot_registered_status(registeredStatus);
title('registered spatial comparison');

nexttile;
plot_nonstrain_terms(nonstrainLedger);
title('non-strain terms retained');

nexttile;
plot_uncertainty(uncertaintySensitivity);
title('prediction uncertainty');

nexttile;
plot_gate_summary(gates);
title('Phase 12C gates');

titleHandle = sgtitle( ...
    'Phase 12C mode-specific Raman forward-model feasibility');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase12C.figureBaseFile '.png']);
saveas(h, [cfg.phase12C.figureBaseFile '.pdf']);
end

function plot_mode_component_priors(T)
if isempty(T)
    empty_panel('missing mode prior ledger');
    return;
end
modes = unique(string(T.mode_id), 'stable');
components = unique(string(T.component_id), 'stable');
M = NaN(numel(modes), numel(components));
for i = 1:numel(modes)
    for j = 1:numel(components)
        idx = find(string(T.mode_id) == modes(i) & ...
            string(T.component_id) == components(j), 1, 'first');
        if ~isempty(idx)
            M(i, j) = T.coefficient_prior_center(idx);
        end
    end
end
imagesc(M);
colorbar;
set(gca, 'XTick', 1:numel(components), 'XTickLabel', components);
set(gca, 'YTick', 1:numel(modes), 'YTickLabel', modes);
xtickangle(30);
axis tight;
end

function plot_device_predictions(T)
if isempty(T)
    empty_panel('missing device predictions');
    return;
end
devices = unique(string(T.device), 'stable');
modes = unique(string(T.mode_id), 'stable');
M = NaN(numel(devices), numel(modes));
for i = 1:numel(devices)
    for j = 1:numel(modes)
        idx = find(string(T.device) == devices(i) & ...
            string(T.mode_id) == modes(j), 1, 'first');
        if ~isempty(idx)
            M(i, j) = T.predicted_response_nominal(idx);
        end
    end
end
bar(M);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
xtickangle(25);
ylabel('relative response');
legend(modes, 'Location', 'northwest', 'Interpreter', 'none');
grid on;
end

function plot_registered_status(T)
if isempty(T)
    empty_panel('missing registered comparison status');
    return;
end
statuses = string(T.quantitative_registered_comparison);
labels = unique(statuses, 'stable');
counts = zeros(numel(labels), 1);
for k = 1:numel(labels)
    counts(k) = sum(statuses == labels(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
hold on;
for k = 1:numel(labels)
    if labels(k) == "not_run"
        text(k, counts(k) + 0.10, "no transform", ...
            'HorizontalAlignment', 'center', 'Color', [0.70 0.05 0.05], ...
            'FontWeight', 'bold');
    end
end
hold off;
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
ylabel('device count');
grid on;
end

function plot_nonstrain_terms(T)
if isempty(T)
    empty_panel('missing non-strain ledger');
    return;
end
terms = unique(string(T.nonstrain_term), 'stable');
counts = zeros(numel(terms), 1);
for k = 1:numel(terms)
    counts(k) = sum(string(T.nonstrain_term) == terms(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(terms), 'XTickLabel', terms);
xtickangle(25);
ylabel('mode count');
grid on;
end

function plot_uncertainty(T)
if isempty(T)
    empty_panel('missing uncertainty table');
    return;
end
classes = string(T.confidence_class);
labels = unique(classes, 'stable');
counts = zeros(numel(labels), 1);
for k = 1:numel(labels)
    counts(k) = sum(classes == labels(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('prediction count');
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.outcome) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', ...
    'Color', 'k');
axis off;
end

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
end
