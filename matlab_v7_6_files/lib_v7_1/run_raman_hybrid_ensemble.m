function ensemble = run_raman_hybrid_ensemble(deviceName, model, T_vec, Iprobe, alpha, registered, Nens)
%RUN_RAMAN_HYBRID_ENSEMBLE Run repeated Raman-hybrid disorder realizations.

if nargin < 7 || isempty(Nens)
    opts = make_raman_hybrid_options();
    Nens = opts.Nens;
end

spec = make_device_spec(deviceName);

for k = 1:Nens
    seed = model.ensemble.seed0 + 1000 * sum(double(spec.name)) + ...
        round(100 * alpha) + k;
    run = run_single_proxy_model(deviceName, model, T_vec, Iprobe, ...
        'raman_hybrid', alpha, registered, seed);
    metrics(k) = run.metrics; %#ok<AGROW>
    pairNames = fieldnames(run.result.R4p);
    for kp = 1:numel(pairNames)
        p = pairNames{kp};
        Rmat.(p)(k,:) = run.result.R4p.(p); %#ok<AGROW>
    end
    if k == 1
        firstRun = run;
    end
end

ensemble = struct();
ensemble.device = char(deviceName);
ensemble.mode = 'raman_hybrid';
ensemble.alpha = alpha;
ensemble.N = Nens;
ensemble.T = T_vec;
ensemble.metrics = metrics;
ensemble.firstRun = firstRun;

pairNames = fieldnames(Rmat);
for kp = 1:numel(pairNames)
    p = pairNames{kp};
    ensemble.R4pMean.(p) = mean(Rmat.(p), 1);
    ensemble.R4pStd.(p) = std(Rmat.(p), 0, 1);
    ensemble.R4pAll.(p) = Rmat.(p);
end

end
