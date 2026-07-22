function run = run_single_domain_model(deviceName, model, T_vec, Iprobe, registered, variantOpts, domainOpts, seed, percOpts)
%RUN_SINGLE_DOMAIN_MODEL Run v6.4 smooth Raman + optional domain layer.

if nargin < 8 || isempty(seed)
    seed = model.ensemble.seed0 + 6400 + sum(double(char(deviceName)));
end
if nargin < 9 || isempty(percOpts)
    percOpts = struct('scResistanceFraction', model.metrics.percResistanceFraction);
end

run = run_single_raman_variant_model(deviceName, model, T_vec, Iprobe, ...
    registered, variantOpts, seed);

[paramsDomain, domainInfo] = apply_enhanced_domain_model(run.net, run.spec, ...
    run.params, domainOpts, seed + 17);

paramsDomain = calibrate_normal_resistance(run.net, run.spec, paramsDomain);
resultDomain = solve_rt_sweep(run.net, run.spec, paramsDomain, T_vec, Iprobe);
perc = compute_percolation_diagnostics(run.net, run.spec, paramsDomain, T_vec, percOpts);

run.params = paramsDomain;
run.result = resultDomain;
run.domain = domainInfo;
run.percolation = perc;
run.domainVariant = domainOpts.name;

end
