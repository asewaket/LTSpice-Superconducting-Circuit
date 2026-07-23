function run = run_single_raman_variant_model(deviceName, model, T_vec, Iprobe, registered, variantOpts, seed)
%RUN_SINGLE_RAMAN_VARIANT_MODEL Run one v6.1 Raman variant realization.

spec = make_device_spec(deviceName);
spec.sim.T_vec = T_vec;
spec.sim.Iprobe = Iprobe;
if nargin < 7 || isempty(seed)
    seed = spec.randomSeed;
end

netGeometry = build_hallbar_network(spec);
netGeometry = apply_mechanical_proxy(netGeometry, spec, model, 'full');

variantData = prepare_raman_variant_data(registered, spec.name, variantOpts);

hybridOpts = make_raman_hybrid_options();
hybridOpts.valueColumn = 'variant_proxy';
hybridOpts.sigma_um = variantOpts.sigma_um;
hybridOpts.maxDistance_um = variantOpts.maxDistance_um;
hybridOpts.minCoverageNorm = variantOpts.minCoverageNorm;
hybridOpts.supportPower = variantOpts.supportPower;
hybridOpts.useDisplayMap = variantOpts.useDisplayMap;
hybridOpts.ramanScaleMode = variantOpts.ramanScaleMode;

netHybrid = netGeometry;
[netHybrid, proxyInfo] = apply_raman_hybrid_proxy(netHybrid, spec, model, ...
    variantData, variantOpts.alpha, hybridOpts);

if variantOpts.alpha == 0
    params = assign_link_parameters(netGeometry, spec, model, seed, 'full');
    netForSolve = netGeometry;
else
    params = assign_link_parameters_coupled(netGeometry, netHybrid, spec, model, ...
        seed, variantOpts.couplingMode);
    netForSolve = netHybrid;
end

params = calibrate_normal_resistance(netForSolve, spec, params);
result = solve_rt_sweep(netForSolve, spec, params, T_vec, Iprobe);

run = struct();
run.device = spec.name;
run.variant = variantOpts;
run.seed = seed;
run.spec = spec;
run.netGeometry = netGeometry;
run.net = netForSolve;
run.params = params;
run.result = result;
run.proxyInfo = proxyInfo;

end
