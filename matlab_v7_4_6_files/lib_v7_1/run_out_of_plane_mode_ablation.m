%RUN_OUT_OF_PLANE_MODE_ABLATION v6.3 A4g/out-of-plane Raman contribution test.
%
% This script tests whether the A4g-labeled out-of-plane-sensitive Raman
% channel carries transport-relevant information beyond in-plane modes.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'out_of_plane_mode_ablation');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

model = make_shared_model_params();
opts = make_out_of_plane_options();
metricOpts = make_metric_options();

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));
registered = register_raman_scans_to_hallbar(ramanProxy, registration);

rows = {};
bestRuns = struct();
rowCounter = 0;

for d = 1:numel(opts.devices)
    device = string(opts.devices{d});
    fprintf('\nDevice %s\n', device);

    expData = load_experimental_rt(device);
    expCurveName = first_fieldname(expData.R);
    expMetrics = compute_rt_curve_metrics(expData.T, expData.R.(expCurveName), metricOpts);
    modelPair = expData.modelPair;

    bestCombined = Inf;
    bestRun = [];

    for im = 1:numel(opts.modeSet)
        for ir = 1:numel(opts.referenceSet)
            for ip = 1:numel(opts.representationSet)
                for ic = 1:numel(opts.couplingSet)
                    variantOpts = make_variant_struct(opts, im, ir, ip, ic);
                    try
                        seed = model.ensemble.seed0 + 3100 * sum(double(char(device))) + rowCounter + 1;
                        run = run_single_raman_variant_model(device, model, opts.T_vec, ...
                            opts.Iprobe, registered, variantOpts, seed);
                    catch ME
                        warning('Skipping %s %s due to: %s', device, ...
                            variantOpts.modeName, ME.message);
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
                    rows(end+1,:) = {char(device), rowCounter, ...
                        variantOpts.modeName, variantOpts.referenceName, ...
                        variantOpts.representationName, variantOpts.couplingMode, ...
                        variantOpts.alpha, modelPair, ...
                        metricScore, shapeScore, combinedScore, ...
                        expMetrics.rLow, modelMetrics.rLow, ...
                        expMetrics.Tonset_K, modelMetrics.Tonset_K, ...
                        expMetrics.Tmid_K, modelMetrics.Tmid_K, ...
                        expMetrics.width90_10_K, modelMetrics.width90_10_K}; %#ok<AGROW>

                    if combinedScore < bestCombined
                        bestCombined = combinedScore;
                        bestRun = run;
                    end
                end
            end
        end
    end

    bestRuns(d).device = char(device); %#ok<SAGROW>
    bestRuns(d).run = bestRun;
    bestRuns(d).expData = expData;
    bestRuns(d).bestCombinedScore = bestCombined;
    fprintf('  best combined score = %.4g\n', bestCombined);
end

scoreTable = cell2table(rows, 'VariableNames', { ...
    'device','variant_id','mode_variant','reference','representation','couplingMode', ...
    'alpha','modelPair','metricScore','shapeScore','combinedScore', ...
    'exp_rLow','model_rLow','exp_Tonset_K','model_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K','exp_width90_10_K','model_width90_10_K'});
scoreTable = sortrows(scoreTable, {'device','combinedScore'});

modeSummary = summarize_out_of_plane_modes(scoreTable);
oopIndex = compute_out_of_plane_contribution_index(modeSummary);

writetable(scoreTable, fullfile(outDir, 'out_of_plane_mode_ablation_scores.csv'));
writetable(modeSummary, fullfile(outDir, 'out_of_plane_mode_summary.csv'));
writetable(oopIndex, fullfile(outDir, 'out_of_plane_contribution_index.csv'));
save(fullfile(outDir, 'out_of_plane_mode_ablation.mat'), ...
    'scoreTable', 'modeSummary', 'oopIndex', 'bestRuns', 'opts', 'metricOpts');

hMode = plot_out_of_plane_mode_ablation(modeSummary, oopIndex);
export_chapter_figure(hMode, outDir, 'out_of_plane_mode_ablation_summary');

hRT = plot_raman_variant_best_rt_comparison(bestRuns);
export_chapter_figure(hRT, outDir, 'out_of_plane_best_rt_comparison');

fprintf('\nFinished v6.3 out-of-plane mode-ablation analysis.\n');
fprintf('Wrote outputs to:\n%s\n', outDir);

function variantOpts = make_variant_struct(opts, im, ir, ip, ic)
variantOpts = struct();
variantOpts.modeName = opts.modeSet{im};
variantOpts.referenceName = opts.referenceSet{ir};
variantOpts.representationName = opts.representationSet{ip};
variantOpts.couplingMode = opts.couplingSet{ic};
variantOpts.alpha = 1.0;
variantOpts.sigma_um = opts.sigma_um;
variantOpts.maxDistance_um = opts.maxDistance_um;
variantOpts.minCoverageNorm = opts.minCoverageNorm;
variantOpts.supportPower = opts.supportPower;
variantOpts.useDisplayMap = opts.useDisplayMap;
variantOpts.ramanScaleMode = opts.ramanScaleMode;
end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
