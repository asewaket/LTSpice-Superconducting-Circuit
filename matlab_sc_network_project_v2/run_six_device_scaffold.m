%% run_six_device_scaffold.m
%
% v2 six-device MoTe2 Hall-bar superconducting-network scaffold.
%
% This code builds directly on the idea in Res_Array_1.m:
% each nearest-neighbor link has a local (Rn, Tc, Ic) triple, and the link
% resistance is determined by smooth temperature/current switching.
%
% v2 adds:
%   - old/new Hall-bar geometry masks
%   - explicit source and drain contacts
%   - internal passive voltage probes
%   - four-probe R extraction
%   - region masks for control, full coverage, half coverage, and cracking
%   - geometry-derived mechanical proxy eta(x,y)
%   - shared eta -> (Rn,Tc,Ic) rules across AS001--AS006
%   - small ensemble runs and qualitative metrics
%
% MB/ChatGPT scaffold, July 2026

clear; close all; clc;

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

outDir = fullfile(thisDir, 'outputs');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

deviceNames = {'AS001','AS002','AS003','AS004','AS005','AS006'};
model = make_shared_model_params();

T_vec = linspace(0.05, 2.20, 160);     % K
Iprobe = 1e-8;                         % A, small-signal current

allResults = struct();

for kd = 1:numel(deviceNames)
    name = deviceNames{kd};

    spec = make_device_spec(name);
    spec.sim.T_vec = T_vec;
    spec.sim.Iprobe = Iprobe;

    net = build_hallbar_network(spec);
    net = apply_mechanical_proxy(net, spec, model, 'full');

    params = assign_link_parameters(net, spec, model, spec.randomSeed, 'full');
    params = calibrate_normal_resistance(net, spec, params);

    result = solve_rt_sweep(net, spec, params, T_vec, Iprobe);
    result.metrics = compute_device_metrics(net, spec, params, result, model);

    ensemble = run_device_ensemble(spec, model, T_vec, Iprobe, model.ensemble.N, 'full');

    allResults(kd).name = name;
    allResults(kd).spec = spec;
    allResults(kd).net = net;
    allResults(kd).params = params;
    allResults(kd).result = result;
    allResults(kd).ensemble = ensemble;

    hGeom = plot_device_spec(net, spec);
    saveas(hGeom, fullfile(outDir, sprintf('%s_geometry_masks.png', name)));

    hRT = figure('Color','w', 'Name', sprintf('%s R(T)', name));
    hold on;
    pairNames = fieldnames(result.R4p);
    for kp = 1:numel(pairNames)
        pName = pairNames{kp};
        plot(T_vec, result.R4p.(pName), 'LineWidth', 2, ...
            'DisplayName', strrep(pName, '_', '\_'));
    end
    grid on;
    xlabel('Temperature T [K]');
    ylabel('Four-probe resistance [\Omega]');
    title(sprintf('%s: scaffold R(T), %s', spec.name, spec.filmForceLabel));
    legend('Location','best');
    saveas(hRT, fullfile(outDir, sprintf('%s_RT_scaffold.png', name)));

    hEns = plot_ensemble_rt(spec, ensemble);
    saveas(hEns, fullfile(outDir, sprintf('%s_RT_ensemble.png', name)));
end

ablationResults = run_ablation_demo('AS005', model, T_vec, Iprobe);
save(fullfile(outDir, 'AS005_ablation_demo.mat'), 'ablationResults');

gridSizeResults = run_grid_size_demo('AS005', model, T_vec, Iprobe);
save(fullfile(outDir, 'AS005_grid_size_demo.mat'), 'gridSizeResults');

save(fullfile(outDir, 'six_device_scaffold_results.mat'), 'allResults');

fprintf('Saved scaffold figures and results to:\n%s\n', outDir);
