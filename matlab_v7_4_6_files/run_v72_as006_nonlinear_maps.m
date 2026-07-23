%RUN_V72_AS006_NONLINEAR_MAPS Nonlinear Ic/dVdI/current-map scaffold for AS006.

clear;
clc;

projectDir = add_v73_paths();

outDir = fullfile(projectDir, 'outputs', 'v7_2_2_as006_nonlinear_maps');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

device = 'AS006';
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);

fprintf('\nRunning v7.2.2 nonlinear current-dependent scaffold for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, modelParams, pde, pdeOpts);

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
params = assign_link_parameters(netPDE, spec, modelParams, seed, 'v7_2_pde_nonlinear');
params = calibrate_normal_resistance(netPDE, spec, params);

nlOpts = make_v72_nonlinear_options(params, netPDE);
fprintf('Nonlinear current sweep: %.3g to %.3g uA, %d current points, %d T points\n', ...
    1e6 * min(nlOpts.I_vec), 1e6 * max(nlOpts.I_vec), ...
    numel(nlOpts.I_vec), numel(nlOpts.T_vec));

nl = solve_v72_dvdi_map(netPDE, spec, params, nlOpts);
maps = compute_v72_state_maps(netPDE, spec, params, nlOpts);
expData = load_experimental_rt(device);
expDvdI = load_v722_experimental_dvdi(device);

h = plot_v72_as006_nonlinear_summary(spec, netPDE, pdeMap, nl, maps, expData, expDvdI);
export_chapter_figure(h, outDir, 'AS006_v7_2_2_nonlinear_dVdI_current_maps');

summary = struct();
summary.device = device;
summary.version = 'v7.2.2';
summary.filmForce_Npm = spec.filmForce_Npm;
summary.filmForceLabel = spec.filmForceLabel;
summary.Imax_A = nlOpts.Imax_A;
summary.Tmap_K = maps.T_K;
summary.I_low_A = maps.I_low_A;
summary.I_high_A = maps.I_high_A;
summary.low_switchedFraction = maps.low.switchedFraction;
summary.high_switchedFraction = maps.high.switchedFraction;
summary.maxSwitchedFraction = max(nl.switchedFraction(:), [], 'omitnan');
summary.maxAbsIOverIc = max(nl.maxAbsIOverIc(:), [], 'omitnan');
summary.experimentalDvdIAvailable = expDvdI.available;
summary.meanEta = mean(netPDE.etaNode(netPDE.active), 'omitnan');
summary.maxEta = max(netPDE.etaNode(netPDE.active), [], 'omitnan');

writetable(struct2table(flatten_summary(summary)), ...
    fullfile(outDir, 'AS006_v7_2_2_nonlinear_summary.csv'));
save(fullfile(outDir, 'AS006_v7_2_2_nonlinear_maps.mat'), ...
    'spec', 'modelParams', 'pdeOpts', 'nlOpts', 'netGeometry', 'netPDE', ...
    'pde', 'pdeMap', 'params', 'nl', 'maps', 'expData', 'expDvdI', 'summary');

fprintf('\nFinished v7.2.2 AS006 nonlinear maps.\n');
fprintf('Outputs written to:\n%s\n', outDir);

function row = flatten_summary(summary)

row = struct();
row.device = string(summary.device);
row.version = string(summary.version);
row.filmForce_Npm = summary.filmForce_Npm;
row.filmForceLabel = string(summary.filmForceLabel);
row.Imax_A = summary.Imax_A;
row.Tmap_K = summary.Tmap_K;
row.I_low_A = summary.I_low_A;
row.I_high_A = summary.I_high_A;
row.low_switchedFraction = summary.low_switchedFraction;
row.high_switchedFraction = summary.high_switchedFraction;
row.maxSwitchedFraction = summary.maxSwitchedFraction;
row.maxAbsIOverIc = summary.maxAbsIOverIc;
row.experimentalDvdIAvailable = summary.experimentalDvdIAvailable;
row.meanEta = summary.meanEta;
row.maxEta = summary.maxEta;

end
