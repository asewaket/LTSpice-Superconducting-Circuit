function run = run_single_physics_case_model(deviceName, model, T_vec, Iprobe, registered, caseDef, seed, percOpts)
%RUN_SINGLE_PHYSICS_CASE_MODEL Run one v6.5 named physics case.

if nargin < 7 || isempty(seed)
    seed = model.ensemble.seed0 + 6500 + sum(double(char(deviceName)));
end
if nargin < 8 || isempty(percOpts)
    percOpts = struct('scResistanceFraction', model.metrics.percResistanceFraction);
end

if isfield(caseDef, 'useDeviceBestVariant') && caseDef.useDeviceBestVariant
    variantOpts = get_v64_best_variant_options(deviceName);
else
    variantOpts = caseDef.variant;
end

run = run_single_raman_variant_model(deviceName, model, T_vec, Iprobe, ...
    registered, variantOpts, seed);

[paramsCase, caseInfo] = apply_physics_informed_case_model(run.net, run.spec, ...
    run.params, caseDef, seed + 29);

paramsCase = calibrate_normal_resistance(run.net, run.spec, paramsCase);
resultCase = solve_rt_sweep(run.net, run.spec, paramsCase, T_vec, Iprobe);
perc = compute_percolation_diagnostics(run.net, run.spec, paramsCase, T_vec, percOpts);

run.params = paramsCase;
run.result = resultCase;
run.percolation = perc;
run.physicsCase = caseDef;
run.caseInfo = caseInfo;
run.caseID = caseDef.caseID;

end
