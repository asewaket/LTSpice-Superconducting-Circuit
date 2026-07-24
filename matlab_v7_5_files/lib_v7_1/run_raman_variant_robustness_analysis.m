%RUN_RAMAN_VARIANT_ROBUSTNESS_ANALYSIS v6.2 robustness/family analysis.
%
% Required first step:
%   run_raman_variant_sensitivity_sweep
%
% This script reads the v6.1 ranked variant table, summarizes variant
% families, selects the top candidates per device, and reruns them over
% multiple disorder realizations.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
opts = make_raman_robustness_options();
outDir = fullfile(projectDir, opts.robustnessOutputSubdir);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

sweepTable = load_v61_sweep_table(projectDir, opts);
baselineTable = compute_geometry_baseline_scores(sweepTable, opts);
familyTable = summarize_raman_variant_families(sweepTable, opts);
topTable = select_top_raman_variants(sweepTable, opts);

writetable(baselineTable, fullfile(outDir, 'geometry_baseline_scores.csv'));
writetable(familyTable, fullfile(outDir, 'raman_variant_family_summary.csv'));
writetable(topTable, fullfile(outDir, 'selected_top_variants_for_robustness.csv'));

hFamily = plot_raman_variant_family_summary(familyTable, baselineTable, opts);
export_chapter_figure(hFamily, outDir, 'raman_variant_family_summary');

model = make_shared_model_params();
variantOptsBase = make_raman_variant_options();
metricOpts = make_metric_options();

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));
registered = register_raman_scans_to_hallbar(ramanProxy, registration);

rows = {};

for r = 1:height(topTable)
    row = topTable(r,:);
    device = string(row.device);
    expData = load_experimental_rt(device);
    expCurveName = first_fieldname(expData.R);
    expMetrics = compute_rt_curve_metrics(expData.T, expData.R.(expCurveName), metricOpts);
    modelPair = string(row.modelPair);
    variantLabel = make_variant_label(row);

    fprintf('\n%s: %s\n', device, variantLabel);

    for k = 1:opts.Nens
        seed = model.ensemble.seed0 + 9000 * sum(double(char(device))) + ...
            100 * r + k;

        if string(row.couplingMode) == "geometry_only" || row.alpha == 0
            run = run_single_proxy_model(device, model, opts.T_vec, opts.Iprobe, ...
                'geometry_only', 0, registered, seed);
        else
            v = variant_from_table_row(row, variantOptsBase);
            run = run_single_raman_variant_model(device, model, opts.T_vec, ...
                opts.Iprobe, registered, v, seed);
        end

        if ~isfield(run.result.R4p, char(modelPair))
            modelPair = string(first_fieldname(run.result.R4p));
        end
        Rmodel = run.result.R4p.(char(modelPair));
        modelMetrics = compute_rt_curve_metrics(run.result.T, Rmodel, metricOpts);
        metricScore = score_rt_metric_agreement(expMetrics, modelMetrics, variantOptsBase);
        shapeScore = compute_rt_shape_score(expData.T, expData.R.(expCurveName), ...
            run.result.T, Rmodel);
        combinedScore = combine_raman_scores(metricScore, shapeScore, variantOptsBase);

        rows(end+1,:) = {char(device), r, char(variantLabel), k, seed, ...
            char(row.raman_mode), char(row.reference), char(row.representation), ...
            char(row.couplingMode), row.alpha, char(modelPair), ...
            metricScore, shapeScore, combinedScore, ...
            modelMetrics.rLow, modelMetrics.Tonset_K, modelMetrics.Tmid_K, ...
            modelMetrics.width90_10_K}; %#ok<AGROW>
    end
end

robustnessTable = cell2table(rows, 'VariableNames', { ...
    'device','selectedVariantIndex','variantLabel','realization','seed', ...
    'raman_mode','reference','representation','couplingMode','alpha','modelPair', ...
    'metricScore','shapeScore','combinedScore', ...
    'model_rLow','model_Tonset_K','model_Tmid_K','model_width90_10_K'});

robustnessSummary = summarize_robustness_table(robustnessTable);

writetable(robustnessTable, fullfile(outDir, 'raman_variant_robustness_realizations.csv'));
writetable(robustnessSummary, fullfile(outDir, 'raman_variant_robustness_summary.csv'));

hRobust = plot_raman_variant_robustness_summary(robustnessSummary);
export_chapter_figure(hRobust, outDir, 'raman_variant_robustness_summary');

save(fullfile(outDir, 'raman_variant_robustness_analysis.mat'), ...
    'sweepTable', 'baselineTable', 'familyTable', 'topTable', ...
    'robustnessTable', 'robustnessSummary', 'opts');

fprintf('\nFinished v6.2 Raman variant robustness analysis.\n');
fprintf('Wrote outputs to:\n%s\n', outDir);

function v = variant_from_table_row(row, base)
v = struct();
v.modeName = char(row.raman_mode);
v.referenceName = char(row.reference);
v.representationName = char(row.representation);
v.couplingMode = char(row.couplingMode);
v.alpha = row.alpha;
v.sigma_um = base.sigma_um;
v.maxDistance_um = base.maxDistance_um;
v.minCoverageNorm = base.minCoverageNorm;
v.supportPower = base.supportPower;
v.useDisplayMap = base.useDisplayMap;
v.ramanScaleMode = base.ramanScaleMode;
end

function label = make_variant_label(row)
if string(row.couplingMode) == "geometry_only" || row.alpha == 0
    label = "geometry only";
else
    label = string(row.raman_mode) + ", " + string(row.representation) + ...
        ", " + string(row.couplingMode) + ", \alpha=" + string(row.alpha);
end
end

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end
