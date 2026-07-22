%% run_six_device_scaffold.m
%
% v4 six-device MoTe2 Hall-bar superconducting-network scaffold.
%
% This code builds directly on the idea in Res_Array_1.m:
% each nearest-neighbor link has a local (Rn, Tc, Ic) triple, and the link
% resistance is determined by smooth temperature/current switching.
%
% v4 includes:
%   - old/new Hall-bar geometry masks
%   - explicit source and drain contacts
%   - internal passive voltage probes
%   - four-probe R extraction
%   - region masks for control, full coverage, half coverage, and cracking
%   - geometry-derived mechanical proxy eta(x,y)
%   - shared eta -> (Rn,Tc,Ic) rules across AS001--AS006
%   - small ensemble runs and qualitative metrics
%   - experimental R(T) import and model/experiment overlays where mapped
%
% MB/ChatGPT scaffold, July 2026

clear; close all; clc;

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

outDir = fullfile(thisDir, 'outputs');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

chapterFigDir = fullfile(outDir, 'chapter_figures');
if ~exist(chapterFigDir, 'dir')
    mkdir(chapterFigDir);
end

metricDir = fullfile(outDir, 'metric_tables');
if ~exist(metricDir, 'dir')
    mkdir(metricDir);
end

sensitivityDir = fullfile(outDir, 'sensitivity');
if ~exist(sensitivityDir, 'dir')
    mkdir(sensitivityDir);
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
    expData = load_experimental_rt(name);

    allResults(kd).name = name;
    allResults(kd).spec = spec;
    allResults(kd).net = net;
    allResults(kd).params = params;
    allResults(kd).result = result;
    allResults(kd).ensemble = ensemble;
    allResults(kd).expData = expData;

    hGeom = plot_device_spec(net, spec);
    export_chapter_figure(hGeom, chapterFigDir, sprintf('%s_geometry_masks', name));

    hRT = figure('Color','w', 'Name', sprintf('%s R(T)', name));
    hold on;
    pairNames = fieldnames(result.R4p);
    for kp = 1:numel(pairNames)
        pName = pairNames{kp};
        plot(T_vec, result.R4p.(pName), 'LineWidth', 2, ...
            'DisplayName', strrep(pName, '_', '\_'));
    end
    xlabel('Temperature T [K]');
    ylabel('Four-probe resistance [\Omega]');
    title(sprintf('%s: scaffold R(T), %s', spec.name, spec.filmForceLabel));
    apply_light_figure_style(gca);
    lgd = legend('Location','best');
    apply_light_legend_style(lgd);
    export_chapter_figure(hRT, chapterFigDir, sprintf('%s_RT_scaffold', name));

    hEns = plot_ensemble_rt(spec, ensemble);
    export_chapter_figure(hEns, chapterFigDir, sprintf('%s_RT_ensemble', name));

    [hAbs, hNorm] = plot_model_experiment_overlay(spec, result, ensemble, expData);
    export_chapter_figure(hAbs, chapterFigDir, sprintf('%s_model_exp_absolute', name));
    export_chapter_figure(hNorm, chapterFigDir, sprintf('%s_model_exp_normalized', name));
end

ablationResults = run_ablation_demo('AS005', model, T_vec, Iprobe);
save(fullfile(outDir, 'AS005_ablation_demo.mat'), 'ablationResults');

as005NullSuite = run_as005_null_model_suite(model, T_vec, Iprobe);
save(fullfile(outDir, 'AS005_null_model_suite.mat'), 'as005NullSuite');
hAS005Null = plot_as005_null_model_tests(as005NullSuite);
export_chapter_figure(hAS005Null, chapterFigDir, 'AS005_geometry_dimensionality_null_model_tests');

gridSizeResults = run_grid_size_demo('AS005', model, T_vec, Iprobe);
save(fullfile(outDir, 'AS005_grid_size_demo.mat'), 'gridSizeResults');

save(fullfile(outDir, 'six_device_scaffold_results.mat'), 'allResults');

hSixNorm = plot_six_device_normalized_comparison(allResults);
export_chapter_figure(hSixNorm, chapterFigDir, 'six_device_model_exp_normalized_comparison');

metricTables = build_rt_metric_tables(allResults, metricDir);
save(fullfile(metricDir, 'rt_metric_tables.mat'), 'metricTables');

sensitivityOptions = make_sensitivity_options();
sensitivitySweep = run_proxy_sensitivity_sweep(sensitivityOptions, sensitivityDir);

fprintf('Saved scaffold figures and results to:\n%s\n', outDir);
