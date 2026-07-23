%RUN_V745_AS006_BEST_MAPS_ONLY Export best-case 2D maps without rescreening.
%
% Use this after run_v745_as006_physical_bottleneck_sweep has produced the
% score CSV.  This script intentionally does not rerun the ablation sweep:
% it loads the ranking table, reconstructs the best shape-controlled and
% conductance-preserving cases, and exports only those dV/dI(B,I) maps.

clear;
clc;

projectDir = add_v745_paths();
outDir = fullfile(projectDir, 'outputs', 'v7_4_5_as006_physical_bottleneck');
scoreCsvPath = fullfile(outDir, 'AS006_v7_4_5_physical_bottleneck_scores.csv');

if exist(scoreCsvPath, 'file') ~= 2
    error(['No v7.4.5 score table found at:\n%s\n', ...
        'Run run_v745_as006_physical_bottleneck_sweep first.'], scoreCsvPath);
end

opts = make_v745_bottleneck_options();
device = opts.device;
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
expField = load_v73_experimental_field_dvdi(device);
fullFieldOpts = make_v73_field_options(expField);
mapFieldOpts = make_best_map_field_options_v745_local(fullFieldOpts, opts);
cases = make_v745_bottleneck_cases(opts);
sweepTable = readtable(scoreCsvPath);

bestShape = best_case_row_v745_local(sweepTable, "shape", "shapeScore");
bestConductance = best_case_row_v745_local(sweepTable, "conductance", "conductanceScore");

fprintf('\nRunning v7.4.5 best-map export for %s\n', device);
fprintf('Score table: %s\n', scoreCsvPath);
fprintf('Best shape case: %s\n', char(bestShape.caseName));
fprintf('Best conductance case: %s\n', char(bestConductance.caseName));
fprintf('Map grid: %d B points x %d current points\n', ...
    numel(mapFieldOpts.B_vec_T), numel(mapFieldOpts.I_vec_A));

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts); %#ok<ASGLU>

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
baseParamsUncal = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v7_4_5_physical_bottleneck_base');

[fullScaleTable, referenceFullNormalScale] = build_full_scale_table_v745_local( ...
    cases, netPDE, spec, baseParamsUncal, opts);

[fieldShape, netShape, paramsShape, weakShape, shapeScore, condScoreShape] = ...
    run_best_map_case_v745_local(bestShape, cases, netPDE, spec, ...
    baseParamsUncal, opts, fullScaleTable, referenceFullNormalScale, ...
    mapFieldOpts, expField);

[fieldConductance, netConductance, paramsConductance, weakConductance, ...
    shapeScoreConductance, condScore] = run_best_map_case_v745_local( ...
    bestConductance, cases, netPDE, spec, baseParamsUncal, opts, ...
    fullScaleTable, referenceFullNormalScale, mapFieldOpts, expField);

hShape = plot_v741_as006_field_summary(spec, fieldShape, expField, ...
    score_wrapper_v745_local(shapeScore, 'shape'));
export_chapter_figure(hShape, outDir, ...
    sprintf('AS006_v7_4_5_best_shape_%s_field_maps', char(bestShape.caseName)));

hCond = plot_v741_as006_field_summary(spec, fieldConductance, expField, ...
    score_wrapper_v745_local(condScore, 'conductance'));
export_chapter_figure(hCond, outDir, ...
    sprintf('AS006_v7_4_5_best_conductance_%s_field_maps', char(bestConductance.caseName)));

hTopo = plot_v745_best_bottleneck_maps(spec, netShape, weakShape, ...
    netConductance, weakConductance, bestShape, bestConductance);
export_chapter_figure(hTopo, outDir, 'AS006_v7_4_5_best_bottleneck_2D_maps');

save(fullfile(outDir, 'AS006_v7_4_5_best_maps_only.mat'), ...
    'spec', 'opts', 'pdeOpts', 'mapFieldOpts', 'sweepTable', ...
    'bestShape', 'bestConductance', 'fieldShape', 'fieldConductance', ...
    'netShape', 'netConductance', 'paramsShape', 'paramsConductance', ...
    'weakShape', 'weakConductance', 'shapeScore', 'condScoreShape', ...
    'shapeScoreConductance', 'condScore', 'expField');

fprintf('\nFinished v7.4.5 best-map export. Outputs written to:\n%s\n', outDir);

function opts = make_best_map_field_options_v745_local(fullOpts, sweepOpts)

opts = fullOpts;
opts.version = 'v7.4.5 best-map export';
opts.B_vec_T = linspace(min(fullOpts.B_vec_T), max(fullOpts.B_vec_T), sweepOpts.bestMapBCount);
opts.I_vec_A = linspace(min(fullOpts.I_vec_A), max(fullOpts.I_vec_A), sweepOpts.bestMapICount);

end

function row = best_case_row_v745_local(T, mode, scoreName)

rows = string(T.calibrationMode) == mode & isfinite(T.(scoreName));
if ~any(rows)
    error('No finite %s rows found for calibration mode "%s".', scoreName, mode);
end
S = sortrows(T(rows,:), scoreName);
row = S(1,:);

end

function [fullScaleTable, referenceScale] = build_full_scale_table_v745_local( ...
    cases, netPDE, spec, baseParamsUncal, opts)

topologies = strings(numel(cases), 1);
for k = 1:numel(cases)
    topologies(k) = string(cases(k).topology);
end
fullIdx = find(topologies == "combined");
if isempty(fullIdx)
    fullIdx = 1;
end

rows = repmat(struct('caseName', string(''), 'gammaW', NaN, ...
    'pW', NaN, 'normalScale', NaN), numel(fullIdx), 1);

for r = 1:numel(fullIdx)
    caseInfo = cases(fullIdx(r));
    [~, paramsFull] = build_v745_bottleneck_case(netPDE, spec, ...
        baseParamsUncal, caseInfo, opts, "shape", NaN);
    rows(r).caseName = string(caseInfo.name);
    rows(r).gammaW = caseInfo.gammaW;
    rows(r).pW = caseInfo.pW;
    rows(r).normalScale = paramsFull.normalScale;
end

fullScaleTable = struct2table(rows);
referenceScale = fullScaleTable.normalScale(1);

end

function normalScale = normal_scale_for_case_v745_local(caseInfo, fullScaleTable, referenceScale)

normalScale = referenceScale;
if isempty(fullScaleTable) || ~isfinite(caseInfo.gammaW) || ~isfinite(caseInfo.pW)
    return;
end

rows = abs(fullScaleTable.gammaW - caseInfo.gammaW) < 10 .* eps(max(1, abs(caseInfo.gammaW))) & ...
    abs(fullScaleTable.pW - caseInfo.pW) < 10 .* eps(max(1, abs(caseInfo.pW)));
if any(rows)
    normalScale = fullScaleTable.normalScale(find(rows, 1, 'first'));
end

end

function [field, netCase, paramsCase, weak, shapeScore, conductanceScore] = ...
    run_best_map_case_v745_local(row, cases, netPDE, spec, baseParamsUncal, ...
    opts, fullScaleTable, referenceScale, mapFieldOpts, expField)

caseName = string(row.caseName);
names = strings(numel(cases), 1);
for k = 1:numel(cases)
    names(k) = string(cases(k).name);
end
idx = find(names == caseName, 1, 'first');
if isempty(idx)
    error('Could not find v7.4.5 case "%s".', caseName);
end

caseInfo = cases(idx);
mode = string(row.calibrationMode);
normalScaleForMode = NaN;
if mode == "conductance"
    normalScaleForMode = normal_scale_for_case_v745_local(caseInfo, ...
        fullScaleTable, referenceScale);
end

[netCase, paramsCase, weak] = build_v745_bottleneck_case(netPDE, spec, ...
    baseParamsUncal, caseInfo, opts, mode, normalScaleForMode);
field = solve_v741_field_dvdi_map(netCase, spec, paramsCase, mapFieldOpts, weak);
field.version = sprintf('v7.4.5 %s best-map', mode);
shapeScore = compute_v742_weaklink_feature_score(field, expField, opts.shapeScore);
conductanceScore = compute_v745_conductance_score(field, expField, opts.conductanceScore);

end

function s = score_wrapper_v745_local(score, label)

s = struct();
s.available = score.available;
s.combined = score.combined;
s.message = sprintf('v7.4.5 %s score', label);

end

function h = plot_v745_best_bottleneck_maps(spec, netShape, weakShape, ...
    netConductance, weakConductance, bestShape, bestConductance)

h = figure('Name', 'v7.4.5 best bottleneck 2D maps', ...
    'Color', 'w', 'Position', [120 120 1300 720]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_node_map_v745(netShape, weakShape.nodeMap);
title(sprintf('shape case W_{ij}: %s', char(bestShape.topology)));

nexttile;
plot_node_map_v745(netShape, weakShape.scoreMap);
title('shape bottleneck score');

nexttile;
plot_node_map_v745(netShape, weakShape.nodeMap > 0);
title('shape selected weak links');

nexttile;
plot_node_map_v745(netConductance, weakConductance.nodeMap);
title(sprintf('conductance case W_{ij}: %s', char(bestConductance.topology)));

nexttile;
plot_node_map_v745(netConductance, weakConductance.scoreMap);
title('conductance bottleneck score');

nexttile;
plot_node_map_v745(netConductance, weakConductance.nodeMap > 0);
title('conductance selected weak links');

sgtitle(sprintf('v7.4.5 %s best physical-bottleneck 2D maps', spec.name), ...
    'FontWeight', 'bold');

end

function plot_node_map_v745(net, Z)

imagesc(net.x_um, net.y_um, Z);
set(gca, 'YDir', 'normal');
xlabel('x [\mum]');
ylabel('y [\mum]');
axis image;
colorbar;
grid on; box on;

end
