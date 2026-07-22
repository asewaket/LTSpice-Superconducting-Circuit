%RUN_V742_AS006_WEAKLINK_ABLATION_SWEEP Focused weak-link ablation sweep.
%
% v7.4.2 asks a narrower question than v7.4.1:
%   Which weak-link geometry/strength assumption best addresses the low-bias
%   AS006 dV/dI(I,B) feature?
%
% The sweep screens named weak-link hypotheses on selected B slices using a
% low-bias-weighted score. It then runs the full v7.4.1-style field map for
% the best case only.

clear;
clc;

projectDir = add_v742_paths();

outDir = fullfile(projectDir, 'outputs', 'v7_4_2_as006_weaklink_ablation');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

device = 'AS006';
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
expField = load_v73_experimental_field_dvdi(device);
fullFieldOpts = make_v73_field_options(expField);
fullFieldOpts.version = 'v7.4.2';
screenFieldOpts = make_screening_field_options(fullFieldOpts, expField);
featureScoreOpts = make_feature_score_options();
cases = make_v742_weaklink_ablation_cases(spec);

fprintf('\nRunning v7.4.2 focused weak-link ablation sweep for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);
fprintf('Screening cases: %d\n', numel(cases));
fprintf('Screening B points: %d, current points: %d\n', ...
    numel(screenFieldOpts.B_vec_T), numel(screenFieldOpts.I_vec_A));
fprintf('Final best-case map B points: %d, current points: %d\n', ...
    numel(fullFieldOpts.B_vec_T), numel(fullFieldOpts.I_vec_A));

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
baseParams = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v7_4_2_pde_field_weaklink_ablation');
baseParams = calibrate_normal_resistance(netPDE, spec, baseParams);

sweepRows = repmat(empty_row(), numel(cases), 1);

for k = 1:numel(cases)
    caseInfo = cases(k);
    weakOpts = caseInfo.opts;
    fprintf('\nCase %d/%d: %s\n', k, numel(cases), weakOpts.caseName);
    fprintf('  fraction %.3g, Ic mult %.3g, dI/Ic %.3g\n', ...
        weakOpts.randomWeakFraction, weakOpts.IcMultiplier, ...
        weakOpts.weakSwitchWidthFrac);

    params = baseParams;
    [params, weak] = apply_v741_weaklink_bottlenecks(params, netPDE, spec, weakOpts);
    fieldScreen = solve_v741_field_dvdi_map(netPDE, spec, params, ...
        screenFieldOpts, weak);
    fieldScreen.version = 'v7.4.2 screening';
    featureScore = compute_v742_weaklink_feature_score(fieldScreen, ...
        expField, featureScoreOpts);
    fullMapScore = compute_v73_field_score(fieldScreen, expField);

    sweepRows(k) = make_sweep_row(spec, weakOpts, weak, featureScore, fullMapScore);
    fprintf('  feature score %.4g, v7.3-style score %.4g\n', ...
        sweepRows(k).featureScore, sweepRows(k).fieldScoreCombined);
end

sweepTable = struct2table(sweepRows);
sweepTable = sortrows(sweepTable, 'featureScore', 'ascend');
writetable(sweepTable, fullfile(outDir, 'AS006_v7_4_2_weaklink_ablation_scores.csv'));

hSweep = plot_v742_weaklink_ablation_summary(sweepTable);
export_chapter_figure(hSweep, outDir, 'AS006_v7_4_2_weaklink_ablation_summary');

bestName = string(sweepTable.caseName(1));
caseNames = strings(numel(cases), 1);
for k = 1:numel(cases)
    caseNames(k) = cases(k).name;
end
bestIdx = find(caseNames == bestName, 1, 'first');
if isempty(bestIdx)
    bestIdx = 1;
end
bestWeakOpts = cases(bestIdx).opts;

fprintf('\nRunning full field map for best v7.4.2 case: %s\n', bestWeakOpts.caseName);
paramsBest = baseParams;
[paramsBest, weakBest] = apply_v741_weaklink_bottlenecks(paramsBest, netPDE, ...
    spec, bestWeakOpts);
fieldBest = solve_v741_field_dvdi_map(netPDE, spec, paramsBest, ...
    fullFieldOpts, weakBest);
fieldBest.version = 'v7.4.2';
fieldScoreBest = compute_v73_field_score(fieldBest, expField);
featureScoreBest = compute_v742_weaklink_feature_score(fieldBest, ...
    expField, featureScoreOpts);

hField = plot_v741_as006_field_summary(spec, fieldBest, expField, fieldScoreBest);
export_chapter_figure(hField, outDir, ...
    sprintf('AS006_v7_4_2_best_%s_field_dVdI_maps', bestWeakOpts.caseName));

hWeak = plot_v741_weaklink_diagnostics(spec, netPDE, weakBest, paramsBest);
export_chapter_figure(hWeak, outDir, ...
    sprintf('AS006_v7_4_2_best_%s_weaklink_diagnostics', bestWeakOpts.caseName));

save(fullfile(outDir, 'AS006_v7_4_2_weaklink_ablation.mat'), ...
    'spec', 'modelParams', 'pdeOpts', 'fullFieldOpts', 'screenFieldOpts', ...
    'featureScoreOpts', 'cases', 'netGeometry', 'netPDE', 'pde', 'pdeMap', ...
    'baseParams', 'sweepTable', 'bestWeakOpts', 'paramsBest', 'weakBest', ...
    'fieldBest', 'expField', 'fieldScoreBest', 'featureScoreBest');

fprintf('\nFinished v7.4.2 weak-link ablation sweep.\n');
fprintf('Best case: %s\n', bestWeakOpts.caseName);
fprintf('Best screening feature score: %.4g\n', sweepTable.featureScore(1));
fprintf('Best full-map v7.3-style field score: %.4g\n', fieldScoreBest.combined);
fprintf('Best full-map v7.4.2 feature score: %.4g\n', featureScoreBest.combined);
fprintf('Outputs written to:\n%s\n', outDir);

function opts = make_screening_field_options(fullOpts, expField)

opts = fullOpts;
opts.version = 'v7.4.2 screening';
if isfield(expField, 'available') && expField.available
    bmin = max(min(fullOpts.B_vec_T), min(expField.B_T));
    bmax = min(max(fullOpts.B_vec_T), max(expField.B_T));
else
    bmin = min(fullOpts.B_vec_T);
    bmax = max(fullOpts.B_vec_T);
end
opts.B_vec_T = linspace(bmin, bmax, 9);
opts.I_vec_A = fullOpts.I_vec_A;

end

function opts = make_feature_score_options()

opts = struct();
opts.lowBiasWindow_A = 0.35e-6;
opts.weights.fullMap = 0.20;
opts.weights.lowBiasMap = 0.35;
opts.weights.zeroBiasField = 0.25;
opts.weights.topBottomAsymmetry = 0.20;

end

function row = empty_row()

row = struct();
row.device = string('');
row.caseName = string('');
row.description = string('');
row.weakFraction = NaN;
row.activeWeakLinkFraction = NaN;
row.IcMultiplier = NaN;
row.switchWidthFrac = NaN;
row.currentBroadening_A = NaN;
row.boundaryWeight = NaN;
row.coveredEdgeWeight = NaN;
row.numHotspots = NaN;
row.hotspotRadius_um = NaN;
row.featureScore = NaN;
row.fullMapScore = NaN;
row.lowBiasScore = NaN;
row.zeroBiasScore = NaN;
row.asymmetryScore = NaN;
row.fieldScoreCombined = NaN;

end

function row = make_sweep_row(spec, weakOpts, weak, featureScore, fullMapScore)

row = empty_row();
row.device = string(spec.name);
row.caseName = string(weakOpts.caseName);
row.description = string(weakOpts.description);
row.weakFraction = weakOpts.randomWeakFraction;
row.activeWeakLinkFraction = weak.activeLinkFraction;
row.IcMultiplier = weakOpts.IcMultiplier;
row.switchWidthFrac = weakOpts.weakSwitchWidthFrac;
row.currentBroadening_A = weakOpts.currentBroadening_A;
row.boundaryWeight = weakOpts.boundaryWeight;
row.coveredEdgeWeight = weakOpts.coveredEdgeWeight;
row.numHotspots = weakOpts.numHotspots;
row.hotspotRadius_um = weakOpts.hotspotRadius_um;

row.featureScore = featureScore.combined;
row.fullMapScore = mean_pair_component(featureScore.fullMapRms);
row.lowBiasScore = mean_pair_component(featureScore.lowBiasRms);
row.zeroBiasScore = mean_pair_component(featureScore.zeroBiasRms);
row.asymmetryScore = featureScore.asymmetryRms;

if isfield(fullMapScore, 'available') && fullMapScore.available
    row.fieldScoreCombined = fullMapScore.combined;
end

end

function val = mean_pair_component(s)

vals = [];
names = fieldnames(s);
for k = 1:numel(names)
    vals(end+1) = s.(names{k}); %#ok<AGROW>
end
if isempty(vals)
    val = NaN;
else
    val = mean(vals, 'omitnan');
end

end
