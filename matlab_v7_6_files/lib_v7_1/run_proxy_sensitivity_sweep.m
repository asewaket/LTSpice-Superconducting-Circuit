function sweep = run_proxy_sensitivity_sweep(opts, outDir)
%RUN_PROXY_SENSITIVITY_SWEEP Rank proxy/model parameters using R(T) metrics.
%
% This is intentionally lightweight: by default it runs one representative
% realization per device and parameter sample. It is meant to identify broad
% trends and useful parameter regions, not to perform a final fit.

if nargin < 1 || isempty(opts)
    opts = make_sensitivity_options();
end
if nargin < 2
    outDir = '';
end

baseModel = make_shared_model_params();
metricOpts = make_metric_options();
samples = generate_sensitivity_samples(opts);

scoreRows = {};
deviceRows = {};

for ks = 1:numel(samples)
    sample = samples(ks);
    model = apply_sensitivity_sample_to_model(baseModel, sample);

    sampleScores = [];

    for kd = 1:numel(opts.deviceNames)
        deviceName = opts.deviceNames{kd};
        spec = make_device_spec(deviceName);
        expData = load_experimental_rt(deviceName);

        if ~expData.available
            continue;
        end

        net = build_hallbar_network(spec);
        net = apply_mechanical_proxy(net, spec, model, 'full');

        % Use the same deterministic seed structure for every sample so the
        % sweep compares parameter effects more than random-seed effects.
        params = assign_link_parameters(net, spec, model, spec.randomSeed, 'full');
        params = calibrate_normal_resistance(net, spec, params);
        result = solve_rt_sweep(net, spec, params, opts.T_vec, opts.Iprobe);

        expMetrics = first_experiment_metrics(expData, metricOpts);
        modelPair = expData.modelPair;
        if ~isfield(result.R4p, modelPair)
            pairNames = fieldnames(result.R4p);
            modelPair = pairNames{1};
        end
        modelMetrics = compute_rt_curve_metrics(result.T, result.R4p.(modelPair), metricOpts);

        [score, components] = metric_score(expMetrics, modelMetrics, opts.scoreScale);
        sampleScores(end+1) = score; %#ok<AGROW>

        deviceRows(end+1,:) = device_score_row(sample.sampleIndex, deviceName, modelPair, score, components, expMetrics, modelMetrics); %#ok<AGROW>
    end

    totalScore = local_nanmean(sampleScores);
    scoreRows(end+1,:) = sample_score_row(sample, totalScore); %#ok<AGROW>

    fprintf('Sensitivity sample %d/%d score = %.3f\n', ks, numel(samples), totalScore);
end

summaryTable = cell2table(scoreRows, 'VariableNames', sample_score_columns());
deviceTable = cell2table(deviceRows, 'VariableNames', device_score_columns());
summaryTable = sortrows(summaryTable, 'score_total', 'ascend');

sweep = struct();
sweep.options = opts;
sweep.summaryTable = summaryTable;
sweep.deviceTable = deviceTable;
sweep.samples = samples;

if ~isempty(outDir)
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writetable(summaryTable, fullfile(outDir, 'proxy_sensitivity_ranked_samples.csv'));
    writetable(deviceTable, fullfile(outDir, 'proxy_sensitivity_device_scores.csv'));
    save(fullfile(outDir, 'proxy_sensitivity_sweep.mat'), 'sweep');

    h = plot_proxy_sensitivity_summary(summaryTable);
    export_chapter_figure(h, outDir, 'proxy_sensitivity_summary');
end

end

function m = first_experiment_metrics(expData, metricOpts)
rNames = fieldnames(expData.R);
m = compute_rt_curve_metrics(expData.T, expData.R.(rNames{1}), metricOpts);
end

function [score, components] = metric_score(expM, modelM, scale)

components = struct();
components.rLow = abs(modelM.rLow - expM.rLow) / scale.rLow;
components.suppressionFrac = abs(modelM.suppressionFrac - expM.suppressionFrac) / scale.suppressionFrac;
components.Tonset_K = abs(modelM.Tonset_K - expM.Tonset_K) / scale.Tonset_K;
components.Tmid_K = abs(modelM.Tmid_K - expM.Tmid_K) / scale.Tmid_K;
components.width90_10_K = abs(modelM.width90_10_K - expM.width90_10_K) / scale.width90_10_K;

vals = [components.rLow, components.suppressionFrac, components.Tonset_K, ...
    components.Tmid_K, components.width90_10_K];
score = local_nanmean(vals);

end

function row = sample_score_row(sample, score)
row = {sample.sampleIndex, score, ...
    sample.coveredWeight, sample.boundaryWeight, sample.crackWeight, sample.edgeWeight, ...
    sample.TcSpan_K, sample.eta0, sample.sigmoidWidth, ...
    sample.residualLow, sample.residualHigh};
end

function cols = sample_score_columns()
cols = {'sampleIndex','score_total', ...
    'coveredWeight','boundaryWeight','crackWeight','edgeWeight', ...
    'TcSpan_K','eta0','sigmoidWidth','residualLow','residualHigh'};
end

function row = device_score_row(sampleIndex, device, modelPair, score, components, expM, modelM)
row = {sampleIndex, device, modelPair, score, ...
    components.rLow, components.suppressionFrac, components.Tonset_K, components.Tmid_K, components.width90_10_K, ...
    expM.rLow, modelM.rLow, ...
    expM.Tonset_K, modelM.Tonset_K, ...
    expM.Tmid_K, modelM.Tmid_K, ...
    expM.width90_10_K, modelM.width90_10_K};
end

function cols = device_score_columns()
cols = {'sampleIndex','device','modelPair','score_device', ...
    'score_rLow','score_suppressionFrac','score_Tonset','score_Tmid','score_width90_10', ...
    'exp_rLow','model_rLow', ...
    'exp_Tonset_K','model_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K', ...
    'exp_width90_10_K','model_width90_10_K'};
end

function m = local_nanmean(x)
x = x(isfinite(x));
if isempty(x); m = NaN; else; m = mean(x); end
end
