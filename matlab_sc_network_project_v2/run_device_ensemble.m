function ensemble = run_device_ensemble(spec, model, T_vec, Iprobe, Nens, mode)
%RUN_DEVICE_ENSEMBLE Run repeated disorder realizations for one device.
%
% Usage from the main script:
%   ensemble = run_device_ensemble(spec, model, T_vec, Iprobe, Nens, mode)
%
% Standalone/default usage from the MATLAB prompt:
%   run_device_ensemble
%   run_device_ensemble('AS005')

if nargin < 1 || isempty(spec)
    spec = make_device_spec('AS005');
elseif ischar(spec) || isstring(spec)
    spec = make_device_spec(char(spec));
end

if nargin < 2 || isempty(model)
    model = make_shared_model_params();
end

if nargin < 3 || isempty(T_vec)
    T_vec = linspace(0.05, 2.20, 160);
end

if nargin < 4 || isempty(Iprobe)
    Iprobe = 1e-8;
end

if nargin < 5 || isempty(Nens)
    Nens = model.ensemble.N;
end

if nargin < 6
    mode = 'full';
end

for k = 1:Nens
    seed = model.ensemble.seed0 + 1000 * sum(double(spec.name)) + k;

    net = build_hallbar_network(spec);
    net = apply_mechanical_proxy(net, spec, model, mode);
    net = apply_ablation_mode(net, spec, mode);

    params = assign_link_parameters(net, spec, model, seed, mode);
    params = calibrate_normal_resistance(net, spec, params);

    result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
    metrics(k) = compute_device_metrics(net, spec, params, result, model); %#ok<AGROW>

    pairNames = fieldnames(result.R4p);
    for kp = 1:numel(pairNames)
        p = pairNames{kp};
        Rmat.(p)(k,:) = result.R4p.(p); %#ok<AGROW>
    end
end

ensemble = struct();
ensemble.mode = mode;
ensemble.N = Nens;
ensemble.T = T_vec;
ensemble.metrics = metrics;

pairNames = fieldnames(Rmat);
for kp = 1:numel(pairNames)
    p = pairNames{kp};
    ensemble.R4pMean.(p) = mean(Rmat.(p), 1);
    ensemble.R4pStd.(p) = std(Rmat.(p), 0, 1);
    ensemble.R4pAll.(p) = Rmat.(p);
end

ensemble.metricSummary = summarize_metrics(metrics);

if nargout == 0
    fprintf('Finished ensemble for %s, mode = %s, N = %d.\n', ...
        spec.name, mode, Nens);
    disp(ensemble.metricSummary);
    plot_ensemble_rt(spec, ensemble);
end

end

function summary = summarize_metrics(metrics)

fields = fieldnames(metrics);
summary = struct();

for kf = 1:numel(fields)
    f = fields{kf};
    vals = [metrics.(f)];
    if isnumeric(vals) && isvector(vals)
        summary.(f).mean = local_nanmean(vals);
        summary.(f).std = local_nanstd(vals);
    end
end

end

function m = local_nanmean(x)
x = x(isfinite(x));
if isempty(x); m = NaN; else; m = mean(x); end
end

function s = local_nanstd(x)
x = x(isfinite(x));
if numel(x) < 2; s = NaN; else; s = std(x); end
end
