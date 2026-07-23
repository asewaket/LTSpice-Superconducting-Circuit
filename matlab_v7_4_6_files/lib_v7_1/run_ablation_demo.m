function ablationResults = run_ablation_demo(deviceName, model, T_vec, Iprobe)
%RUN_ABLATION_DEMO Basic null models for one representative device.
%
% Standalone/default usage from the MATLAB prompt:
%   run_ablation_demo
%   run_ablation_demo('AS005')

if nargin < 1 || isempty(deviceName)
    deviceName = 'AS005';
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

modes = {'full','central_lane','uniform','random_eta','crack_off'};
spec = make_device_spec(deviceName);
sharedSeed = spec.randomSeed + 505;

ablationResults = struct();

for km = 1:numel(modes)
    mode = modes{km};
    if strcmp(mode, 'crack_off') && ~strcmp(spec.geometryClass, 'cracked_full')
        continue;
    end

    net = build_hallbar_network(spec);
    rng(sharedSeed);
    net = apply_mechanical_proxy(net, spec, model, mode);
    net = apply_ablation_mode(net, spec, mode);

    params = assign_link_parameters(net, spec, model, sharedSeed, mode);
    params = calibrate_normal_resistance(net, spec, params);
    result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
    result.metrics = compute_device_metrics(net, spec, params, result, model);

    ablationResults.(mode).net = net;
    ablationResults.(mode).params = params;
    ablationResults.(mode).result = result;
end

if nargout == 0
    figure('Color','w', 'Name', sprintf('%s ablation demo', deviceName));
    hold on;
    labels = fieldnames(ablationResults);
    for k = 1:numel(labels)
        label = labels{k};
        result = ablationResults.(label).result;
        plot(result.T, result.R4p.top_4_10, 'LineWidth', 2, ...
            'DisplayName', strrep(label, '_', '\_'));
    end
    grid on;
    xlabel('Temperature T [K]');
    ylabel('R_{4-10} [\Omega]');
    title(sprintf('%s ablation comparison', deviceName));
    apply_light_figure_style(gca);
    lgd = legend('Location','best');
    apply_light_legend_style(lgd);
end

end
