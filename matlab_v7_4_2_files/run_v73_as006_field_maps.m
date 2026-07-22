%RUN_V73_AS006_FIELD_MAPS PDE/Raman-informed AS006 dV/dI(I,B) scaffold.

clear;
clc;

projectDir = add_v73_paths();

outDir = fullfile(projectDir, 'outputs', 'v7_3_as006_field_maps');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

device = 'AS006';
spec = make_device_spec(device);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
expField = load_v73_experimental_field_dvdi(device);
fieldOpts = make_v73_field_options(expField);

fprintf('\nRunning v7.3 out-of-plane magnetic-field scaffold for %s\n', device);
fprintf('Film force: %s\n', spec.filmForceLabel);
fprintf('Field direction: %s\n', fieldOpts.fieldDirection);
fprintf('Field range: %.3g to %.3g mT, %d B points\n', ...
    1e3 * min(fieldOpts.B_vec_T), 1e3 * max(fieldOpts.B_vec_T), ...
    numel(fieldOpts.B_vec_T));
fprintf('Current range: %.3g to %.3g uA, %d I points\n', ...
    1e6 * min(fieldOpts.I_vec_A), 1e6 * max(fieldOpts.I_vec_A), ...
    numel(fieldOpts.I_vec_A));
fprintf('Assumed fixed T for field sweep: %.4g K\n', fieldOpts.T_K);

netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
params = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v7_3_pde_field');
params = calibrate_normal_resistance(netPDE, spec, params);

field = solve_v73_field_dvdi_map(netPDE, spec, params, fieldOpts);
score = compute_v73_field_score(field, expField);

h = plot_v73_as006_field_summary(spec, field, expField, score);
export_chapter_figure(h, outDir, 'AS006_v7_3_field_dVdI_maps');

summary = make_summary(spec, fieldOpts, expField, score, netPDE);
writetable(struct2table(summary), ...
    fullfile(outDir, 'AS006_v7_3_field_summary.csv'));
save(fullfile(outDir, 'AS006_v7_3_field_maps.mat'), ...
    'spec', 'modelParams', 'pdeOpts', 'fieldOpts', 'netGeometry', 'netPDE', ...
    'pde', 'pdeMap', 'params', 'field', 'expField', 'score', 'summary');

fprintf('\nFinished v7.3 AS006 field maps.\n');
if score.available
    fprintf('Combined field score: %.4g\n', score.combined);
    disp(score.pairScores);
else
    fprintf('Field score unavailable: %s\n', score.message);
end
fprintf('Outputs written to:\n%s\n', outDir);

function row = make_summary(spec, fieldOpts, expField, score, net)

row = struct();
row.device = string(spec.name);
row.version = string('v7.3');
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
