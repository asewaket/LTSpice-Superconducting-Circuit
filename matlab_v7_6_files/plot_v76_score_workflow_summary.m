function h = plot_v76_score_workflow_summary(scoreTemplate, gateTemplate)
%PLOT_V76_SCORE_WORKFLOW_SUMMARY Visual summary of v7.6 scoring logic.

if nargin < 1 || isempty(scoreTemplate)
    scoreTemplate = make_default_score_template();
end
if nargin < 2 || isempty(gateTemplate)
    gateTemplate = make_default_gate_template();
end

h = figure('Name', 'v7.6 multi-observable scoring workflow', 'Color', 'w');
set(h, 'InvertHardcopy', 'off');
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
bar(scoreTemplate.weight, 'FaceColor', [0.20 0.50 0.85], ...
    'EdgeColor', [0.15 0.25 0.35], 'LineWidth', 0.8);
set(gca, 'XTick', 1:height(scoreTemplate), ...
    'XTickLabel', short_component_labels(scoreTemplate.component), ...
    'XTickLabelRotation', 28);
ylabel('relative weight');
title('core score weights');
grid on;

nexttile;
includeFlag = get_score_include_flag(scoreTemplate);
bar(double(includeFlag), 'FaceColor', [0.30 0.70 0.35], ...
    'EdgeColor', [0.15 0.35 0.18], 'LineWidth', 0.8);
ylim([0 1.2]);
set(gca, 'XTick', 1:height(scoreTemplate), ...
    'XTickLabel', short_component_labels(scoreTemplate.component), ...
    'XTickLabelRotation', 28, 'YTick', [0 1], ...
    'YTickLabel', {'diagnostic', 'core'});
ylabel('role');
title('included in objective');
grid on;

nexttile;
requiredFlag = get_gate_required_flag(gateTemplate);
bar(double(requiredFlag), 'FaceColor', [0.90 0.55 0.20], ...
    'EdgeColor', [0.45 0.25 0.08], 'LineWidth', 0.8);
ylim([0 1.2]);
set(gca, 'XTick', 1:height(gateTemplate), ...
    'XTickLabel', short_gate_labels(gateTemplate.gate), ...
    'XTickLabelRotation', 25, 'YTick', [0 1], ...
    'YTickLabel', {'optional', 'required'});
ylabel('claim gate');
title('physical-claim gates');
grid on;

nexttile;
axText = gca;
axis(axText, 'off');
lineBreak = sprintf('\n');

text(axText, 0.02, 0.94, 'v7.6 interpretation rule:', ...
    'Units', 'normalized', 'FontWeight', 'bold', 'Color', 'k', ...
    'Interpreter', 'none');

ruleLines = { ...
    'A lower score is not a physical conclusion unless the improvement:', ...
    '- appears across disorder seeds;', ...
    '- helps both probe pairs or explains their difference;', ...
    '- survives bounded prior/sensitivity sweeps;', ...
    '- improves held-out data such as selected dV/dI linecuts;', ...
    '- exceeds disorder and Raman-registration uncertainty.'};
text(axText, 0.02, 0.78, strjoin(ruleLines, lineBreak), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'Color', 'k', 'Interpreter', 'none', 'FontSize', 10);

fieldLines = { ...
    'Magnetic-field rasters are diagnostic only in v7.6.', ...
    'They should not enter the core score until phase/flux physics is added.'};
text(axText, 0.02, 0.18, strjoin(fieldLines, lineBreak), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontAngle', 'italic', 'Color', [0.20 0.20 0.20], ...
    'Interpreter', 'none', 'FontSize', 10);

title(tl, 'v7.6 multi-observable scoring: fit curves, then test why', ...
    'Color', 'k', 'FontWeight', 'bold');
apply_light_figure_style_safe(h, tl);

end

function T = make_default_score_template()
component = {'R(T) chi2'; 'Tonset/Rlow/breadth'; 'probe asymmetry'; ...
    'dV/dI linecuts'; 'complexity penalty'};
weight = [1.0; 0.6; 0.6; 0.4; 1.0];
active = [1; 1; 1; 1; 1];
T = table(component, weight, active);
end

function T = make_default_gate_template()
gate = {'seed robustness'; 'both probes'; 'held-out data'; ...
    'ablation Z'; 'registration uncertainty'};
required = ones(numel(gate), 1);
T = table(gate, required);
end

function labels = short_component_labels(component)
labels = cellstr(string(component));
labels = strrep(labels, 'primary_RT_chi2', 'R(T) \chi^2');
labels = strrep(labels, 'secondary_transition_metrics', 'T_{onset}, R_{low}, breadth');
labels = strrep(labels, 'probe_pair_asymmetry', 'probe asymmetry');
labels = strrep(labels, 'nonlinear_dVdI_linecuts', 'dV/dI linecuts');
labels = strrep(labels, 'complexity_penalty', 'complexity');
end

function labels = short_gate_labels(gate)
labels = cellstr(string(gate));
labels = strrep(labels, 'multi_seed_improvement', 'multi-seed');
labels = strrep(labels, 'both_probe_pairs_or_asymmetry_explained', 'both probes');
labels = strrep(labels, 'reasonable_parameter_variation', 'prior sweep');
labels = strrep(labels, 'held_out_data', 'held-out data');
labels = strrep(labels, 'ablation_Z_larger_than_noise', 'ablation Z');
labels = strrep(labels, 'registration_uncertainty_test', 'registration');
labels = strrep(labels, 'seed robustness', 'multi-seed');
labels = strrep(labels, 'both probes', 'both probes');
labels = strrep(labels, 'held-out data', 'held-out data');
labels = strrep(labels, 'ablation Z', 'ablation Z');
labels = strrep(labels, 'registration uncertainty', 'registration');
end

function includeFlag = get_score_include_flag(scoreTemplate)
if any(strcmp(scoreTemplate.Properties.VariableNames, 'includeInCoreScore'))
    includeFlag = logical(scoreTemplate.includeInCoreScore);
elseif any(strcmp(scoreTemplate.Properties.VariableNames, 'active'))
    includeFlag = logical(scoreTemplate.active);
else
    includeFlag = true(height(scoreTemplate), 1);
end
includeFlag = includeFlag(:);
end

function requiredFlag = get_gate_required_flag(gateTemplate)
if any(strcmp(gateTemplate.Properties.VariableNames, 'requiredForPhysicalClaim'))
    requiredFlag = logical(gateTemplate.requiredForPhysicalClaim);
elseif any(strcmp(gateTemplate.Properties.VariableNames, 'required'))
    requiredFlag = logical(gateTemplate.required);
else
    requiredFlag = true(height(gateTemplate), 1);
end
requiredFlag = requiredFlag(:);
end

function apply_light_figure_style_safe(h, tl)
set(h, 'Color', 'w');
if nargin > 1 && ~isempty(tl)
    try
        tl.Title.Color = 'k';
    catch
    end
end

ax = findall(h, 'Type', 'axes');
for k = 1:numel(ax)
    set(ax(k), 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.75 0.75 0.75], 'MinorGridColor', [0.85 0.85 0.85], ...
        'LineWidth', 0.9, 'Box', 'on');
    try
        ax(k).Title.Color = 'k';
        ax(k).XLabel.Color = 'k';
        ax(k).YLabel.Color = 'k';
    catch
    end
    grid(ax(k), 'on');
end

txt = findall(h, 'Type', 'text');
for k = 1:numel(txt)
    if isequal(txt(k).Color, [1 1 1]) || mean(double(txt(k).Color)) > 0.85
        txt(k).Color = 'k';
    end
end

lg = findall(h, 'Type', 'legend');
for k = 1:numel(lg)
    set(lg(k), 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.4 0.4 0.4]);
end
end
