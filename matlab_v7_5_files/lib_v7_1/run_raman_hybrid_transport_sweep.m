%RUN_RAMAN_HYBRID_TRANSPORT_SWEEP Test whether Raman-informed eta improves R(T).
%
% v6 central question:
%   Holding the same network rules fixed, does registered Raman spatial
%   heterogeneity improve normalized R(T) agreement for AS002/AS005/AS006?

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'raman_hybrid_transport');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

model = make_shared_model_params();
opts = make_raman_hybrid_options();
metricOpts = make_metric_options();

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));
registered = register_raman_scans_to_hallbar(ramanProxy, registration);

devices = string(opts.devices);
alphaVec = opts.alphaVec;
rows = {};
allSweeps = struct();

for d = 1:numel(devices)
    device = devices(d);
    expData = load_experimental_rt(device);
    if ~expData.available
        warning('Skipping %s because no experimental R(T) is available.', device);
        continue;
    end
    expCurveName = first_fieldname(expData.R);
    expMetrics = compute_rt_curve_metrics(expData.T, expData.R.(expCurveName), metricOpts);
    modelPair = expData.modelPair;

    for ia = 1:numel(alphaVec)
        alpha = alphaVec(ia);

        if alpha == 0
            run = run_single_proxy_model(device, model, opts.T_vec, opts.Iprobe, ...
                'geometry_only', 0, registered, []);
            ensemble = run_device_ensemble(run.spec, model, opts.T_vec, opts.Iprobe, ...
                opts.Nens, 'full');
        else
            ensemble = run_raman_hybrid_ensemble(device, model, opts.T_vec, ...
                opts.Iprobe, alpha, registered, opts.Nens);
            run = ensemble.firstRun;
        end

        if ~isfield(ensemble.R4pMean, modelPair)
            modelPair = first_fieldname(ensemble.R4pMean);
        end
        modelMetrics = compute_rt_curve_metrics(ensemble.T, ...
            ensemble.R4pMean.(modelPair), metricOpts);
        score = score_rt_metric_agreement(expMetrics, modelMetrics, opts);

        rows(end+1,:) = {char(device), alpha, run.proxyMode, modelPair, ...
            score, expMetrics.rLow, modelMetrics.rLow, ...
            expMetrics.Tonset_K, modelMetrics.Tonset_K, ...
            expMetrics.Tmid_K, modelMetrics.Tmid_K, ...
            expMetrics.width90_10_K, modelMetrics.width90_10_K, ...
            run.proxyInfo.meanEtaGeometry, run.proxyInfo.meanEtaHybrid, ...
            getfield_default(run.proxyInfo, 'meanSupport', NaN), ...
            getfield_default(run.proxyInfo, 'supportedNodeFraction', NaN)}; %#ok<GFLD,AGROW>

        allSweeps(d).device = char(device); %#ok<SAGROW>
        allSweeps(d).expData = expData;
        allSweeps(d).runs(ia).alpha = alpha;
        allSweeps(d).runs(ia).run = run;
        allSweeps(d).runs(ia).ensemble = ensemble;
        allSweeps(d).runs(ia).score = score;
        allSweeps(d).runs(ia).modelPair = modelPair;
    end
end

sweepTable = cell2table(rows, 'VariableNames', { ...
    'device','alpha','proxyMode','modelPair','score', ...
    'exp_rLow','model_rLow','exp_Tonset_K','model_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K','exp_width90_10_K','model_width90_10_K', ...
    'meanEtaGeometry','meanEtaHybrid','meanRamanSupport','supportedNodeFraction'});

writetable(sweepTable, fullfile(outDir, 'raman_hybrid_alpha_sweep_metrics.csv'));
save(fullfile(outDir, 'raman_hybrid_transport_sweep.mat'), ...
    'allSweeps', 'sweepTable', 'opts', 'metricOpts');

hScore = plot_raman_hybrid_alpha_sweep(sweepTable);
export_chapter_figure(hScore, outDir, 'raman_hybrid_alpha_sweep_scores');

hRT = plot_raman_hybrid_rt_comparison(allSweeps, sweepTable);
export_chapter_figure(hRT, outDir, 'raman_hybrid_rt_comparison');

fprintf('\nFinished v6 Raman-hybrid transport sweep.\n');
fprintf('Wrote:\n');
fprintf('  %s\n', fullfile(outDir, 'raman_hybrid_alpha_sweep_metrics.csv'));
fprintf('  %s\n', fullfile(outDir, 'raman_hybrid_alpha_sweep_scores.png'));
fprintf('  %s\n', fullfile(outDir, 'raman_hybrid_rt_comparison.png'));

function name = first_fieldname(S)
names = fieldnames(S);
name = names{1};
end

function value = getfield_default(S, fieldName, defaultValue)
if isfield(S, fieldName)
    value = S.(fieldName);
else
    value = defaultValue;
end
end
