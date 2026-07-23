%RUN_AS005_CASEB_WEAKLINK_SWEEP v6.6 focused AS005 Case B diagnostic.
%
% Case B was the first physics-informed case to produce source-drain
% percolation in AS005. This script asks which part of that hypothesis matters:
% weak-link residual suppression, Ic enhancement, small Tc gain, or Raman
% interpolation width.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'as005_caseB_weaklink_sweep');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

model = make_shared_model_params();
opts = make_physics_case_options();
metricOpts = make_metric_options();

device = "AS005";
expData = load_experimental_rt(device);
expCurveName = first_fieldname(expData.R);
expMetrics = compute_rt_curve_metrics(expData.T, expData.R.(expCurveName), metricOpts);
modelPair = expData.modelPair;

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));
registered = register_raman_scans_to_hallbar(ramanProxy, registration);

residualVec = [0.50 0.70 0.85 0.95];
icVec = [2.0 3.0 5.0];
tcVec = [0.05 0.10 0.20];
sigmaVec = [0.65 0.85 1.10];

rows = {};
bestCombined = Inf;
bestRun = [];
runID = 0;

for ir = 1:numel(residualVec)
    for ii = 1:numel(icVec)
        for itc = 1:numel(tcVec)
            for isg = 1:numel(sigmaVec)
                caseDef = get_physics_case_definition(device, 'case_B_outofplane_weaklinks');
                caseDef.residualSuppression = residualVec(ir);
                caseDef.IcMultiplier = icVec(ii);
                caseDef.TcGain_K = tcVec(itc);
                caseDef.variant.sigma_um = sigmaVec(isg);
                caseDef.variant.maxDistance_um = 3 * sigmaVec(isg);

                runID = runID + 1;
                seed = model.ensemble.seed0 + 6600 + runID;

                try
                    run = run_single_physics_case_model(device, model, opts.T_vec, ...
                        opts.Iprobe, registered, caseDef, seed, opts.percolation);
                catch ME
                    warning('Skipping run %d due to: %s', runID, ME.message);
                    continue;
                end

                if ~isfield(run.result.R4p, modelPair)
                    modelPair = first_fieldname(run.result.R4p);
                end

                modelR = run.result.R4p.(modelPair);
                modelMetrics = compute_rt_curve_metrics(run.result.T, modelR, metricOpts);
                metricScore = score_rt_metric_agreement(expMetrics, modelMetrics, opts);
                shapeScore = compute_rt_shape_score(expData.T, expData.R.(expCurveName), ...
                    run.result.T, modelR);
                combinedScore = combine_raman_scores(metricScore, shapeScore, opts);

                topMetrics = metrics_for_pair(run, 'top_4_10', metricOpts);
                bottomMetrics = metrics_for_pair(run, 'bottom_3_9', metricOpts);

                rows(end+1,:) = {runID, residualVec(ir), icVec(ii), tcVec(itc), sigmaVec(isg), ...
                    metricScore, shapeScore, combinedScore, ...
                    expMetrics.rLow, modelMetrics.rLow, topMetrics.rLow, bottomMetrics.rLow, ...
                    modelMetrics.Tonset_K, run.percolation.percolationOnset_K, ...
                    run.percolation.topProbeOnset_K, run.percolation.bottomProbeOnset_K, ...
                    run.caseInfo.domainLinkFraction}; %#ok<AGROW>

                if combinedScore < bestCombined
                    bestCombined = combinedScore;
                    bestRun = run;
                    bestRun.expData = expData;
                    bestRun.expCurveName = expCurveName;
                    bestRun.modelPair = modelPair;
                    bestRun.combinedScore = combinedScore;
                end
            end
        end
    end
end

sweepTable = cell2table(rows, 'VariableNames', { ...
    'run_id','residualSuppression','IcMultiplier','TcGain_K','sigma_um', ...
    'metricScore','shapeScore','combinedScore', ...
    'exp_rLow','model_rLow','model_top_rLow','model_bottom_rLow', ...
    'model_Tonset_K','sourceDrainPercOnset_K','topProbePercOnset_K', ...
    'bottomProbePercOnset_K','domainLinkFraction'});
sweepTable = sortrows(sweepTable, 'combinedScore');

writetable(sweepTable, fullfile(outDir, 'as005_caseB_weaklink_sweep_scores.csv'));
save(fullfile(outDir, 'as005_caseB_weaklink_sweep.mat'), ...
    'sweepTable', 'bestRun', 'opts', 'metricOpts');

h = plot_as005_caseB_weaklink_sweep(sweepTable, bestRun);
export_chapter_figure(h, outDir, 'as005_caseB_weaklink_sweep_summary');

fprintf('\nFinished AS005 Case B weak-link sweep.\n');
fprintf('Best score = %.4g\n', bestCombined);
fprintf('Wrote outputs to:\n%s\n', outDir);

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end

function metrics = metrics_for_pair(run, pairName, metricOpts)

if isfield(run.result.R4p, pairName)
    metrics = compute_rt_curve_metrics(run.result.T, run.result.R4p.(pairName), metricOpts);
else
    metrics = compute_rt_curve_metrics([], [], metricOpts);
end

end
