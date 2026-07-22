%RUN_V743_AS006_WIJ_ABLATION_SWEEP Controlled W_ij weak-link ablation.
%
% v7.4.3 keeps geometry, PDE/Raman proxy, Tc field, disorder realization,
% field/current grid, probe mapping, and normal-state reference controlled.
% Only weak-link transparency W_ij is varied.

clear;
clc;

projectDir = add_v743_paths();
outDir = fullfile(projectDir, 'outputs', 'v7_4_3_as006_wij_ablation');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

opts = make_v743_wij_ablation_options();
device = opts.device;
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
expField = load_v73_experimental_field_dvdi(device);
fullFieldOpts = make_v73_field_options(expField);
fullFieldOpts.version = opts.version;
screenFieldOpts = make_screening_field_options_v743(fullFieldOpts, expField, opts);
cases = make_v743_wij_ablation_cases(opts);
scoreCsvPath = fullfile(outDir, 'AS006_v7_4_3_wij_ablation_scores.csv');

fprintf('\nRunning v7.4.3 controlled W_ij ablation sweep for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);
fprintf('Cases: %d W_ij topologies/parameter combinations\n', numel(cases));
fprintf('gammaW values: %s\n', mat2str(opts.gammaW_values));
fprintf('pW values: %s\n', mat2str(opts.pW_values));
fprintf('Screening B points: %d, current points: %d\n', ...
    numel(screenFieldOpts.B_vec_T), numel(screenFieldOpts.I_vec_A));

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
baseParamsUncal = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v7_4_3_controlled_wij_base');

[fullScaleTable, fullReference, paramsFullRef, weakFullRef] = ...
    build_full_scale_table_v743(cases, netPDE, spec, baseParamsUncal, opts);
referenceFullNormalScale = paramsFullRef.normalScale;
fprintf('Reference full-model normal-state calibration scale: %.4g\n', ...
    referenceFullNormalScale);
fprintf('Conductance-preserving ablations use the full-model scale from the same gammaW/pW family.\n');

expectedRows = 2 .* numel(cases);
sweepTable = table();
if opts.reuseExistingScreeningTable && exist(scoreCsvPath, 'file') == 2
    candidateTable = readtable(scoreCsvPath);
    if height(candidateTable) == expectedRows
        fprintf('Reusing existing screening score table:\n%s\n', scoreCsvPath);
        sweepTable = candidateTable;
    else
        fprintf('Existing screening score table has %d rows, expected %d; recomputing.\n', ...
            height(candidateTable), expectedRows);
    end
end

if isempty(sweepTable)
    sweepRows = repmat(empty_row_v743(), expectedRows, 1);
    rowIdx = 0;

    for k = 1:numel(cases)
        caseInfo = cases(k);
        for mode = ["shape","conductance"]
            rowIdx = rowIdx + 1;
            fprintf('\nCase %d/%d, %s calibration: %s\n', ...
                k, numel(cases), char(mode), char(caseInfo.name));

            normalScaleForMode = NaN;
            if mode == "conductance"
                normalScaleForMode = normal_scale_for_case_v743(caseInfo, ...
                    fullScaleTable, referenceFullNormalScale);
            end
            [netCase, paramsCase, weak] = build_v743_wij_case(netPDE, spec, ...
                baseParamsUncal, caseInfo, opts, mode, normalScaleForMode);
            fieldScreen = solve_v741_field_dvdi_map(netCase, spec, paramsCase, ...
                screenFieldOpts, weak);
            fieldScreen.version = sprintf('v7.4.3 %s screening', mode);

            shapeScore = compute_v742_weaklink_feature_score(fieldScreen, ...
                expField, opts.shapeScore);
            conductanceScore = compute_v743_conductance_score(fieldScreen, ...
                expField, opts.conductanceScore);

            sweepRows(rowIdx) = make_sweep_row_v743(spec, caseInfo, weak, ...
                mode, shapeScore, conductanceScore);
        end
    end

    sweepTable = struct2table(sweepRows);
    sweepTable = sortrows(sweepTable, {'calibrationMode','shapeScore'});
    writetable(sweepTable, scoreCsvPath);
else
    sweepTable = sortrows(sweepTable, {'calibrationMode','shapeScore'});
end

hSweep = plot_v743_wij_ablation_summary(sweepTable);
export_chapter_figure(hSweep, outDir, 'AS006_v7_4_3_wij_ablation_summary');

bestShape = best_case_row(sweepTable, "shape", "shapeScore");
bestConductance = best_case_row(sweepTable, "conductance", "conductanceScore");

fprintf('\nRunning full field maps for best shape and conductance cases.\n');
[fieldBestShape, netBestShape, paramsBestShape, weakBestShape, shapeScoreFull, condScoreShapeFull] = ...
    run_full_case(bestShape, cases, netPDE, spec, baseParamsUncal, opts, ...
    fullScaleTable, referenceFullNormalScale, fullFieldOpts, expField);
[fieldBestConductance, netBestConductance, paramsBestConductance, weakBestConductance, shapeScoreCondFull, condScoreFull] = ...
    run_full_case(bestConductance, cases, netPDE, spec, baseParamsUncal, opts, ...
    fullScaleTable, referenceFullNormalScale, fullFieldOpts, expField);

hShape = plot_v741_as006_field_summary(spec, fieldBestShape, expField, ...
    score_wrapper(shapeScoreFull, 'shape'));
export_chapter_figure(hShape, outDir, ...
    sprintf('AS006_v7_4_3_best_shape_%s_field_maps', char(bestShape.caseName)));

hCond = plot_v741_as006_field_summary(spec, fieldBestConductance, expField, ...
    score_wrapper(condScoreFull, 'conductance'));
export_chapter_figure(hCond, outDir, ...
    sprintf('AS006_v7_4_3_best_conductance_%s_field_maps', char(bestConductance.caseName)));

save(fullfile(outDir, 'AS006_v7_4_3_wij_ablation.mat'), ...
    'spec', 'modelParams', 'pdeOpts', 'opts', 'fullFieldOpts', ...
    'screenFieldOpts', 'cases', 'netGeometry', 'netPDE', 'pde', 'pdeMap', ...
    'baseParamsUncal', 'fullReference', 'paramsFullRef', 'weakFullRef', ...
    'referenceFullNormalScale', 'fullScaleTable', 'sweepTable', ...
    'bestShape', 'bestConductance', ...
    'fieldBestShape', 'netBestShape', 'paramsBestShape', 'weakBestShape', ...
    'fieldBestConductance', 'netBestConductance', 'paramsBestConductance', ...
    'weakBestConductance', 'shapeScoreFull', 'condScoreShapeFull', ...
    'shapeScoreCondFull', 'condScoreFull', 'expField');

fprintf('\nFinished v7.4.3 controlled W_ij ablation.\n');
fprintf('Best shape-controlled case: %s, shape score %.4g, conductance score %.4g\n', ...
    char(bestShape.caseName), bestShape.shapeScore, bestShape.conductanceScore);
fprintf('Best conductance-preserving case: %s, shape score %.4g, conductance score %.4g\n', ...
    char(bestConductance.caseName), bestConductance.shapeScore, bestConductance.conductanceScore);
fprintf('Outputs written to:\n%s\n', outDir);

function opts = make_screening_field_options_v743(fullOpts, expField, sweepOpts)

opts = fullOpts;
opts.version = 'v7.4.3 screening';
if isfield(expField, 'available') && expField.available
    bmin = max(min(fullOpts.B_vec_T), min(expField.B_T));
    bmax = min(max(fullOpts.B_vec_T), max(expField.B_T));
else
    bmin = min(fullOpts.B_vec_T);
    bmax = max(fullOpts.B_vec_T);
end
opts.B_vec_T = linspace(bmin, bmax, sweepOpts.screenBCount);
opts.I_vec_A = fullOpts.I_vec_A;

end

function caseInfo = first_full_reference_case(cases)

topologies = strings(numel(cases), 1);
for k = 1:numel(cases)
    topologies(k) = string(cases(k).topology);
end
idx = find(topologies == "full", 1, 'first');
if isempty(idx)
    idx = 1;
end
caseInfo = cases(idx);

end

function [fullScaleTable, fullReference, paramsFullRef, weakFullRef] = ...
    build_full_scale_table_v743(cases, netPDE, spec, baseParamsUncal, opts)

topologies = strings(numel(cases), 1);
for k = 1:numel(cases)
    topologies(k) = string(cases(k).topology);
end
fullIdx = find(topologies == "full");
if isempty(fullIdx)
    fullReference = cases(1);
    [~, paramsFullRef, weakFullRef] = build_v743_wij_case(netPDE, spec, ...
        baseParamsUncal, fullReference, opts, "shape", NaN);
    fullScaleTable = table(string(fullReference.name), fullReference.gammaW, ...
        fullReference.pW, paramsFullRef.normalScale, ...
        'VariableNames', {'caseName','gammaW','pW','normalScale'});
    return;
end

rows = repmat(struct('caseName', string(''), 'gammaW', NaN, ...
    'pW', NaN, 'normalScale', NaN), numel(fullIdx), 1);
paramsFullRef = [];
weakFullRef = [];
fullReference = cases(fullIdx(1));

for r = 1:numel(fullIdx)
    caseInfo = cases(fullIdx(r));
    [~, paramsFull, weakFull] = build_v743_wij_case(netPDE, spec, ...
        baseParamsUncal, caseInfo, opts, "shape", NaN);
    rows(r).caseName = string(caseInfo.name);
    rows(r).gammaW = caseInfo.gammaW;
    rows(r).pW = caseInfo.pW;
    rows(r).normalScale = paramsFull.normalScale;
    if r == 1
        paramsFullRef = paramsFull;
        weakFullRef = weakFull;
    end
end

fullScaleTable = struct2table(rows);

end

function normalScale = normal_scale_for_case_v743(caseInfo, fullScaleTable, referenceScale)

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

function row = empty_row_v743()

row = struct();
row.device = string('');
row.caseName = string('');
row.description = string('');
row.topology = string('');
row.calibrationMode = string('');
row.gammaW = NaN;
row.pW = NaN;
row.meanW = NaN;
row.minW = NaN;
row.activeWeakLinkFraction = NaN;
row.normalScaleApplied = NaN;
row.shapeScore = NaN;
row.shapeFullMap = NaN;
row.shapeLowBias = NaN;
row.shapeZeroBias = NaN;
row.shapeAsymmetry = NaN;
row.conductanceScore = NaN;
row.conductanceFullMap = NaN;
row.conductanceLowBias = NaN;
row.conductanceZeroBias = NaN;
row.conductanceAsymmetry = NaN;
row.modelRN_top_4_10 = NaN;
row.modelRN_bottom_3_9 = NaN;

end

function row = make_sweep_row_v743(spec, caseInfo, weak, mode, shapeScore, conductanceScore)

row = empty_row_v743();
row.device = string(spec.name);
row.caseName = string(caseInfo.name);
row.description = string(caseInfo.description);
row.topology = string(caseInfo.topology);
row.calibrationMode = string(mode);
row.gammaW = caseInfo.gammaW;
row.pW = caseInfo.pW;
row.meanW = weak.meanW;
if isfield(weak, 'minW')
    row.minW = weak.minW;
end
row.activeWeakLinkFraction = weak.activeLinkFraction;
row.normalScaleApplied = weak.normalScaleApplied;

row.shapeScore = shapeScore.combined;
row.shapeFullMap = mean_pair_component_v743(shapeScore.fullMapRms);
row.shapeLowBias = mean_pair_component_v743(shapeScore.lowBiasRms);
row.shapeZeroBias = mean_pair_component_v743(shapeScore.zeroBiasRms);
row.shapeAsymmetry = shapeScore.asymmetryRms;

row.conductanceScore = conductanceScore.combined;
row.conductanceFullMap = mean_pair_component_v743(conductanceScore.fullMapRms);
row.conductanceLowBias = mean_pair_component_v743(conductanceScore.lowBiasRms);
row.conductanceZeroBias = mean_pair_component_v743(conductanceScore.zeroBiasRms);
row.conductanceAsymmetry = conductanceScore.asymmetryRms;
if isfield(conductanceScore, 'modelRN')
    if isfield(conductanceScore.modelRN, 'top_4_10')
        row.modelRN_top_4_10 = conductanceScore.modelRN.top_4_10;
    end
    if isfield(conductanceScore.modelRN, 'bottom_3_9')
        row.modelRN_bottom_3_9 = conductanceScore.modelRN.bottom_3_9;
    end
end

end

function val = mean_pair_component_v743(s)

vals = [];
names = fieldnames(s);
for k = 1:numel(names)
    vals(end+1) = s.(names{k}); %#ok<AGROW>
end
if isempty(vals)
    val = NaN;
else
    vals = vals(isfinite(vals));
    if isempty(vals)
        val = NaN;
    else
        val = mean(vals);
    end
end

end

function row = best_case_row(T, mode, scoreName)

rows = string(T.calibrationMode) == mode & isfinite(T.(scoreName));
if ~any(rows)
    error('No finite %s rows found for calibration mode "%s".', scoreName, mode);
end
S = sortrows(T(rows,:), scoreName);
row = S(1,:);

end

function [field, netCase, paramsCase, weak, shapeScore, conductanceScore] = ...
    run_full_case(row, cases, netPDE, spec, baseParamsUncal, opts, ...
    fullScaleTable, referenceFullNormalScale, fullFieldOpts, expField)

caseName = string(row.caseName);
names = strings(numel(cases), 1);
for k = 1:numel(cases)
    names(k) = string(cases(k).name);
end
idx = find(names == caseName, 1, 'first');
if isempty(idx)
    error('Could not find v7.4.3 case "%s".', caseName);
end
caseInfo = cases(idx);
mode = string(row.calibrationMode);
normalScaleForMode = NaN;
if mode == "conductance"
    normalScaleForMode = normal_scale_for_case_v743(caseInfo, ...
        fullScaleTable, referenceFullNormalScale);
end
[netCase, paramsCase, weak] = build_v743_wij_case(netPDE, spec, ...
    baseParamsUncal, caseInfo, opts, mode, normalScaleForMode);
field = solve_v741_field_dvdi_map(netCase, spec, paramsCase, fullFieldOpts, weak);
field.version = sprintf('v7.4.3 %s full', mode);
shapeScore = compute_v742_weaklink_feature_score(field, expField, opts.shapeScore);
conductanceScore = compute_v743_conductance_score(field, expField, opts.conductanceScore);

end

function s = score_wrapper(score, label)

s = struct();
s.available = score.available;
s.combined = score.combined;
s.message = sprintf('v7.4.3 %s score', label);

end
