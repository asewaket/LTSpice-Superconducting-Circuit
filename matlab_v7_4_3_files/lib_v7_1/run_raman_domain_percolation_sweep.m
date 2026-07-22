%RUN_RAMAN_DOMAIN_PERCOLATION_SWEEP v6.4 Raman-domain/percolation test.
%
% This script asks whether Raman-informed spatial heterogeneity needs a
% thresholded enhanced-domain layer to explain low-temperature residual
% resistance and superconducting-network connectivity.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'domain_percolation');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

model = make_shared_model_params();
opts = make_domain_percolation_options();
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
    variantOpts = get_v64_best_variant_options(device);

    bestCombined = Inf;
    bestRun = [];

    for iv = 1:numel(opts.domainVariants)
        domainOpts = opts.domainVariants(iv);
        seed = model.ensemble.seed0 + 6400 + 200 * d + 19 * iv;

        try
            run = run_single_domain_model(device, model, opts.T_vec, opts.Iprobe, ...
                registered, variantOpts, domainOpts, seed, opts.percolation);
        catch ME
            warning('Skipping %s / %s due to: %s', device, domainOpts.name, ME.message);
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

        rowCounter = rowCounter + 1;
        rows(end+1,:) = {char(device), rowCounter, domainOpts.name, domainOpts.description, ...
            variantOpts.modeName, variantOpts.referenceName, variantOpts.representationName, ...
            variantOpts.couplingMode, modelPair, metricScore, shapeScore, combinedScore, ...
            expMetrics.rLow, modelMetrics.rLow, expMetrics.Tonset_K, modelMetrics.Tonset_K, ...
            expMetrics.Tmid_K, modelMetrics.Tmid_K, expMetrics.width90_10_K, modelMetrics.width90_10_K, ...
            run.domain.domainLinkFraction, run.domain.meanProbability, ...
            run.percolation.percolationOnset_K, run.percolation.topProbeOnset_K, ...
            run.percolation.bottomProbeOnset_K}; %#ok<AGROW>

        for kT = 1:numel(run.percolation.T)
            percRows(end+1,:) = {char(device), domainOpts.name, run.percolation.T(kT), ...
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
        end
    end

    bestRuns(d).device = char(device); %#ok<SAGROW>
    bestRuns(d).run = bestRun;
    bestRuns(d).expData = expData;
    bestRuns(d).bestCombinedScore = bestCombined;
    fprintf('  best domain/percolation score = %.4g\n', bestCombined);
end

sweepTable = cell2table(rows, 'VariableNames', { ...
    'device','run_id','domain_variant','domain_description', ...
    'raman_mode','reference','representation','couplingMode','modelPair', ...
    'metricScore','shapeScore','combinedScore', ...
    'exp_rLow','model_rLow','exp_Tonset_K','model_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K','exp_width90_10_K','model_width90_10_K', ...
    'domainLinkFraction','meanDomainProbability', ...
    'sourceDrainPercOnset_K','topProbePercOnset_K','bottomProbePercOnset_K'});
sweepTable = sortrows(sweepTable, {'device','combinedScore'});

percolationTable = cell2table(percRows, 'VariableNames', { ...
    'device','domain_variant','T_K','scLinkFraction','largestClusterFraction', ...
    'sourceDrainConnected','topProbeConnected','bottomProbeConnected'});

summaryTable = summarize_domain_percolation_sweep(sweepTable);

writetable(sweepTable, fullfile(outDir, 'domain_percolation_sweep_scores.csv'));
writetable(percolationTable, fullfile(outDir, 'domain_percolation_vs_temperature.csv'));
writetable(summaryTable, fullfile(outDir, 'domain_percolation_summary.csv'));
save(fullfile(outDir, 'domain_percolation_sweep.mat'), ...
    'sweepTable', 'percolationTable', 'summaryTable', 'bestRuns', 'opts', 'metricOpts');

hSummary = plot_domain_percolation_summary(sweepTable, summaryTable);
export_chapter_figure(hSummary, outDir, 'domain_percolation_summary');

hRT = plot_domain_rt_and_percolation(bestRuns);
export_chapter_figure(hRT, outDir, 'domain_rt_percolation_comparison');

hMaps = plot_domain_network_state_maps(bestRuns);
export_chapter_figure(hMaps, outDir, 'domain_network_state_maps');

fprintf('\nFinished v6.4 Raman-domain/percolation sweep.\n');
fprintf('Wrote outputs to:\n%s\n', outDir);

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
