function tables = build_rt_metric_tables(allResults, outDir)
%BUILD_RT_METRIC_TABLES Build and optionally export v4 R(T) metric tables.

if nargin < 2
    outDir = '';
end

opts = make_metric_options();

rows = {};
comparisonRows = {};

for kd = 1:numel(allResults)
    item = allResults(kd);
    device = item.name;

    % Experimental selected/main curve and optional explicit pair curves.
    expData = item.expData;
    if expData.available
        expRows = metric_rows_from_expdata(device, expData, opts);
        rows = [rows; expRows]; %#ok<AGROW>
    end

    if isfield(expData, 'pairData') && expData.pairData.available
        expPairRows = metric_rows_from_pairdata(device, expData.pairData, opts);
        rows = [rows; expPairRows]; %#ok<AGROW>
    end

    % Representative model realization.
    modelRows = metric_rows_from_model_result(device, item.result, opts, 'model_representative');
    rows = [rows; modelRows]; %#ok<AGROW>

    % Ensemble normalized metrics for every model probe pair.
    ensRows = metric_rows_from_ensemble(device, item.ensemble, opts);
    rows = [rows; ensRows]; %#ok<AGROW>
end

metricTable = cell2table(rows, 'VariableNames', metric_column_names());

% Build selected experiment-vs-model comparison table. This uses the curated
% experimental curve and the corresponding model pair defined in the data table.
for kd = 1:numel(allResults)
    item = allResults(kd);
    if ~item.expData.available
        continue;
    end

    device = item.name;
    modelPair = item.expData.modelPair;

    expMetrics = compute_first_exp_metrics(item.expData, opts);
    modelMetrics = compute_ensemble_mean_metrics(item.ensemble, modelPair, opts);

    comparisonRows(end+1,:) = comparison_row(device, modelPair, expMetrics, modelMetrics); %#ok<AGROW>
end

comparisonTable = cell2table(comparisonRows, 'VariableNames', comparison_column_names());

tables = struct();
tables.metricTable = metricTable;
tables.comparisonTable = comparisonTable;
tables.options = opts;

if ~isempty(outDir)
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writetable(metricTable, fullfile(outDir, 'rt_metrics_all_sources.csv'));
    writetable(comparisonTable, fullfile(outDir, 'rt_metrics_model_experiment_comparison.csv'));
end

end

function rows = metric_rows_from_expdata(device, expData, opts)

rows = {};
rNames = fieldnames(expData.R);
for kr = 1:numel(rNames)
    rName = rNames{kr};
    m = compute_rt_curve_metrics(expData.T, expData.R.(rName), opts);
    rows(end+1,:) = metric_row(device, 'experiment_selected', rName, m); %#ok<AGROW>
end

end

function rows = metric_rows_from_pairdata(device, pairData, opts)

rows = {};
rNames = fieldnames(pairData.R);
for kr = 1:numel(rNames)
    rName = rNames{kr};
    m = compute_rt_curve_metrics(pairData.T, pairData.R.(rName), opts);
    rows(end+1,:) = metric_row(device, 'experiment_pairfile', rName, m); %#ok<AGROW>
end

end

function rows = metric_rows_from_model_result(device, result, opts, sourceName)

rows = {};
pairNames = fieldnames(result.R4p);
for kp = 1:numel(pairNames)
    p = pairNames{kp};
    m = compute_rt_curve_metrics(result.T, result.R4p.(p), opts);
    rows(end+1,:) = metric_row(device, sourceName, p, m); %#ok<AGROW>
end

end

function rows = metric_rows_from_ensemble(device, ensemble, opts)

rows = {};
pairNames = fieldnames(ensemble.R4pAll);
for kp = 1:numel(pairNames)
    p = pairNames{kp};
    Rall = ensemble.R4pAll.(p);
    metrics = repmat(compute_rt_curve_metrics(ensemble.T, Rall(1,:), opts), size(Rall,1), 1);
    for k = 1:size(Rall,1)
        metrics(k) = compute_rt_curve_metrics(ensemble.T, Rall(k,:), opts);
    end
    mMean = mean_metrics(metrics);
    mStd = std_metrics(metrics);
    rows(end+1,:) = metric_row(device, 'model_ensemble_mean', p, mMean); %#ok<AGROW>
    rows(end+1,:) = metric_row(device, 'model_ensemble_std', p, mStd); %#ok<AGROW>
end

end

function m = compute_first_exp_metrics(expData, opts)

rNames = fieldnames(expData.R);
m = compute_rt_curve_metrics(expData.T, expData.R.(rNames{1}), opts);

end

function m = compute_ensemble_mean_metrics(ensemble, modelPair, opts)

if ~isfield(ensemble.R4pAll, modelPair)
    pairNames = fieldnames(ensemble.R4pAll);
    modelPair = pairNames{1};
end

Rall = ensemble.R4pAll.(modelPair);
metrics = repmat(compute_rt_curve_metrics(ensemble.T, Rall(1,:), opts), size(Rall,1), 1);
for k = 1:size(Rall,1)
    metrics(k) = compute_rt_curve_metrics(ensemble.T, Rall(k,:), opts);
end
m = mean_metrics(metrics);

end

function row = metric_row(device, sourceName, channelName, m)

row = {device, sourceName, channelName, ...
    m.N_points, m.T_min_K, m.T_max_K, ...
    m.RN_ohm, m.Rlow_ohm, m.rLow, m.suppressionFrac, ...
    m.Tonset_K, m.Tmid_K, m.T90_K, m.T10_K, m.width90_10_K};

end

function row = comparison_row(device, modelPair, expM, modelM)

row = {device, modelPair, ...
    expM.rLow, modelM.rLow, modelM.rLow - expM.rLow, ...
    expM.suppressionFrac, modelM.suppressionFrac, modelM.suppressionFrac - expM.suppressionFrac, ...
    expM.Tonset_K, modelM.Tonset_K, modelM.Tonset_K - expM.Tonset_K, ...
    expM.Tmid_K, modelM.Tmid_K, modelM.Tmid_K - expM.Tmid_K, ...
    expM.width90_10_K, modelM.width90_10_K, modelM.width90_10_K - expM.width90_10_K};

end

function names = metric_column_names()
names = {'device','source','channel','N_points','T_min_K','T_max_K', ...
    'RN_ohm','Rlow_ohm','rLow','suppressionFrac', ...
    'Tonset_K','Tmid_K','T90_K','T10_K','width90_10_K'};
end

function names = comparison_column_names()
names = {'device','modelPair', ...
    'exp_rLow','model_rLow','delta_rLow', ...
    'exp_suppressionFrac','model_suppressionFrac','delta_suppressionFrac', ...
    'exp_Tonset_K','model_Tonset_K','delta_Tonset_K', ...
    'exp_Tmid_K','model_Tmid_K','delta_Tmid_K', ...
    'exp_width90_10_K','model_width90_10_K','delta_width90_10_K'};
end

function out = mean_metrics(metrics)
out = metrics(1);
fields = metric_numeric_fields();
for kf = 1:numel(fields)
    f = fields{kf};
    vals = [metrics.(f)];
    out.(f) = local_nanmean(vals);
end
end

function out = std_metrics(metrics)
out = metrics(1);
fields = metric_numeric_fields();
for kf = 1:numel(fields)
    f = fields{kf};
    vals = [metrics.(f)];
    out.(f) = local_nanstd(vals);
end
end

function fields = metric_numeric_fields()
fields = {'N_points','T_min_K','T_max_K','RN_ohm','Rlow_ohm','rLow', ...
    'suppressionFrac','Tonset_K','Tmid_K','T90_K','T10_K','width90_10_K'};
end

function m = local_nanmean(x)
x = x(isfinite(x));
if isempty(x); m = NaN; else; m = mean(x); end
end

function s = local_nanstd(x)
x = x(isfinite(x));
if numel(x) < 2; s = NaN; else; s = std(x); end
end
