%RUN_V741_AS006_WEAKLINK_FIELD_MAPS Strong weak-link/Josephson bottleneck scaffold.
%
% This v7.4.1 runner starts from the v7.3 AS006 out-of-plane-field workflow
% and adds a selected subset of low-Ic, sharp-switching weak links. The goal
% is to test whether bottleneck nonlinearity can produce stronger low-bias
% dV/dI(I,B) structure than the smoother v7.3 field-only scaffold.

clear;
clc;

projectDir = add_v741_paths();

outDir = fullfile(projectDir, 'outputs', 'v7_4_1_as006_weaklink_field_maps');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

device = 'AS006';
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
expField = load_v73_experimental_field_dvdi(device);
fieldOpts = make_v73_field_options(expField);
fieldOpts.version = 'v7.4.1';
weakOpts = make_v741_weaklink_options(spec);

fprintf('\nRunning v7.4.1 weak-link magnetic-field scaffold for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);
fprintf('Field direction: %s\n', fieldOpts.fieldDirection);
fprintf('Field range: %.3g to %.3g mT, %d B points\n', ...
    1e3 * min(fieldOpts.B_vec_T), 1e3 * max(fieldOpts.B_vec_T), ...
    numel(fieldOpts.B_vec_T));
fprintf('Current range: %.3g to %.3g uA, %d I points\n', ...
    1e6 * min(fieldOpts.I_vec_A), 1e6 * max(fieldOpts.I_vec_A), ...
    numel(fieldOpts.I_vec_A));
fprintf('Weak-link Ic multiplier: %.3g\n', weakOpts.IcMultiplier);
fprintf('Weak-link switch width: %.3g Ic\n', weakOpts.weakSwitchWidthFrac);

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
params = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v7_4_1_pde_field_weaklinks');
params = calibrate_normal_resistance(netPDE, spec, params);
[params, weak] = apply_v741_weaklink_bottlenecks(params, netPDE, spec, weakOpts);

field = solve_v741_field_dvdi_map(netPDE, spec, params, fieldOpts, weak);
score = compute_v73_field_score(field, expField);

hField = plot_v741_as006_field_summary(spec, field, expField, score);
export_chapter_figure(hField, outDir, 'AS006_v7_4_1_weaklink_field_dVdI_maps');

hWeak = plot_v741_weaklink_diagnostics(spec, netPDE, weak, params);
export_chapter_figure(hWeak, outDir, 'AS006_v7_4_1_weaklink_diagnostics');

summary = make_summary(spec, fieldOpts, weakOpts, expField, score, netPDE, weak);
writetable(struct2table(summary), ...
    fullfile(outDir, 'AS006_v7_4_1_weaklink_field_summary.csv'));
save(fullfile(outDir, 'AS006_v7_4_1_weaklink_field_maps.mat'), ...
    'spec', 'modelParams', 'pdeOpts', 'fieldOpts', 'weakOpts', ...
    'netGeometry', 'netPDE', 'pde', 'pdeMap', 'params', 'weak', ...
    'field', 'expField', 'score', 'summary');

fprintf('\nFinished v7.4.1 AS006 weak-link field maps.\n');
if score.available
    fprintf('Combined field score: %.4g\n', score.combined);
    disp(score.pairScores);
else
    fprintf('Field score unavailable: %s\n', score.message);
end
fprintf('Weak-link active-link fraction: %.4g\n', weak.activeLinkFraction);
fprintf('Outputs written to:\n%s\n', outDir);

function row = make_summary(spec, fieldOpts, weakOpts, expField, score, net, weak)

row = struct();
row.device = string(spec.name);
row.version = string('v7.4.1');
row.filmForce_Npm = spec.filmForce_Npm;
row.filmForceLabel = string(spec.filmForceLabel);
row.fieldDirection = string(fieldOpts.fieldDirection);
row.assumedFieldSweepTemperature_K = fieldOpts.T_K;
row.Bmin_T = min(fieldOpts.B_vec_T);
row.Bmax_T = max(fieldOpts.B_vec_T);
row.Imin_A = min(fieldOpts.I_vec_A);
row.Imax_A = max(fieldOpts.I_vec_A);
row.experimentalFieldFile = string(expField.filePath);
row.experimentalFieldAvailable = expField.available;
row.meanEta = mean(net.etaNode(net.active), 'omitnan');
row.maxEta = max(net.etaNode(net.active), [], 'omitnan');
row.weakLinkFraction = weak.activeLinkFraction;
row.weakIcMultiplier = weakOpts.IcMultiplier;
row.weakRnMultiplier = weakOpts.RnMultiplier;
row.weakSwitchWidthFrac = weakOpts.weakSwitchWidthFrac;
row.currentBroadening_A = weakOpts.currentBroadening_A;
row.hysteresisEnabled = weakOpts.hysteresis.enabled;

row.fieldScoreCombined = NaN;
row.fieldScoreTop_4_10 = NaN;
row.fieldScoreBottom_3_9 = NaN;
row.mapRmsTop_4_10 = NaN;
row.mapRmsBottom_3_9 = NaN;
row.zeroBiasRmsTop_4_10 = NaN;
row.zeroBiasRmsBottom_3_9 = NaN;

if isfield(score, 'available') && score.available
    row.fieldScoreCombined = score.combined;
    row.fieldScoreTop_4_10 = get_score_field(score.pairScores, 'top_4_10');
    row.fieldScoreBottom_3_9 = get_score_field(score.pairScores, 'bottom_3_9');
    row.mapRmsTop_4_10 = get_score_field(score.mapRms, 'top_4_10');
    row.mapRmsBottom_3_9 = get_score_field(score.mapRms, 'bottom_3_9');
    row.zeroBiasRmsTop_4_10 = get_score_field(score.zeroBiasRms, 'top_4_10');
    row.zeroBiasRmsBottom_3_9 = get_score_field(score.zeroBiasRms, 'bottom_3_9');
end

end

function val = get_score_field(s, fieldName)

if isfield(s, fieldName)
    val = s.(fieldName);
else
    val = NaN;
end

end
