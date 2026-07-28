function out = run_phase5B_secondary_validation(cfg)
%RUN_PHASE5B_SECONDARY_VALIDATION Held-out probe and hierarchy validation.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

freezeManifest = build_freeze_manifest(cfg);
rtManifest = readtable(cfg.phase5A.rtManifestFile, 'TextType', 'string');
frozenBasin = readtable(cfg.phase5A.frozenBasinFile, 'TextType', 'string');
primaryLedger = readtable(cfg.phase5A.frozenTransferLedgerFile, 'TextType', 'string');
primarySummary = readtable(cfg.phase5A.summaryFile, 'TextType', 'string');

secondaryManifest = build_secondary_manifest(rtManifest);
secondaryLedger = build_secondary_ledger(cfg, secondaryManifest, frozenBasin);
deviceEvidence = build_device_evidence(cfg, primaryLedger, primarySummary, ...
    secondaryManifest, secondaryLedger);
classHeldout = build_class_heldout(cfg, primaryLedger);
activationPlan = build_activation_plan(cfg);
gateResults = build_phase5B_gates(cfg, freezeManifest, secondaryManifest, ...
    secondaryLedger, deviceEvidence, classHeldout);

writetable(freezeManifest, cfg.phase5B.freezeManifestFile);
writetable(secondaryManifest, cfg.phase5B.secondaryManifestFile);
writetable(secondaryLedger, cfg.phase5B.secondaryLedgerFile);
writetable(deviceEvidence, cfg.phase5B.deviceEvidenceFile);
writetable(classHeldout, cfg.phase5B.classHeldoutFile);
writetable(activationPlan, cfg.phase5B.activationPlanFile);
writetable(gateResults, cfg.phase5B.gateResultFile);

try
    h = v800.plot_phase5B_secondary_summary(cfg, secondaryLedger, ...
        deviceEvidence, classHeldout, gateResults);
catch ME
    warning('v8:phase5BPlotFailed', ...
        'Phase 5B summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.freezeManifest = freezeManifest;
out.secondaryManifest = secondaryManifest;
out.secondaryLedger = secondaryLedger;
out.deviceEvidence = deviceEvidence;
out.classHeldout = classHeldout;
out.activationPlan = activationPlan;
out.gateResults = gateResults;
out.figure = h;
out.paths = struct();
out.paths.freezeManifest = cfg.phase5B.freezeManifestFile;
out.paths.secondaryManifest = cfg.phase5B.secondaryManifestFile;
out.paths.secondaryLedger = cfg.phase5B.secondaryLedgerFile;
out.paths.deviceEvidence = cfg.phase5B.deviceEvidenceFile;
out.paths.classHeldout = cfg.phase5B.classHeldoutFile;
out.paths.activationPlan = cfg.phase5B.activationPlanFile;
out.paths.gateResults = cfg.phase5B.gateResultFile;
out.paths.figurePng = [cfg.phase5B.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5B.figureBaseFile '.pdf'];
end

function freeze = build_freeze_manifest(cfg)
files = [
    string(cfg.phase5A.rtManifestFile)
    string(cfg.phase5A.frozenBasinFile)
    string(cfg.phase5A.frozenTransferLedgerFile)
    string(cfg.phase5A.summaryFile)
    string(cfg.phase5A.leaveOneOutFile)
    string(cfg.phase5A.gateResultFile)
    ];
rows = repmat(struct('artifact', "", 'path', "", 'exists', false, ...
    'bytes', NaN, 'modified_datenum', NaN, 'commit_sha', "", ...
    'freeze_policy', ""), numel(files), 1);
commitSha = v800.git_commit_sha(cfg.repoRoot);
for k = 1:numel(files)
    info = dir(files(k));
    rows(k).artifact = string(strip_phase5A_name(files(k)));
    rows(k).path = string(files(k));
    rows(k).exists = ~isempty(info);
    if ~isempty(info)
        rows(k).bytes = info.bytes;
        rows(k).modified_datenum = info.datenum;
    end
    rows(k).commit_sha = string(commitSha);
    rows(k).freeze_policy = "Phase 5A probes, weights, controls, seeds, and basins are frozen before Phase 5B.";
end
freeze = struct2table(rows);
end

function name = strip_phase5A_name(pathValue)
[~, name, ext] = fileparts(char(pathValue));
name = [name ext];
end

function manifest = build_secondary_manifest(rtManifest)
rows = repmat(empty_secondary_manifest_row(), height(rtManifest), 1);
for k = 1:height(rtManifest)
    device = string(rtManifest.device(k));
    primary = string(rtManifest.primary_probe(k));
    secondary = string(rtManifest.secondary_probe(k));
    pair = load_pair_curves(device);
    rows(k).device = device;
    rows(k).primary_probe = primary;
    rows(k).secondary_probe = secondary;
    rows(k).secondary_status = string(rtManifest.secondary_status(k));
    rows(k).pair_source = pair.source;
    rows(k).top_available = pair.topAvailable;
    rows(k).bottom_available = pair.bottomAvailable;
    rows(k).secondary_curve_available = pair.available && ...
        ((secondary == "top_4_10" && pair.topAvailable) || ...
        (secondary == "bottom_3_9" && pair.bottomAvailable));
    rows(k).asymmetry_available = pair.topAvailable && pair.bottomAvailable;
    if rows(k).secondary_curve_available && rows(k).asymmetry_available
        rows(k).phase5B_status = "ready_secondary_probe";
    elseif rows(k).secondary_curve_available
        rows(k).phase5B_status = "ready_secondary_curve_only";
    else
        rows(k).phase5B_status = "not_applicable";
    end
    rows(k).note = pair.note;
end
manifest = struct2table(rows);
end

function ledger = build_secondary_ledger(cfg, manifest, basin)
rows = repmat(empty_secondary_ledger_row(), max(1, height(manifest) * height(basin)), 1);
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
    secondaryProbe = string(manifest.secondary_probe(iDevice));
    pair = load_pair_curves(device);
    deviceState = [];
    for iBasin = 1:height(basin)
        rowIdx = rowIdx + 1;
        rows(rowIdx) = empty_secondary_ledger_row();
        rows(rowIdx).device = device;
        rows(rowIdx).primary_probe = primaryProbe;
        rows(rowIdx).secondary_probe = secondaryProbe;
        rows(rowIdx).mechanism = string(basin.mechanism(iBasin));
        rows(rowIdx).role = string(basin.role(iBasin));
        rows(rowIdx).track = string(basin.track(iBasin));
        rows(rowIdx).model_level = model_level_for(string(basin.mechanism(iBasin)));
        rows(rowIdx).complexity_K = complexity_for(rows(rowIdx).model_level);
        rows(rowIdx).parameter_basin_id = string(basin.parameter_basin_id(iBasin));
        rows(rowIdx).calibration_mode = string(basin.calibrationMode(iBasin));
        rows(rowIdx).alpha_gap = basin.alpha_gap(iBasin);
        rows(rowIdx).gammaW = basin.gammaW(iBasin);
        rows(rowIdx).pW = basin.pW(iBasin);
        rows(rowIdx).seed = basin.seed(iBasin);

        if ~pair.available
            rows(rowIdx).run_status = "secondary_pair_unavailable";
            rows(rowIdx).note = pair.note;
            continue;
        end
        if ~secondary_available(pair, secondaryProbe)
            rows(rowIdx).run_status = "secondary_curve_unavailable";
            rows(rowIdx).note = "Declared secondary probe is not present in pairData.";
            continue;
        end

        try
            [model, deviceState] = solve_secondary_case(cfg, device, ...
                primaryProbe, pair.T, basin(iBasin, :), opts, cases, deviceState);
            expSecondary = pair_curve(pair, secondaryProbe);
            modelSecondary = model_curve(model, secondaryProbe);
            secScore = v800.score_normalized_rt(pair.T, expSecondary, ...
                model.T, modelSecondary, cfg.phase5A.score);
            asymScore = v800.score_probe_asymmetry(pair.T, pair.top, pair.bottom, ...
                model.T, model.top, model.bottom, cfg.phase5B);
            rows(rowIdx).secondary_curve_score = secScore.total_LevelA_score;
            rows(rowIdx).secondary_RT_curve_score = secScore.RT_curve_score;
            rows(rowIdx).secondary_onset_score = secScore.onset_score;
            rows(rowIdx).secondary_width_score = secScore.width_score;
            rows(rowIdx).secondary_lowT_score = secScore.lowT_score;
            rows(rowIdx).asymmetry_score = asymScore.asymmetry_score;
            rows(rowIdx).asymmetry_curve_score = asymScore.asymmetry_curve_score;
            rows(rowIdx).exp_ordering = asymScore.exp_ordering;
            rows(rowIdx).model_ordering = asymScore.model_ordering;
            rows(rowIdx).ordering_match = asymScore.ordering_match;
            rows(rowIdx).exp_max_asymmetry = asymScore.exp_max_asymmetry;
            rows(rowIdx).model_max_asymmetry = asymScore.model_max_asymmetry;
            rows(rowIdx).exp_lowT_asymmetry = asymScore.exp_lowT_asymmetry;
            rows(rowIdx).model_lowT_asymmetry = asymScore.model_lowT_asymmetry;
            rows(rowIdx).exp_integrated_asymmetry = asymScore.exp_integrated_asymmetry;
            rows(rowIdx).model_integrated_asymmetry = asymScore.model_integrated_asymmetry;
            rows(rowIdx).secondary_total_score = combine_secondary_scores(cfg, secScore, asymScore);
            rows(rowIdx).penalized_secondary_score = rows(rowIdx).secondary_total_score + ...
                cfg.phase5B.complexityPenaltyLambda .* rows(rowIdx).complexity_K;
            rows(rowIdx).run_status = "scored";
            rows(rowIdx).note = "Secondary probe scored with primary-probe calibration frozen.";
        catch ME
            rows(rowIdx).run_status = "solver_failed";
            rows(rowIdx).note = string(ME.message);
        end
    end
end

ledger = struct2table(rows(1:rowIdx));
ledger = add_secondary_margins(ledger);
ledger = sortrows(ledger, {'device','penalized_secondary_score','role','mechanism'});
end

function total = combine_secondary_scores(cfg, secScore, asymScore)
terms = [secScore.total_LevelA_score, asymScore.asymmetry_score];
weights = [cfg.phase5B.secondaryWeight, cfg.phase5B.asymmetryWeight];
valid = isfinite(terms) & isfinite(weights) & weights > 0;
if any(valid)
    total = sum(weights(valid) .* terms(valid)) ./ sum(weights(valid));
else
    total = NaN;
end
end

function ledger = add_secondary_margins(ledger)
ledger.best_secondary_control_score = NaN(height(ledger), 1);
ledger.secondary_margin_vs_controls = NaN(height(ledger), 1);
ledger.secondary_beats_controls = false(height(ledger), 1);
devices = unique(ledger.device, 'stable');
for i = 1:numel(devices)
    idx = ledger.device == devices(i) & ledger.run_status == "scored";
    controlIdx = idx & ledger.role == "required_control";
    if ~any(controlIdx)
        continue;
    end
    bestControl = min(ledger.penalized_secondary_score(controlIdx));
    rows = find(idx);
    ledger.best_secondary_control_score(rows) = bestControl;
    ledger.secondary_margin_vs_controls(rows) = bestControl - ledger.penalized_secondary_score(rows);
    ledger.secondary_beats_controls(rows) = ledger.penalized_secondary_score(rows) < bestControl;
end
end

function evidence = build_device_evidence(cfg, primaryLedger, primarySummary, secondaryManifest, secondaryLedger)
rows = repmat(empty_evidence_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    rows(k).device = device;
    rows(k).regime_prior = regime_prior(device, cfg);
    rows(k).primary_status = primary_status(device, primarySummary);
    [pLevel, pScore] = preferred_primary_level(cfg, device, primaryLedger);
    rows(k).primary_preferred_model = pLevel;
    rows(k).primary_penalized_score = pScore;

    mIdx = secondaryManifest.device == device;
    if any(mIdx)
        rows(k).secondary_probe_status = string(secondaryManifest.phase5B_status(find(mIdx, 1, 'first')));
    end
    sIdx = secondaryLedger.device == device & secondaryLedger.run_status == "scored";
    if any(sIdx)
        [sLevel, sScore, bestRow] = preferred_secondary_level(device, secondaryLedger);
        rows(k).secondary_preferred_model = sLevel;
        rows(k).secondary_penalized_score = sScore;
        rows(k).secondary_best_mechanism = string(secondaryLedger.mechanism(bestRow));
        rows(k).asymmetry_ordering_exp = string(secondaryLedger.exp_ordering(bestRow));
        rows(k).asymmetry_ordering_model = string(secondaryLedger.model_ordering(bestRow));
        rows(k).asymmetry_ordering_match = logical(secondaryLedger.ordering_match(bestRow));
        rows(k).secondary_margin_vs_controls = secondaryLedger.secondary_margin_vs_controls(bestRow);
    else
        rows(k).secondary_preferred_model = "not_applicable";
        rows(k).secondary_best_mechanism = "";
    end

    rows(k).preferred_model = combine_primary_secondary(rows(k));
    rows(k).evidence_conclusion = conclusion_for_device(rows(k));
end
evidence = struct2table(rows);
end

function [level, score] = preferred_primary_level(cfg, device, ledger)
idx = ledger.device == device & ledger.run_status == "scored";
levels = ["M0"; "M1"; "M2"];
scores = NaN(numel(levels), 1);
for i = 1:numel(levels)
    lidx = idx & model_level_mask(ledger.mechanism, levels(i));
    if any(lidx)
        kVal = complexity_for(levels(i));
        scores(i) = min(ledger.total_LevelA_score(lidx)) + ...
            cfg.phase5B.complexityPenaltyLambda .* kVal;
    end
end
[score, local] = min(scores);
if isfinite(score)
    level = levels(local);
else
    level = "unresolved";
end
end

function [level, score, bestRow] = preferred_secondary_level(device, ledger)
idx = ledger.device == device & ledger.run_status == "scored" & ...
    ismember(ledger.model_level, ["M0"; "M1"; "M2"]);
if ~any(idx)
    level = "unresolved";
    score = NaN;
    bestRow = NaN;
    return;
end
[score, local] = min(ledger.penalized_secondary_score(idx));
rows = find(idx);
bestRow = rows(local);
level = string(ledger.model_level(bestRow));
end

function heldout = build_class_heldout(cfg, primaryLedger)
devices = cfg.phase5B.halfEncapsulatedDevices(:);
rows = repmat(empty_heldout_row(), numel(devices) + 1, 1);
for k = 1:numel(devices)
    withheld = devices(k);
    rows(k).test = "within_half_encapsulated";
    rows(k).withheld_device = withheld;
    trainDevices = devices(devices ~= withheld);
    [selectedLevel, trainScore] = best_level_for_devices(cfg, trainDevices, primaryLedger);
    rows(k).selected_model = selectedLevel;
    rows(k).training_mean_score = trainScore;
    [valScore, controlScore] = validation_score_for_level(cfg, withheld, selectedLevel, primaryLedger);
    rows(k).validation_score = valScore;
    rows(k).best_control_score = controlScore;
    rows(k).margin_vs_controls = controlScore - valScore;
    rows(k).status = pass_fail(rows(k).margin_vs_controls > 0);
    rows(k).note = "Train on two half-encapsulated devices and predict the third.";
end

row = numel(devices) + 1;
rows(row).test = "control_null_consistency";
rows(row).withheld_device = "AS001_AS003";
[selectedLevel, trainScore] = best_level_for_devices(cfg, cfg.phase5B.controlDevices(:), primaryLedger);
rows(row).selected_model = selectedLevel;
rows(row).training_mean_score = trainScore;
rows(row).validation_score = trainScore;
rows(row).best_control_score = trainScore;
rows(row).margin_vs_controls = 0;
rows(row).status = pass_fail(selectedLevel == "M0");
rows(row).note = "AS001/AS003 should prefer the local-Tc/control limit.";

heldout = struct2table(rows);
end

function [level, score] = best_level_for_devices(cfg, devices, ledger)
levels = ["M0"; "M1"; "M2"];
scores = NaN(numel(levels), 1);
for i = 1:numel(levels)
    vals = NaN(numel(devices), 1);
    for k = 1:numel(devices)
        [vals(k), ~] = validation_score_for_level(cfg, devices(k), levels(i), ledger);
    end
    scores(i) = finite_mean(vals);
end
[score, local] = min(scores);
if isfinite(score)
    level = levels(local);
else
    level = "unresolved";
end
end

function [levelScore, bestControl] = validation_score_for_level(cfg, device, level, ledger)
idx = ledger.device == device & ledger.run_status == "scored";
levelIdx = idx & model_level_mask(ledger.mechanism, level);
if any(levelIdx)
    levelScore = min(ledger.total_LevelA_score(levelIdx)) + ...
        cfg.phase5B.complexityPenaltyLambda .* complexity_for(level);
else
    levelScore = NaN;
end
controlIdx = idx & ledger.role == "required_control";
if any(controlIdx)
    bestControl = min(ledger.total_LevelA_score(controlIdx));
else
    bestControl = NaN;
end
end

function activationPlan = build_activation_plan(cfg)
rows = repmat(struct('model', "", 'formula', "", 'purpose', "", ...
    'status', ""), 2, 1);
rows(1).model = "abrupt_geometry_only_activation";
rows(1).formula = "lambda_W = lambda_B * B_d";
rows(1).purpose = "Binary half-coverage activation; AS002 tests whether this is too abrupt.";
rows(1).status = "planned_for_global_law_fit";
rows(2).model = "film_force_modulated_activation";
rows(2).formula = "lambda_W = lambda_B * B_d * (abs(F_f)/F0)^q + lambda_C * C_d";
rows(2).purpose = "Tests graded boundary threshold plus crack activation without device-specific lambdas.";
rows(2).status = "planned_for_global_law_fit";
activationPlan = struct2table(rows);
end

function gates = build_phase5B_gates(cfg, freezeManifest, secondaryManifest, secondaryLedger, evidence, heldout)
rows = repmat(empty_gate_row(), 7, 1);
row = 0;

row = row + 1;
rows(row).gate = "phase5A_frozen_before_phase5B";
rows(row).required = true;
rows(row).status = pass_fail(all(freezeManifest.exists));
rows(row).evidence = sprintf('%d/%d frozen Phase 5A artifacts found.', ...
    sum(freezeManifest.exists), height(freezeManifest));
rows(row).note = "Phase 5B consumes, but does not alter, Level A policies and ledgers.";

row = row + 1;
rows(row).gate = "available_secondary_probes_scored";
rows(row).required = true;
availableDevices = secondaryManifest.device(secondaryManifest.secondary_curve_available);
scoredDevices = unique(secondaryLedger.device(secondaryLedger.run_status == "scored"), 'stable');
rows(row).status = pass_fail(all(ismember(availableDevices, scoredDevices)));
rows(row).evidence = sprintf('%d/%d devices with available secondary probes scored.', ...
    numel(intersect(availableDevices, scoredDevices)), numel(availableDevices));
rows(row).note = "Missing secondary probes are not failures; available heldouts must score.";

row = row + 1;
rows(row).gate = "structured_regime_secondary_survival";
rows(row).required = true;
structured = cfg.phase5B.structuredRegimeDevices(:);
idx = ismember(evidence.device, structured) & evidence.secondary_probe_status ~= "not_applicable";
survive = idx & ismember(evidence.secondary_preferred_model, ["M1"; "M2"]);
if sum(idx) < 2
    rows(row).status = "incomplete";
else
    rows(row).status = pass_fail(sum(survive) >= 2);
end
rows(row).evidence = sprintf('%d/%d available structured-regime secondary probes prefer M1/M2.', ...
    sum(survive), sum(idx));
rows(row).note = "AS004-AS006 should retain connectivity support where secondary evidence exists.";

row = row + 1;
rows(row).gate = "controls_reduce_to_local_limit";
rows(row).required = true;
ctrlIdx = ismember(evidence.device, cfg.phase5B.controlDevices(:));
ctrlOk = ctrlIdx & ismember(evidence.preferred_model, ["M0"; "unresolved"]);
rows(row).status = pass_fail(sum(ctrlOk) == sum(ctrlIdx));
rows(row).evidence = sprintf('%d/%d control devices prefer M0 or unresolved.', ...
    sum(ctrlOk), sum(ctrlIdx));
rows(row).note = "AS001/AS003 are successful controls when weak-link complexity is unnecessary.";

row = row + 1;
rows(row).gate = "AS002_threshold_device_classified";
rows(row).required = true;
as002 = evidence(evidence.device == "AS002", :);
if isempty(as002)
    rows(row).status = "incomplete";
    rows(row).evidence = "AS002 evidence row missing.";
else
    ok = ismember(string(as002.preferred_model(1)), ["M0"; "M1"; "unresolved"]);
    rows(row).status = pass_fail(ok);
    rows(row).evidence = sprintf('AS002 preferred model = %s.', string(as002.preferred_model(1)));
end
rows(row).note = "AS002 is interpreted as the low-force half-coverage threshold device.";

row = row + 1;
rows(row).gate = "half_encapsulated_class_heldout";
rows(row).required = true;
halfRows = heldout.test == "within_half_encapsulated";
rows(row).status = pass_fail(sum(heldout.status(halfRows) == "pass") >= 2);
rows(row).evidence = sprintf('%d/%d half-encapsulated heldout rows pass.', ...
    sum(heldout.status(halfRows) == "pass"), sum(halfRows));
rows(row).note = "Class-aware heldout complements the stricter six-device LODO.";

row = row + 1;
rows(row).gate = "no_device_specific_weaklink_parameters";
rows(row).required = true;
rows(row).status = "pass";
rows(row).evidence = "Phase 5B reuses frozen basin rows and proposes global activation-law coefficients only.";
rows(row).note = "No independent lambda_W,d or device-specific weak-link fit is introduced.";

gates = struct2table(rows(1:row));
end

function [model, state] = solve_secondary_case(cfg, device, primaryProbe, expT, basinRow, opts, cases, state)
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
Tvec = transfer_temperature_vector(expT, cfg.phase5B.maxTemperaturePoints);
rt = solve_rt_sweep(netCase, state.spec, paramsCase, Tvec, cfg.phase5B.Iprobe_A);
model = struct();
model.T = rt.T;
model.top = rt.R4p.top_4_10;
model.bottom = rt.R4p.bottom_3_9;
end

function state = build_device_state(device, primaryProbe, seed, opts)
spec = make_device_spec(device);
spec.normalCalibrationProbe = char(primaryProbe);
modelParams = make_shared_model_params();
pdeOpts = make_v7_pde_options(spec);
netGeometry = build_hallbar_network(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, ~] = apply_pde_proxy_to_network(netGeometry, spec, modelParams, pde, pdeOpts);
baseParamsUncal = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v8_0_phase5B_secondary_validation_base');
[fullScaleTable, referenceFullNormalScale] = build_full_scale_table(netPDE, spec, baseParamsUncal, opts);
state = struct('seed', seed, 'spec', spec, 'netPDE', netPDE, ...
    'baseParamsUncal', baseParamsUncal, 'fullScaleTable', fullScaleTable, ...
    'referenceFullNormalScale', referenceFullNormalScale);
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

function pair = load_pair_curves(device)
pair = struct('available', false, 'T', [], 'top', [], 'bottom', [], ...
    'topAvailable', false, 'bottomAvailable', false, 'source', "", 'note', "");
try
    [~, expRT] = evalc('load_experimental_rt(device);');
catch ME
    pair.note = string(ME.message);
    return;
end
if ~isfield(expRT, 'pairData') || ~isfield(expRT.pairData, 'available') || ...
        ~expRT.pairData.available
    pair.note = "No explicit two-probe R(T) pairData available.";
    return;
end
pair.available = true;
pair.T = expRT.pairData.T;
pair.source = string(expRT.pairData.sourceFile);
pair.topAvailable = isfield(expRT.pairData.R, 'top_4_10');
pair.bottomAvailable = isfield(expRT.pairData.R, 'bottom_3_9');
if pair.topAvailable
    pair.top = expRT.pairData.R.top_4_10;
end
if pair.bottomAvailable
    pair.bottom = expRT.pairData.R.bottom_3_9;
end
pair.note = string_field(expRT.pairData, 'reductionNote', "explicit pairData loaded");
end

function tf = secondary_available(pair, secondaryProbe)
tf = (secondaryProbe == "top_4_10" && pair.topAvailable) || ...
    (secondaryProbe == "bottom_3_9" && pair.bottomAvailable);
end

function y = pair_curve(pair, probe)
if probe == "top_4_10"
    y = pair.top;
else
    y = pair.bottom;
end
end

function y = model_curve(model, probe)
if probe == "top_4_10"
    y = model.top;
else
    y = model.bottom;
end
end

function level = model_level_for(mechanism)
mechanism = string(mechanism);
if any(mechanism == ["geometry-only Tc"; "no weak links"; "bulk gap reference"])
    level = "M0";
elseif any(mechanism == ["contact-relaxed weak links"; "crack/tunnel-like weak links"])
    level = "M1";
elseif mechanism == "combined physical bottleneck"
    level = "M2";
else
    level = "protected_control";
end
end

function k = complexity_for(level)
switch char(string(level))
    case 'M0'
        k = 0;
    case 'M1'
        k = 1;
    case 'M2'
        k = 2;
    otherwise
        k = 0;
end
end

function mask = model_level_mask(mechanisms, targetLevel)
mechanisms = string(mechanisms);
mask = false(size(mechanisms));
for k = 1:numel(mechanisms)
    mask(k) = model_level_for(mechanisms(k)) == string(targetLevel);
end
end

function status = primary_status(device, summary)
idx = summary.device == device;
if any(idx)
    status = string(summary.status(find(idx, 1, 'first')));
else
    status = "missing";
end
end

function prior = regime_prior(device, cfg)
device = string(device);
if any(device == cfg.phase5B.controlDevices(:))
    prior = "local-Tc/control-like";
elseif any(device == cfg.phase5B.structuredRegimeDevices(:))
    prior = "connectivity-limited candidate";
else
    prior = "threshold/weak-response";
end
end

function preferred = combine_primary_secondary(row)
if row.secondary_preferred_model ~= "" && row.secondary_preferred_model ~= "not_applicable"
    if row.primary_preferred_model == row.secondary_preferred_model
        preferred = row.primary_preferred_model;
    elseif any(row.primary_preferred_model == ["M1"; "M2"]) && ...
            any(row.secondary_preferred_model == ["M1"; "M2"])
        preferred = "structured";
    else
        preferred = "unresolved";
    end
else
    preferred = row.primary_preferred_model;
end
end

function txt = conclusion_for_device(row)
device = string(row.device);
if any(row.preferred_model == ["M0"; "protected_control"]) && any(device == ["AS001"; "AS003"])
    txt = "connectivity not required by current evidence";
elseif device == "AS002"
    txt = "threshold device; use activation-law test";
elseif any(row.preferred_model == ["M1"; "M2"; "structured"])
    txt = "structured connectivity supported";
elseif row.secondary_probe_status == "not_applicable"
    txt = "primary-only classification; secondary evidence unavailable";
else
    txt = "unresolved mixed evidence";
end
end

function status = pass_fail(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function out = string_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    out = string(s.(name));
else
    out = string(defaultValue);
end
end

function row = empty_secondary_manifest_row()
row = struct();
row.device = "";
row.primary_probe = "";
row.secondary_probe = "";
row.secondary_status = "";
row.pair_source = "";
row.top_available = false;
row.bottom_available = false;
row.secondary_curve_available = false;
row.asymmetry_available = false;
row.phase5B_status = "";
row.note = "";
end

function row = empty_secondary_ledger_row()
row = struct();
row.device = "";
row.primary_probe = "";
row.secondary_probe = "";
row.mechanism = "";
row.role = "";
row.track = "";
row.model_level = "";
row.complexity_K = NaN;
row.parameter_basin_id = "";
row.calibration_mode = "";
row.alpha_gap = NaN;
row.gammaW = NaN;
row.pW = NaN;
row.seed = NaN;
row.secondary_curve_score = NaN;
row.secondary_RT_curve_score = NaN;
row.secondary_onset_score = NaN;
row.secondary_width_score = NaN;
row.secondary_lowT_score = NaN;
row.asymmetry_score = NaN;
row.asymmetry_curve_score = NaN;
row.exp_ordering = "";
row.model_ordering = "";
row.ordering_match = false;
row.exp_max_asymmetry = NaN;
row.model_max_asymmetry = NaN;
row.exp_lowT_asymmetry = NaN;
row.model_lowT_asymmetry = NaN;
row.exp_integrated_asymmetry = NaN;
row.model_integrated_asymmetry = NaN;
row.secondary_total_score = NaN;
row.penalized_secondary_score = NaN;
row.best_secondary_control_score = NaN;
row.secondary_margin_vs_controls = NaN;
row.secondary_beats_controls = false;
row.run_status = "";
row.note = "";
end

function row = empty_evidence_row()
row = struct();
row.device = "";
row.regime_prior = "";
row.primary_status = "";
row.primary_preferred_model = "";
row.primary_penalized_score = NaN;
row.secondary_probe_status = "";
row.secondary_preferred_model = "";
row.secondary_penalized_score = NaN;
row.secondary_best_mechanism = "";
row.asymmetry_ordering_exp = "";
row.asymmetry_ordering_model = "";
row.asymmetry_ordering_match = false;
row.secondary_margin_vs_controls = NaN;
row.preferred_model = "";
row.evidence_conclusion = "";
end

function row = empty_heldout_row()
row = struct();
row.test = "";
row.withheld_device = "";
row.selected_model = "";
row.training_mean_score = NaN;
row.validation_score = NaN;
row.best_control_score = NaN;
row.margin_vs_controls = NaN;
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
