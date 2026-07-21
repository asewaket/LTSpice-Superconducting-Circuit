function run = run_single_proxy_model(deviceName, model, T_vec, Iprobe, proxyMode, alpha, registered, seed)
%RUN_SINGLE_PROXY_MODEL Run one calibrated R(T) realization for a proxy mode.

if nargin < 8 || isempty(seed)
    seed = [];
end
if nargin < 7
    registered = table();
end
if nargin < 6 || isempty(alpha)
    alpha = 0;
end

spec = make_device_spec(deviceName);
spec.sim.T_vec = T_vec;
spec.sim.Iprobe = Iprobe;

if isempty(seed)
    seed = spec.randomSeed;
end

net = build_hallbar_network(spec);
net = apply_mechanical_proxy(net, spec, model, 'full');
proxyInfo = struct('alpha', alpha, 'mode', proxyMode, ...
    'meanEtaGeometry', mean(net.etaNode(net.active), 'omitnan'), ...
    'meanEtaHybrid', mean(net.etaNode(net.active), 'omitnan'), ...
    'meanSupport', 0, ...
    'supportedNodeFraction', 0);

switch char(proxyMode)
    case {'geometry_only','full'}
        proxyMode = 'geometry_only';
    case {'raman_hybrid','hybrid_abs','raman_abs'}
        opts = make_raman_hybrid_options();
        opts.valueColumn = 'abs_shift_proxy';
        [net, proxyInfo] = apply_raman_hybrid_proxy(net, spec, model, registered, alpha, opts);
    otherwise
        error('Unknown proxyMode "%s".', proxyMode);
end

params = assign_link_parameters(net, spec, model, seed, 'full');
params = calibrate_normal_resistance(net, spec, params);
result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
metrics = compute_device_metrics(net, spec, params, result, model);

run = struct();
run.device = char(deviceName);
run.proxyMode = char(proxyMode);
run.alpha = alpha;
run.seed = seed;
run.spec = spec;
run.net = net;
run.params = params;
run.result = result;
run.metrics = metrics;
run.proxyInfo = proxyInfo;

end
