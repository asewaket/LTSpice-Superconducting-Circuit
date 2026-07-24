function suite = run_as005_null_model_suite(model, T_vec, Iprobe)
%RUN_AS005_NULL_MODEL_SUITE Shared-seed AS005 null/dimensionality tests.

if nargin < 1 || isempty(model)
    model = make_shared_model_params();
end
if nargin < 2 || isempty(T_vec)
    T_vec = linspace(0.05, 2.20, 160);
end
if nargin < 3 || isempty(Iprobe)
    Iprobe = 1e-8;
end

spec = make_device_spec('AS005');
sharedSeed = spec.randomSeed + 505;
modes = {'full','central_lane','uniform','random_eta','crack_off'};

suite = struct();
suite.spec = spec;
suite.modes = modes;
suite.sharedSeed = sharedSeed;

for km = 1:numel(modes)
    mode = modes{km};

    net = build_hallbar_network(spec);
    rng(sharedSeed);
    net = apply_mechanical_proxy(net, spec, model, mode);
    net = apply_ablation_mode(net, spec, mode);

    params = assign_link_parameters(net, spec, model, sharedSeed, mode);
    params = calibrate_normal_resistance(net, spec, params);
    result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
    result.metrics = compute_device_metrics(net, spec, params, result, model);

    suite.cases.(mode).net = net;
    suite.cases.(mode).params = params;
    suite.cases.(mode).result = result;
end

end

