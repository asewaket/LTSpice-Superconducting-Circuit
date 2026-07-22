%RUN_PHYSICS_INFORMED_CASE_SWEEP v6.7 literature-informed cases A--G.
%
% The cases are:
%   A: in-plane Raman channel controls local Tc
%   B: out-of-plane Raman channel controls weak-link transparency/residuals
%   C: crack-edge response controls domain nucleation
%   D: stressor-boundary lane controls percolating channel continuity
%   E: metal contacts/probes locally relax or suppress strain enhancement
%   F: interrupted boundary-lane superconductivity
%   G: weakly connected finite-transparency boundary channel

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'physics_informed_cases');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

model = make_shared_model_params();
opts = make_physics_case_options();
metricOpts = make_metric_options();

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));
registered = register_raman_scans_to_hallbar(ramanProxy, registration);

rows = {};
percRows = {};
bestRuns = struct();
rowCounter = 0;

for d = 1:numel(opts.devices)
    device = string(opts.devices{d});
    fprintf('\nDevice %s\n', device);

    expData = load_experimental_rt(device);
    if ~expData.available
        warning('Skipping %s because no experimental R(T) is available.', device);
        continue;
    end

    expCurveName = first_fieldname(expData.R);
    expMetrics = compute_rt_curve_metrics(expData.T, expData.R.(expCurveName), metricOpts);
    modelPair = expData.modelPair;

    bestCombined = Inf;
    bestRun = [];

    for icase = 1:numel(opts.caseIDs)
        caseID = opts.caseIDs{icase};
        caseDef = get_physics_case_definition(device, caseID);
        seed = model.ensemble.seed0 + 6500 + 251 * d + 31 * icase;

        try
            run = run_single_physics_case_model(device, model, opts.T_vec, ...
                opts.Iprobe, registered, caseDef, seed, opts.percolation);
        catch ME
            warning('Skipping %s / %s due to: %s', device, caseID, ME.message);
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
        pairScores = compute_probe_pair_scores(expData, run, metricOpts, opts);
        topPair = pairScores.top_4_10;
        bottomPair = pairScores.bottom_3_9;

        rowCounter = rowCounter + 1;
        rows(end+1,:) = {char(device), rowCounter, caseID, caseDef.label, ...
            caseDef.description, run.variant.modeName, run.variant.referenceName, ...
            run.variant.representationName, run.variant.couplingMode, modelPair, ...
            metricScore, shapeScore, combinedScore, ...
            topPair.available, topPair.combinedScore, topPair.metricScore, ...
            topPair.shapeScore, topPair.exp_rLow, topPair.model_rLow, ...
            bottomPair.available, bottomPair.combinedScore, bottomPair.metricScore, ...
            bottomPair.shapeScore, bottomPair.exp_rLow, bottomPair.model_rLow, ...
            expMetrics.rLow, modelMetrics.rLow, expMetrics.Tonset_K, modelMetrics.Tonset_K, ...
            expMetrics.Tmid_K, modelMetrics.Tmid_K, ...
            expMetrics.width90_10_K, modelMetrics.width90_10_K, ...
            run.caseInfo.domainLinkFraction, run.caseInfo.contactLinkFraction, ...
            run.percolation.percolationOnset_K, run.percolation.topProbeOnset_K, ...
            run.percolation.bottomProbeOnset_K}; %#ok<AGROW>

        for kT = 1:numel(run.percolation.T)
            percRows(end+1,:) = {char(device), caseID, run.percolation.T(kT), ...
                run.percolation.scLinkFraction(kT), ...
                run.percolation.largestClusterFraction(kT), ...
                run.percolation.sourceDrainConnected(kT), ...
                run.percolation.topProbeConnected(kT), ...
                run.percolation.bottomProbeConnected(kT)}; %#ok<AGROW>
        end

        if combinedScore < bestCombined
            bestCombined = combinedScore;
            bestRun = run;
            bestRun.expData = expData;
            bestRun.expCurveName = expCurveName;
            bestRun.combinedScore = combinedScore;
            bestRun.metricScore = metricScore;
            bestRun.shapeScore = shapeScore;
            bestRun.modelPair = modelPair;
            bestRun.pairScores = pairScores;
        end
    end

    bestRuns(d).device = char(device); %#ok<SAGROW>
    bestRuns(d).run = bestRun;
    bestRuns(d).expData = expData;
    bestRuns(d).bestCombinedScore = bestCombined;
    fprintf('  best v6.7 physics-informed score = %.4g\n', bestCombined);
end

caseTable = cell2table(rows, 'VariableNames', { ...
    'device','run_id','caseID','caseLabel','caseDescription', ...
    'raman_mode','reference','representation','couplingMode','modelPair', ...
    'metricScore','shapeScore','combinedScore', ...
    'topPairAvailable','topPairScore','topPairMetricScore','topPairShapeScore', ...
    'top_exp_rLow','top_model_rLow', ...
    'bottomPairAvailable','bottomPairScore','bottomPairMetricScore','bottomPairShapeScore', ...
    'bottom_exp_rLow','bottom_model_rLow', ...
    'exp_rLow','model_rLow','exp_Tonset_K','model_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K','exp_width90_10_K','model_width90_10_K', ...
    'domainLinkFraction','contactLinkFraction', ...
    'sourceDrainPercOnset_K','topProbePercOnset_K','bottomProbePercOnset_K'});
caseTable = sortrows(caseTable, {'device','combinedScore'});

percolationTable = cell2table(percRows, 'VariableNames', { ...
    'device','caseID','T_K','scLinkFraction','largestClusterFraction', ...
    'sourceDrainConnected','topProbeConnected','bottomProbeConnected'});

summaryTable = summarize_physics_case_sweep(caseTable);

writetable(caseTable, fullfile(outDir, 'physics_case_sweep_scores.csv'));
writetable(percolationTable, fullfile(outDir, 'physics_case_percolation_vs_temperature.csv'));
writetable(summaryTable, fullfile(outDir, 'physics_case_summary.csv'));
save(fullfile(outDir, 'physics_case_sweep.mat'), ...
    'caseTable', 'percolationTable', 'summaryTable', 'bestRuns', 'opts', 'metricOpts');

hSummary = plot_physics_case_summary(caseTable, summaryTable, opts);
export_chapter_figure(hSummary, outDir, 'physics_case_summary');

hRT = plot_physics_case_rt_percolation(bestRuns);
export_chapter_figure(hRT, outDir, 'physics_case_rt_percolation_comparison');

hMaps = plot_physics_case_network_maps(bestRuns);
export_chapter_figure(hMaps, outDir, 'physics_case_network_maps');

hCurrent = plot_physics_case_current_maps(bestRuns);
export_chapter_figure(hCurrent, outDir, 'physics_case_current_maps');

fprintf('\nFinished v6.7 physics-informed case sweep.\n');
fprintf('Wrote outputs to:\n%s\n', outDir);

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
