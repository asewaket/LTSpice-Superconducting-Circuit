function out = run_phase5A_frozen_rt_transfer(cfg)
%RUN_PHASE5A_FROZEN_RT_TRANSFER Solver-generated Level-A R(T) transfer.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

rtManifest = v800.build_phase5_rt_manifest(cfg);
frozenBasin = v800.select_phase5A_frozen_basin(cfg);
ledger = run_frozen_ledger(cfg, rtManifest, frozenBasin);
summary = summarize_ledger(cfg, ledger);
loo = build_levelA_loo(cfg, ledger);
gates = build_levelA_gates(cfg, rtManifest, ledger, summary, loo);

writetable(rtManifest, cfg.phase5A.rtManifestFile);
writetable(frozenBasin, cfg.phase5A.frozenBasinFile);
writetable(ledger, cfg.phase5A.frozenTransferLedgerFile);
writetable(summary, cfg.phase5A.summaryFile);
writetable(loo, cfg.phase5A.leaveOneOutFile);
writetable(gates, cfg.phase5A.gateResultFile);

try
    h = v800.plot_phase5A_rt_transfer_summary(cfg, ledger, summary, loo, gates);
catch ME
    warning('v8:phase5APlotFailed', ...
        'Phase 5A summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.rtManifest = rtManifest;
out.frozenBasin = frozenBasin;
out.frozenTransferLedger = ledger;
out.summary = summary;
out.leaveOneOut = loo;
out.gates = gates;
out.figure = h;
out.paths = struct();
out.paths.rtManifest = cfg.phase5A.rtManifestFile;
out.paths.frozenBasin = cfg.phase5A.frozenBasinFile;
out.paths.frozenTransferLedger = cfg.phase5A.frozenTransferLedgerFile;
out.paths.summary = cfg.phase5A.summaryFile;
out.paths.leaveOneOut = cfg.phase5A.leaveOneOutFile;
out.paths.gates = cfg.phase5A.gateResultFile;
out.paths.figurePng = [cfg.phase5A.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5A.figureBaseFile '.pdf'];
end

function ledger = run_frozen_ledger(cfg, manifest, basin)
rows = repmat(empty_ledger_row(), max(1, height(manifest) * height(basin)), 1);
rowIdx = 0;

opts = make_v746_gap_weaklink_options();
opts.device = '';
opts.alphaGap.values = unique([cfg.alphaGapValues(:); basin.alpha_gap(isfinite(basin.alpha_gap))]);
opts.gammaW_values = unique([cfg.gammaWValues(:); basin.gammaW(isfinite(basin.gammaW))]);
opts.pW_values = unique([cfg.pWValues(:); basin.pW(isfinite(basin.pW))]);
opts.topologyFilter = unique([cfg.transferTopologyFilter(:); basin.topology], 'stable');
cases = make_v746_gap_weaklink_cases(opts);

for iDevice = 1:height(manifest)
    device = string(manifest.device(iDevice));
    primaryProbe = string(manifest.primary_probe(iDevice));
    expCurve = load_primary_curve(device, primaryProbe);
    deviceState = [];
    for iBasin = 1:height(basin)
        rowIdx = rowIdx + 1;
        rows(rowIdx) = empty_ledger_row();
        rows(rowIdx).device = device;
        rows(rowIdx).primary_probe = primaryProbe;
        rows(rowIdx).experimental_channel = string(manifest.experimental_channel(iDevice));
        rows(rowIdx).calibration_mode = string(basin.calibrationMode(iBasin));
        rows(rowIdx).mechanism = string(basin.mechanism(iBasin));
        rows(rowIdx).role = string(basin.role(iBasin));
        rows(rowIdx).track = string(basin.track(iBasin));
        rows(rowIdx).parameter_basin_id = string(basin.parameter_basin_id(iBasin));
        rows(rowIdx).alpha_gap = basin.alpha_gap(iBasin);
        rows(rowIdx).gammaW = basin.gammaW(iBasin);
        rows(rowIdx).pW = basin.pW(iBasin);
        rows(rowIdx).seed = basin.seed(iBasin);
        rows(rowIdx).phase4_evidence_score = basin.phase4_evidence_score(iBasin);
        rows(rowIdx).selection_note = string(basin.selection_note(iBasin));

        if ~expCurve.available
            rows(rowIdx).run_status = "missing_primary_rt";
            rows(rowIdx).note = expCurve.note;
            continue;
        end

        try
            [model, deviceState] = solve_frozen_case(cfg, device, primaryProbe, ...
                expCurve.T, basin(iBasin, :), opts, cases, deviceState);
            rtScore = v800.score_normalized_rt(expCurve.T, expCurve.R, ...
                model.T, model.R, cfg.phase5A.score);

            rows(rowIdx).RN_exp = rtScore.RN_exp;
            rows(rowIdx).RN_model_precalibration = model.RN_model_precalibration;
            rows(rowIdx).calibration_factor = rows(rowIdx).RN_exp ./ ...
                max(rows(rowIdx).RN_model_precalibration, eps);
            rows(rowIdx).RT_curve_score = rtScore.RT_curve_score;
            rows(rowIdx).onset_score = rtScore.onset_score;
            rows(rowIdx).width_score = rtScore.width_score;
            rows(rowIdx).lowT_score = rtScore.lowT_score;
            rows(rowIdx).total_LevelA_score = rtScore.total_LevelA_score;
            rows(rowIdx).exp_Tonset_K = rtScore.exp_Tonset_K;
            rows(rowIdx).model_Tonset_K = rtScore.model_Tonset_K;
            rows(rowIdx).exp_width90_10_K = rtScore.exp_width90_10_K;
            rows(rowIdx).model_width90_10_K = rtScore.model_width90_10_K;
            rows(rowIdx).exp_rLow = rtScore.exp_rLow;
            rows(rowIdx).model_rLow = rtScore.model_rLow;
            rows(rowIdx).run_status = rtScore.run_status;
            rows(rowIdx).note = model.note;
        catch ME
            rows(rowIdx).run_status = "solver_failed";
            rows(rowIdx).note = string(ME.message);
        end
    end
end

ledger = struct2table(rows(1:rowIdx));
ledger = add_levelA_margins(ledger);
ledger = sortrows(ledger, {'device','total_LevelA_score','role','mechanism'});
end

function [model, state] = solve_frozen_case(cfg, device, primaryProbe, expT, basinRow, opts, cases, state)
seed = basinRow.seed(1);
if isempty(state) || ~isfield(state, 'seed') || state.seed ~= seed
    state = build_device_state(device, primaryProbe, seed, opts);
end

caseInfo = case_from_basin(cases, basinRow);
mode = string(basinRow.calibrationMode(1));
normalScale = NaN;
if mode == "conductance"
    normalScale = normal_scale_for_case(caseInfo, state.fullScaleTable, ...
        state.referenceFullNormalScale);
end

optsCase = opts;
if string(basinRow.mechanism(1)) == "geometry-only Tc"
    optsCase.applyGapDerivedIc = false;
    optsCase.applyWtoRn = false;
end

[netCase, paramsCase] = build_v746_gap_weaklink_case(state.netPDE, ...
    state.spec, state.baseParamsUncal, caseInfo, optsCase, mode, normalScale);

Tvec = transfer_temperature_vector(expT, cfg.phase5A.maxTemperaturePoints);
rt = solve_rt_sweep(netCase, state.spec, paramsCase, Tvec, cfg.phase5A.Iprobe_A);
primary = char(primaryProbe);
if ~isfield(rt.R4p, primary)
    error('Modeled primary probe "%s" was not produced by solve_rt_sweep.', primary);
end

model = struct();
model.T = rt.T;
model.R = rt.R4p.(primary);
model.RN_model_precalibration = normal_state_probe_resistance(netCase, ...
    state.spec, paramsCase, primary, cfg.phase5A.Iprobe_A);
model.note = "solver-generated small-signal R(T) with frozen Phase 4 parameters";
end

function state = build_device_state(device, primaryProbe, seed, opts)
spec = make_device_spec(device);
spec.normalCalibrationProbe = char(primaryProbe);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, ~] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);
baseParamsUncal = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v8_0_phase5A_frozen_rt_base');

[fullScaleTable, referenceFullNormalScale] = build_full_scale_table( ...
    netPDE, spec, baseParamsUncal, opts);

state = struct();
state.device = string(device);
state.primaryProbe = string(primaryProbe);
state.seed = seed;
state.spec = spec;
state.netPDE = netPDE;
state.baseParamsUncal = baseParamsUncal;
state.fullScaleTable = fullScaleTable;
state.referenceFullNormalScale = referenceFullNormalScale;
end

function [fullScaleTable, referenceScale] = build_full_scale_table(netPDE, spec, baseParamsUncal, opts)
cases = make_v746_gap_weaklink_cases(opts);
topologies = strings(numel(cases), 1);
for k = 1:numel(cases)
    topologies(k) = string(cases(k).topology);
end
fullIdx = find(topologies == "combined");
if isempty(fullIdx)
    fullIdx = 1;
end

rows = repmat(struct('caseName', string(''), 'gammaW', NaN, ...
    'pW', NaN, 'alphaGap', NaN, 'normalScale', NaN), numel(fullIdx), 1);
for k = 1:numel(fullIdx)
    caseInfo = cases(fullIdx(k));
    [~, paramsFull] = build_v746_gap_weaklink_case(netPDE, spec, ...
        baseParamsUncal, caseInfo, opts, "shape", NaN);
    rows(k).caseName = string(caseInfo.name);
    rows(k).gammaW = caseInfo.gammaW;
    rows(k).pW = caseInfo.pW;
    rows(k).alphaGap = caseInfo.alphaGap;
    rows(k).normalScale = paramsFull.normalScale;
end
fullScaleTable = struct2table(rows);
referenceScale = fullScaleTable.normalScale(1);
end

function caseInfo = case_from_basin(cases, basinRow)
caseName = string(basinRow.caseName(1));
names = strings(numel(cases), 1);
for k = 1:numel(cases)
    names(k) = string(cases(k).name);
end
idx = find(names == caseName, 1, 'first');
if isempty(idx)
    error('Frozen case "%s" is not in the v7.4.6 case library.', caseName);
end
caseInfo = cases(idx);
end

function normalScale = normal_scale_for_case(caseInfo, fullScaleTable, referenceScale)
normalScale = referenceScale;
if isempty(fullScaleTable) || ~isfinite(caseInfo.gammaW) || ~isfinite(caseInfo.pW)
    return;
end
idx = abs(fullScaleTable.gammaW - caseInfo.gammaW) < 10 .* eps(max(1, abs(caseInfo.gammaW))) & ...
    abs(fullScaleTable.pW - caseInfo.pW) < 10 .* eps(max(1, abs(caseInfo.pW))) & ...
    abs(fullScaleTable.alphaGap - caseInfo.alphaGap) < 10 .* eps(max(1, abs(caseInfo.alphaGap)));
if any(idx)
    normalScale = fullScaleTable.normalScale(find(idx, 1, 'first'));
end
end

function Rn = normal_state_probe_resistance(net, spec, params, primaryProbe, Iprobe)
[Rx, Ry] = link_resistance_T(params, spec, 4.0);
gx = safe_conductance(Rx, net.link.activeX);
gy = safe_conductance(Ry, net.link.activeY);
v = solve_network_linear(net, gx, gy, Iprobe);
R = extract_all_probe_resistances(net, spec, v, Iprobe);
if isfield(R, primaryProbe)
    Rn = R.(primaryProbe);
else
    Rn = NaN;
end
end

function Tvec = transfer_temperature_vector(expT, maxPoints)
Tvec = expT(:);
Tvec = Tvec(isfinite(Tvec));
Tvec = unique(Tvec, 'stable');
Tvec = sort(Tvec);
if isempty(Tvec)
    Tvec = linspace(0.05, 2.20, maxPoints).';
elseif numel(Tvec) > maxPoints
    Tvec = linspace(min(Tvec), max(Tvec), maxPoints).';
end
end

function curve = load_primary_curve(device, primaryProbe)
try
    [~, expRT] = evalc('load_experimental_rt(device);');
catch ME
    expRT = struct('available', false, 'note', ME.message);
end
curve = struct('available', false, 'T', [], 'R', [], 'note', "");
if ~isfield(expRT, 'available') || ~expRT.available
    curve.note = string_field(expRT, 'note', "experimental R(T) unavailable");
    return;
end
primary = char(primaryProbe);
if isfield(expRT, 'pairData') && isfield(expRT.pairData, 'available') && ...
        expRT.pairData.available && isfield(expRT.pairData.R, primary)
    curve.available = true;
    curve.T = expRT.pairData.T;
    curve.R = expRT.pairData.R.(primary);
    curve.note = "explicit primary probe channel";
elseif isfield(expRT, 'R') && isfield(expRT.R, 'main_4p')
    curve.available = true;
    curve.T = expRT.T;
    curve.R = expRT.R.main_4p;
    curve.note = "publication main_4p mapped to declared primary probe";
else
    curve.note = "primary R(T) channel unavailable";
end
end

function ledger = add_levelA_margins(ledger)
if isempty(ledger)
    return;
end
ledger.best_required_control_score = NaN(height(ledger), 1);
ledger.margin_vs_required_controls = NaN(height(ledger), 1);
ledger.beats_required_controls = false(height(ledger), 1);
devices = unique(ledger.device, 'stable');
for i = 1:numel(devices)
    idx = ledger.device == devices(i) & ledger.run_status == "scored";
    controlIdx = idx & ledger.role == "required_control";
    if ~any(controlIdx)
        continue;
    end
    bestControl = min(ledger.total_LevelA_score(controlIdx));
    rows = find(idx);
    ledger.best_required_control_score(rows) = bestControl;
    ledger.margin_vs_required_controls(rows) = bestControl - ledger.total_LevelA_score(rows);
    ledger.beats_required_controls(rows) = ledger.total_LevelA_score(rows) < bestControl;
end
end

function summary = summarize_ledger(cfg, ledger)
rows = repmat(empty_summary_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    rows(k).device = device;
    idx = ledger.device == device & ledger.run_status == "scored";
    rows(k).scored_row_count = sum(idx);
    rows(k).primary_curve_scored = any(idx);
    if ~any(idx)
        rows(k).status = "incomplete";
        rows(k).note = "No scored Level-A ledger rows.";
        continue;
    end
    primaryIdx = idx & ledger.role == "transfer_primary";
    challengerIdx = idx & ledger.role == "required_challenger";
    controlIdx = idx & ledger.role == "required_control";
    [rows(k).best_any_score, anyLocal] = min(ledger.total_LevelA_score(idx));
    allRows = find(idx);
    rows(k).best_any_mechanism = ledger.mechanism(allRows(anyLocal));
    if any(primaryIdx)
        [rows(k).best_primary_score, local] = min(ledger.total_LevelA_score(primaryIdx));
        primaryRows = find(primaryIdx);
        rows(k).best_primary_mechanism = ledger.mechanism(primaryRows(local));
    end
    if any(challengerIdx)
        [rows(k).best_challenger_score, local] = min(ledger.total_LevelA_score(challengerIdx));
        challengerRows = find(challengerIdx);
        rows(k).best_challenger_mechanism = ledger.mechanism(challengerRows(local));
    end
    if any(controlIdx)
        rows(k).best_control_score = min(ledger.total_LevelA_score(controlIdx));
    end
    rows(k).primary_margin_vs_control = rows(k).best_control_score - rows(k).best_primary_score;
    rows(k).primary_beats_controls = rows(k).primary_margin_vs_control > 0;
    if rows(k).primary_beats_controls
        rows(k).status = "pass";
    else
        rows(k).status = "fail";
    end
    rows(k).note = "Frozen Level-A primary R(T) transfer scored.";
end
summary = struct2table(rows);
end

function loo = build_levelA_loo(cfg, ledger)
rows = repmat(empty_loo_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    withheld = string(cfg.devices(k));
    rows(k).withheld_device = withheld;
    trainIdx = ledger.device ~= withheld & ledger.role == "transfer_primary" & ...
        ledger.run_status == "scored";
    rows(k).available_training_device_count = numel(unique(ledger.device(trainIdx)));
    rows(k).training_device_count = numel(cfg.devices) - 1;
    if ~any(trainIdx)
        rows(k).status = "incomplete";
        rows(k).note = "No training devices scored after withholding.";
        continue;
    end
    tracks = unique(ledger.track(trainIdx), 'stable');
    meanScores = NaN(numel(tracks), 1);
    for i = 1:numel(tracks)
        meanScores(i) = finite_mean(ledger.total_LevelA_score(trainIdx & ledger.track == tracks(i)));
    end
    [rows(k).training_mean_score, bestIdx] = min(meanScores);
    rows(k).selected_track = tracks(bestIdx);
    valIdx = ledger.device == withheld & ledger.track == rows(k).selected_track & ...
        ledger.run_status == "scored";
    rows(k).validation_available = any(valIdx);
    if any(valIdx)
        rows(k).validation_margin_vs_controls = max(ledger.margin_vs_required_controls(valIdx));
        rows(k).validation_pass = rows(k).validation_margin_vs_controls > 0;
        rows(k).status = ternary(rows(k).validation_pass, "pass", "fail");
        rows(k).note = "Withheld primary R(T) scored.";
    else
        rows(k).status = "incomplete";
        rows(k).note = "Withheld device has no selected-track score.";
    end
end
loo = struct2table(rows);
end

function gates = build_levelA_gates(cfg, manifest, ledger, summary, loo)
rows = repmat(empty_gate_row(), 6, 1);
row = 0;

row = row + 1;
rows(row).gate = "all_primary_curves_load";
rows(row).required = true;
rows(row).status = ternary(all(manifest.primary_curve_loaded), "pass", "fail");
rows(row).evidence = sprintf('%d/%d primary curves loaded.', ...
    sum(manifest.primary_curve_loaded), height(manifest));
rows(row).note = "Level A uses only declared primary R(T) channels.";

row = row + 1;
rows(row).gate = "all_devices_solver_scored";
rows(row).required = true;
rows(row).status = ternary(all(summary.primary_curve_scored), "pass", "fail");
rows(row).evidence = sprintf('%d/%d devices have solver-generated scores.', ...
    sum(summary.primary_curve_scored), height(summary));
rows(row).note = "No device may be excluded because field-map data are missing.";

row = row + 1;
rows(row).gate = "frozen_tracks_execute";
rows(row).required = true;
tracks = ["combined_physical_bottleneck_basin"; ...
    "contact_relaxed_conductance_basin"; "crack_tunnel_shape_basin"];
ok = true(numel(tracks), 1);
for k = 1:numel(tracks)
    ok(k) = any(ledger.track == tracks(k) & ledger.run_status == "scored");
end
rows(row).status = ternary(all(ok), "pass", "fail");
rows(row).evidence = sprintf('%d/%d frozen tracks have scored rows.', ...
    sum(ok), numel(tracks));
rows(row).note = "Transfer tracks come from Phase 4 basins without refitting.";

row = row + 1;
rows(row).gate = "required_controls_scored";
rows(row).required = true;
controls = ["no weak links"; "uniform weak links"; "shuffled weak links"; ...
    "central-lane / 1D-like"; "geometry-only Tc"; "bulk gap reference"];
ok = true(numel(controls), 1);
for k = 1:numel(controls)
    ok(k) = any(ledger.mechanism == controls(k) & ledger.run_status == "scored");
end
rows(row).status = ternary(all(ok), "pass", "fail");
rows(row).evidence = sprintf('%d/%d required controls have scored rows.', ...
    sum(ok), numel(controls));
rows(row).note = "Controls are protected; beating them is a Level-A test.";

row = row + 1;
rows(row).gate = "beats_required_controls";
rows(row).required = true;
if any(summary.status == "fail")
    rows(row).status = "fail";
elseif all(summary.status == "pass")
    rows(row).status = "pass";
else
    rows(row).status = "incomplete";
end
rows(row).evidence = sprintf('%d pass, %d fail, %d incomplete device rows.', ...
    sum(summary.status == "pass"), sum(summary.status == "fail"), ...
    sum(summary.status == "incomplete"));
rows(row).note = "Best frozen primary track must beat the best protected control.";

row = row + 1;
rows(row).gate = "leave_one_device_out_survival";
rows(row).required = true;
if any(loo.status == "fail")
    rows(row).status = "fail";
elseif all(loo.status == "pass")
    rows(row).status = "pass";
else
    rows(row).status = "incomplete";
end
rows(row).evidence = sprintf('%d pass, %d fail, %d incomplete LOO rows.', ...
    sum(loo.status == "pass"), sum(loo.status == "fail"), ...
    sum(loo.status == "incomplete"));
rows(row).note = "LOO uses only primary R(T), with secondary probes held out.";

gates = struct2table(rows(1:row));
end

function row = empty_ledger_row()
row = struct();
row.device = "";
row.primary_probe = "";
row.experimental_channel = "";
row.calibration_mode = "";
row.mechanism = "";
row.role = "";
row.track = "";
row.parameter_basin_id = "";
row.alpha_gap = NaN;
row.gammaW = NaN;
row.pW = NaN;
row.seed = NaN;
row.phase4_evidence_score = NaN;
row.RN_exp = NaN;
row.RN_model_precalibration = NaN;
row.calibration_factor = NaN;
row.RT_curve_score = NaN;
row.onset_score = NaN;
row.width_score = NaN;
row.lowT_score = NaN;
row.total_LevelA_score = NaN;
row.exp_Tonset_K = NaN;
row.model_Tonset_K = NaN;
row.exp_width90_10_K = NaN;
row.model_width90_10_K = NaN;
row.exp_rLow = NaN;
row.model_rLow = NaN;
row.best_required_control_score = NaN;
row.margin_vs_required_controls = NaN;
row.beats_required_controls = false;
row.run_status = "";
row.selection_note = "";
row.note = "";
end

function row = empty_summary_row()
row = struct();
row.device = "";
row.scored_row_count = 0;
row.primary_curve_scored = false;
row.best_primary_mechanism = "";
row.best_primary_score = NaN;
row.best_challenger_mechanism = "";
row.best_challenger_score = NaN;
row.best_control_score = NaN;
row.primary_margin_vs_control = NaN;
row.primary_beats_controls = false;
row.best_any_mechanism = "";
row.best_any_score = NaN;
row.status = "";
row.note = "";
end

function row = empty_loo_row()
row = struct();
row.withheld_device = "";
row.training_device_count = 0;
row.available_training_device_count = 0;
row.selected_track = "";
row.training_mean_score = NaN;
row.validation_available = false;
row.validation_margin_vs_controls = NaN;
row.validation_pass = false;
row.status = "";
row.note = "";
end

function row = empty_gate_row()
row = struct();
row.gate = "";
row.required = false;
row.status = "";
row.evidence = "";
row.note = "";
end

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function out = ternary(tf, a, b)
if tf
    out = a;
else
    out = b;
end
end

function out = string_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    out = string(s.(name));
else
    out = string(defaultValue);
end
end
