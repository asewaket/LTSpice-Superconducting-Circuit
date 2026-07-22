function outputs = run_v71_device_pde_scaffold(device)
%RUN_V71_DEVICE_PDE_SCAFFOLD Device-general v7.1 PDE-informed scaffold.
%
% Usage:
%   run_v71_device_pde_scaffold('AS002')
%   run_v71_device_pde_scaffold('AS005')
%   run_v71_device_pde_scaffold('AS006')
%
% This function generalizes the original AS006-only v7.1 workflow. It builds
% the simplified Hall-bar network, solves the PDE mechanical proxy, maps the
% PDE/contact fields onto the resistor network, computes four-probe R(T), and
% exports both the main scaffold figure and top/bottom asymmetry diagnostic.

if nargin < 1 || isempty(device)
    device = 'AS006';
end
device = upper(char(device));

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'v7_1_device_pde_scaffold', device);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

spec = make_device_spec(device);
modelParams = make_shared_model_params();
opts = make_v7_pde_options(spec);

fprintf('\nRunning v7.1 PDE-informed scaffold for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, opts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, modelParams, pde, opts);

seed = spec.randomSeed + opts.transport.seedOffset;
params = assign_link_parameters(netPDE, spec, modelParams, seed, 'v7_pde');
params = calibrate_normal_resistance(netPDE, spec, params);
result = solve_rt_sweep(netPDE, spec, params, opts.transport.T_vec, opts.transport.Iprobe);

expData = load_experimental_rt(device);
scoreInfo = score_v71_pde_rt_result(result, expData);
asymmetry = compute_v71_asymmetry_diagnostics(result, expData);

fprintf('v7.1 PDE-informed %s combined score: %.4g\n', device, scoreInfo.combinedScore);
fprintf('  metric score: %.4g\n', scoreInfo.metricScore);
fprintf('  shape score:  %.4g\n', scoreInfo.shapeScore);
fprintf('  model pair:   %s\n', scoreInfo.modelPair);
fprintf('v7.1 %s asymmetry diagnostic, Delta r = bottom_3_9 - top_4_10:\n', device);
fprintf('  model Delta r RMS:      %.4g\n', asymmetry.summary.modelDeltaRms);
fprintf('  experiment Delta r RMS: %.4g\n', asymmetry.summary.expDeltaRms);
fprintf('  Delta r mismatch RMS:   %.4g\n', asymmetry.summary.deltaMismatchRms);
if asymmetry.summary.asymmetryFailureFlag
    warning(['Model top/bottom asymmetry is nearly zero while experiment is asymmetric. ', ...
        'This flags missing lateral transport asymmetry in the v7.1 scaffold.']);
end

h = plot_v71_device_pde_summary(spec, netPDE, pde, pdeMap, result, expData, scoreInfo);
export_chapter_figure(h, outDir, sprintf('%s_v7_1_PDE_scaffold_summary', device));

hAsym = plot_v71_device_asymmetry_diagnostics(spec, asymmetry, expData);
export_chapter_figure(hAsym, outDir, sprintf('%s_v7_1_top_bottom_asymmetry', device));

summary = struct();
summary.device = device;
summary.version = 'v7.1';
summary.scoreInfo = scoreInfo;
summary.filmForce_Npm = spec.filmForce_Npm;
summary.filmForceLabel = spec.filmForceLabel;
summary.pdeForceAmplitude = pde.forceAmplitude;
summary.pdeAppliedTraction = pde.appliedTraction;
summary.meanEta = mean(netPDE.etaNode(netPDE.active), 'omitnan');
summary.maxEta = max(netPDE.etaNode(netPDE.active), [], 'omitnan');
summary.meanContactRelaxation = mean(pdeMap.contactRelaxationMask(netPDE.active), 'omitnan');
summary.probeOverlap = netPDE.probeOverlap;
summary.asymmetry = asymmetry.summary;

Tsummary = struct2table(flatten_v71_score_summary(summary));
writetable(Tsummary, fullfile(outDir, sprintf('%s_v7_1_PDE_scaffold_summary.csv', device)));
writetable(struct2table(asymmetry.summary), ...
    fullfile(outDir, sprintf('%s_v7_1_asymmetry_summary.csv', device)));
writetable(asymmetry.curves, ...
    fullfile(outDir, sprintf('%s_v7_1_asymmetry_curves.csv', device)));

save(fullfile(outDir, sprintf('%s_v7_1_PDE_scaffold.mat', device)), ...
    'spec', 'modelParams', 'opts', 'netGeometry', 'netPDE', 'pde', ...
    'pdeMap', 'params', 'result', 'expData', 'scoreInfo', ...
    'asymmetry', 'summary');

outputs = struct();
outputs.spec = spec;
outputs.modelParams = modelParams;
outputs.opts = opts;
outputs.netGeometry = netGeometry;
outputs.netPDE = netPDE;
outputs.pde = pde;
outputs.pdeMap = pdeMap;
outputs.params = params;
outputs.result = result;
outputs.expData = expData;
outputs.scoreInfo = scoreInfo;
outputs.asymmetry = asymmetry;
outputs.summary = summary;
outputs.outDir = outDir;

fprintf('\nFinished v7.1 %s PDE scaffold.\n', device);
fprintf('Outputs written to:\n%s\n', outDir);

end

function scoreInfo = score_v71_pde_rt_result(result, expData)

metricOpts = make_metric_options();
scoreOpts = make_raman_hybrid_options();
scoreOpts = ensure_v71_combined_score_options(scoreOpts);

scoreInfo = struct();
scoreInfo.metricScore = NaN;
scoreInfo.shapeScore = NaN;
scoreInfo.combinedScore = NaN;
scoreInfo.modelPair = '';

if ~expData.available || ~isfield(expData.R, 'main_4p')
    warning('No experimental main_4p curve available for PDE score.');
    return;
end

modelPair = expData.modelPair;
if ~isfield(result.R4p, modelPair)
    names = fieldnames(result.R4p);
    modelPair = names{1};
end

expMetrics = compute_rt_curve_metrics(expData.T, expData.R.main_4p, metricOpts);
modelMetrics = compute_rt_curve_metrics(result.T, result.R4p.(modelPair), metricOpts);
metricScore = score_rt_metric_agreement(expMetrics, modelMetrics, scoreOpts);
shapeScore = compute_rt_shape_score(expData.T, expData.R.main_4p, ...
    result.T, result.R4p.(modelPair));
combinedScore = combine_raman_scores(metricScore, shapeScore, scoreOpts);

scoreInfo.modelPair = modelPair;
scoreInfo.metricScore = metricScore;
scoreInfo.shapeScore = shapeScore;
scoreInfo.combinedScore = combinedScore;
scoreInfo.expMetrics = expMetrics;
scoreInfo.modelMetrics = modelMetrics;

runForPairs = struct();
runForPairs.result = result;
scoreInfo.pairScores = compute_probe_pair_scores(expData, runForPairs, metricOpts, scoreOpts);

end

function opts = ensure_v71_combined_score_options(opts)

if ~isfield(opts, 'combinedScore') || ~isstruct(opts.combinedScore)
    opts.combinedScore = struct();
end
if ~isfield(opts.combinedScore, 'metricWeight') || isempty(opts.combinedScore.metricWeight)
    opts.combinedScore.metricWeight = 1.0;
end
if ~isfield(opts.combinedScore, 'shapeWeight') || isempty(opts.combinedScore.shapeWeight)
    opts.combinedScore.shapeWeight = 1.0;
end

end

function T = flatten_v71_score_summary(summary)

T = struct();
T.device = string(summary.device);
T.version = string(summary.version);
T.combinedScore = summary.scoreInfo.combinedScore;
T.metricScore = summary.scoreInfo.metricScore;
T.shapeScore = summary.scoreInfo.shapeScore;
T.modelPair = string(summary.scoreInfo.modelPair);
T.filmForce_Npm = summary.filmForce_Npm;
T.filmForceLabel = string(summary.filmForceLabel);
T.pdeForceAmplitude = summary.pdeForceAmplitude;
T.pdeAppliedTraction = summary.pdeAppliedTraction;
T.meanEta = summary.meanEta;
T.maxEta = summary.maxEta;
T.meanContactRelaxation = summary.meanContactRelaxation;
if isfield(summary, 'probeOverlap')
    probeNames = fieldnames(summary.probeOverlap);
    for k = 1:numel(probeNames)
        name = probeNames{k};
        S = summary.probeOverlap.(name);
        T.([name '_activeProbeNodes']) = S.activeNodes;
        T.([name '_nominalProbeNodes']) = S.nominalNodes;
        T.([name '_activeProbeFraction']) = S.activeFraction;
    end
end
if isfield(summary.scoreInfo, 'pairScores')
    pairs = {'top_4_10','bottom_3_9'};
    for k = 1:numel(pairs)
        pairName = pairs{k};
        if isfield(summary.scoreInfo.pairScores, pairName)
            S = summary.scoreInfo.pairScores.(pairName);
            T.([pairName '_available']) = logical(S.available);
            T.([pairName '_combinedScore']) = S.combinedScore;
            T.([pairName '_metricScore']) = S.metricScore;
            T.([pairName '_shapeScore']) = S.shapeScore;
            T.([pairName '_exp_rLow']) = S.exp_rLow;
            T.([pairName '_model_rLow']) = S.model_rLow;
        end
    end
end
if isfield(summary, 'asymmetry')
    A = summary.asymmetry;
    T.asym_experimentAvailable = logical(A.experimentAvailable);
    T.asym_modelDeltaRms = A.modelDeltaRms;
    T.asym_modelDeltaMaxAbs = A.modelDeltaMaxAbs;
    T.asym_expDeltaRms = A.expDeltaRms;
    T.asym_expDeltaMaxAbs = A.expDeltaMaxAbs;
    T.asym_deltaMismatchRms = A.deltaMismatchRms;
    T.asym_deltaMismatchMaxAbs = A.deltaMismatchMaxAbs;
    T.asym_modelToExperimentDeltaRmsRatio = A.modelToExperimentDeltaRmsRatio;
    T.asymmetryFailureFlag = logical(A.asymmetryFailureFlag);
end

end
