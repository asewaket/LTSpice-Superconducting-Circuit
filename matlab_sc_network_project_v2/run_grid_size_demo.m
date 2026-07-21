function gridResults = run_grid_size_demo(deviceName, model, T_vec, Iprobe)
%RUN_GRID_SIZE_DEMO Compare 3x3, 4x4, and 5x5 effective-domain networks.
%
% Usage from the main script:
%   gridResults = run_grid_size_demo('AS005', model, T_vec, Iprobe)
%
% Standalone/default usage from the MATLAB prompt:
%   run_grid_size_demo
%   run_grid_size_demo('AS005')

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

sizes = [3 3; 4 4; 5 5];

for ks = 1:size(sizes,1)
    nLat = sizes(ks,1);
    nLong = sizes(ks,2);
    spec = make_coarse_device_spec(deviceName, nLong, nLat);

    net = build_hallbar_network(spec);
    net = apply_mechanical_proxy(net, spec, model, 'full');

    params = assign_link_parameters(net, spec, model, spec.randomSeed + ks, 'full');
    params = calibrate_normal_resistance(net, spec, params);

    result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
    result.metrics = compute_device_metrics(net, spec, params, result, model);

    label = sprintf('N%d_by_%d', nLat, nLong);
    gridResults.(label).spec = spec;
    gridResults.(label).net = net;
    gridResults.(label).params = params;
    gridResults.(label).result = result;
end

if nargout == 0
    figure('Color','w', 'Name', sprintf('%s coarse-grid demo', deviceName));
    hold on;
    labels = fieldnames(gridResults);
    for k = 1:numel(labels)
        label = labels{k};
        result = gridResults.(label).result;
        plot(result.T, result.R4p.top_4_10, 'LineWidth', 2, ...
            'DisplayName', strrep(label, '_', '\_'));
    end
    grid on;
    xlabel('Temperature T [K]');
    ylabel('R_{4-10} [\Omega]');
    title(sprintf('%s coarse effective-domain grid comparison', deviceName));
    legend('Location','best');
end

end
