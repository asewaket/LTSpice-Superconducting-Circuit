function out = run_phase5B2_full_series_activation_consolidation(cfg)
%RUN_PHASE5B2_FULL_SERIES_ACTIVATION_CONSOLIDATION One-law consolidation.
%
% Phase 5B.2 fits one full-series activation coefficient set for
% AS002/AS004/AS006. It preserves the strict 5B.1 heldout result and uses
% this phase only for final interpretability and joint-model comparison.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

baselineArchive = build_baseline_archive(cfg);
ledger = read_table(cfg.phase5A.frozenTransferLedgerFile);
heldout5B1 = read_optional_table(cfg.phase5B1.heldoutFile);
preservation5B1 = read_optional_table(cfg.phase5B1.secondaryPreservationFile);
deviceInputs = build_device_inputs(cfg);

require_vars(ledger, ["device"; "mechanism"; "role"; "model_level"; ...
    "caseName"; "gammaW"; "pW"; "alpha_gap"; "seed"; ...
    "total_LevelA_score"; "run_status"; "RT_curve_score"; ...
    "onset_score"; "width_score"; "lowT_score"], ...
    cfg.phase5A.frozenTransferLedgerFile);

fitLedger = build_full_series_fit_ledger(cfg, ledger, deviceInputs);
bestBinary = first_row(fitLedger, fitLedger.activation_law == "binary_geometry_activation");
bestForce = first_row(fitLedger, fitLedger.activation_law == "film_force_modulated_activation");
devicePredictions = build_device_predictions(cfg, ledger, deviceInputs, ...
    bestBinary, bestForce);
jointComparison = build_joint_comparison(cfg, ledger, bestBinary, bestForce);
as004Profile = build_as004_profile(cfg, ledger, bestForce);
[uncertaintyBySeed, uncertaintySummary] = build_uncertainty(cfg, ledger, ...
    deviceInputs);
gates = build_gates(cfg, baselineArchive, jointComparison, heldout5B1, ...
    preservation5B1);

writetable(baselineArchive, cfg.phase5B2.baselineArchiveFile);
writetable(fitLedger, cfg.phase5B2.fullSeriesFitLedgerFile);
writetable(devicePredictions, cfg.phase5B2.devicePredictionFile);
writetable(jointComparison, cfg.phase5B2.jointComparisonFile);
writetable(as004Profile, cfg.phase5B2.as004ProfileFile);
writetable(uncertaintyBySeed, cfg.phase5B2.uncertaintyFile);
writetable(uncertaintySummary, cfg.phase5B2.uncertaintySummaryFile);
writetable(gates, cfg.phase5B2.gateResultFile);

try
    h = v800.plot_phase5B2_full_series_summary(cfg, devicePredictions, ...
        jointComparison, as004Profile, uncertaintySummary, gates);
catch ME
    warning('v8:phase5B2PlotFailed', ...
        'Phase 5B.2 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.baselineArchive = baselineArchive;
out.fitLedger = fitLedger;
out.devicePredictions = devicePredictions;
out.jointComparison = jointComparison;
out.as004Profile = as004Profile;
out.uncertaintyBySeed = uncertaintyBySeed;
out.uncertaintySummary = uncertaintySummary;
out.gates = gates;
out.figure = h;
out.paths = struct();
out.paths.baselineArchive = cfg.phase5B2.baselineArchiveFile;
out.paths.fitLedger = cfg.phase5B2.fullSeriesFitLedgerFile;
out.paths.devicePredictions = cfg.phase5B2.devicePredictionFile;
out.paths.jointComparison = cfg.phase5B2.jointComparisonFile;
out.paths.as004Profile = cfg.phase5B2.as004ProfileFile;
out.paths.uncertaintyBySeed = cfg.phase5B2.uncertaintyFile;
out.paths.uncertaintySummary = cfg.phase5B2.uncertaintySummaryFile;
out.paths.gates = cfg.phase5B2.gateResultFile;
out.paths.figurePng = [cfg.phase5B2.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5B2.figureBaseFile '.pdf'];
end

function archive = build_baseline_archive(cfg)
files = [
    artifact("phase5B1_baseline_archive", cfg.phase5B1.baselineArchiveFile)
    artifact("phase5B1_device_activation_inputs", cfg.phase5B1.deviceActivationFile)
    artifact("phase5B1_fit_ledger", cfg.phase5B1.fitLedgerFile)
    artifact("phase5B1_strict_heldout", cfg.phase5B1.heldoutFile)
    artifact("phase5B1_secondary_preservation", cfg.phase5B1.secondaryPreservationFile)
    artifact("phase5B1_gates", cfg.phase5B1.gateResultFile)
    artifact("phase5A_primary_ledger", cfg.phase5A.frozenTransferLedgerFile)
    ];
rows = repmat(struct('artifact', "", 'path', "", 'exists', false, ...
    'bytes', NaN, 'modified_datenum', NaN, 'commit_sha', "", ...
    'freeze_policy', ""), numel(files), 1);
commitSha = v800.git_commit_sha(cfg.repoRoot);
for k = 1:numel(files)
    info = dir(files(k).path);
    rows(k).artifact = files(k).name;
    rows(k).path = files(k).path;
    rows(k).exists = ~isempty(info);
    if ~isempty(info)
        rows(k).bytes = info.bytes;
        rows(k).modified_datenum = info.datenum;
    end
    rows(k).commit_sha = string(commitSha);
    rows(k).freeze_policy = "Phase 5B.2 preserves strict 5B.1 heldout evidence.";
end
archive = struct2table(rows);
end

function a = artifact(name, pathValue)
a = struct('name', string(name), 'path', string(pathValue));
end

function inputs = build_device_inputs(cfg)
forceTable = cfg.phase5B1.halfEncapsulatedForce_N_per_m;
devices = cfg.phase5B.halfEncapsulatedDevices(:);
rows = repmat(struct('device', "", 'film_force_N_per_m', NaN, ...
    'abs_force_over_F0', NaN), numel(devices), 1);
for k = 1:numel(devices)
    idx = forceTable.device == devices(k);
    rows(k).device = devices(k);
    rows(k).film_force_N_per_m = forceTable.film_force_N_per_m(find(idx, 1, 'first'));
    rows(k).abs_force_over_F0 = abs(rows(k).film_force_N_per_m) ./ ...
        cfg.phase5B1.F0_N_per_m;
end
inputs = struct2table(rows);
end

function fitLedger = build_full_series_fit_ledger(cfg, ledger, deviceInputs)
basis = candidate_basis_rows(ledger);
families = ["binary_geometry_activation", ...
    "film_force_modulated_activation"];
maxRows = height(basis) .* numel(cfg.phase5B2.lambdaBGrid) .* ...
    (1 + numel(cfg.phase5B2.qGrid));
rows = repmat(empty_fit_row(), max(1, maxRows), 1);
row = 0;
for iFamily = 1:numel(families)
    family = families(iFamily);
    paramGrid = param_grid(cfg, family);
    for iBasis = 1:height(basis)
        for iParam = 1:height(paramGrid)
            row = row + 1;
            rows(row) = empty_fit_row();
            rows(row).activation_law = family;
            rows(row).mechanism = string(basis.mechanism(iBasis));
            rows(row).model_level = string(basis.model_level(iBasis));
            rows(row).case_family = string(basis.case_family(iBasis));
            rows(row).basis_caseName = string(basis.caseName(iBasis));
            rows(row).basis_gammaW = basis.gammaW(iBasis);
            rows(row).basis_pW = basis.pW(iBasis);
            rows(row).basis_alpha_gap = basis.alpha_gap(iBasis);
            rows(row).seed = basis.seed(iBasis);
            rows(row).lambda_B = paramGrid.lambda_B(iParam);
            rows(row).q = paramGrid.q(iParam);
            [scoreMean, lambdas, deviceScores] = score_devices(cfg, ledger, ...
                deviceInputs, rows(row));
            rows(row).mean_raw_score = scoreMean;
            rows(row).joint_penalized_score = scoreMean + ...
                cfg.phase5B.complexityPenaltyLambda .* ...
                complexity_for(rows(row).model_level) + q_penalty(cfg, family);
            rows(row).lambdaW_AS002 = lambdas(1);
            rows(row).lambdaW_AS004 = lambdas(2);
            rows(row).lambdaW_AS006 = lambdas(3);
            rows(row).score_AS002 = deviceScores(1);
            rows(row).score_AS004 = deviceScores(2);
            rows(row).score_AS006 = deviceScores(3);
            rows(row).policy = "one full-series coefficient set; no crack term; no per-device lambda";
        end
    end
end
fitLedger = struct2table(rows(1:row));
fitLedger = sortrows(fitLedger, {'joint_penalized_score','activation_law','mechanism'});
end

function [scoreMean, lambdas, scores] = score_devices(cfg, ledger, deviceInputs, fitRow)
devices = cfg.phase5B.halfEncapsulatedDevices(:);
lambdas = NaN(numel(devices), 1);
scores = NaN(numel(devices), 1);
for k = 1:numel(devices)
    lambdas(k) = lambda_for_device(cfg, deviceInputs, devices(k), fitRow);
    scores(k) = interpolated_score(cfg, ledger, devices(k), fitRow, lambdas(k));
end
scoreMean = finite_mean(scores);
end

function lambdaW = lambda_for_device(cfg, deviceInputs, device, fitRow)
idx = deviceInputs.device == string(device);
if ~any(idx)
    lambdaW = NaN;
    return;
end
forceFactor = deviceInputs.abs_force_over_F0(find(idx, 1, 'first'));
switch string(fitRow.activation_law)
    case "binary_geometry_activation"
        lambdaW = fitRow.lambda_B;
    case "film_force_modulated_activation"
        lambdaW = fitRow.lambda_B .* forceFactor .^ fitRow.q;
    otherwise
        lambdaW = NaN;
end
lambdaW = max(cfg.phase5B1.lambdaLowerBound, ...
    min(cfg.phase5B1.lambdaMax, lambdaW));
end

function score = interpolated_score(cfg, ledger, device, fitRow, lambdaW)
localScore = local_m0_score(ledger, device);
weakScore = solved_weak_score(ledger, device, fitRow);
lambdaSolved = max(0, min(cfg.phase5B1.lambdaMax, 1 - fitRow.basis_gammaW));
if ~isfinite(localScore) || ~isfinite(weakScore) || ...
        ~isfinite(lambdaSolved) || lambdaSolved <= 0
    score = NaN;
    return;
end
frac = max(0, min(1, lambdaW ./ lambdaSolved));
score = localScore + frac .* (weakScore - localScore);
end

function preds = build_device_predictions(cfg, ledger, deviceInputs, bestBinary, bestForce)
devices = cfg.phase5B.halfEncapsulatedDevices(:);
rows = repmat(struct('device', "", 'film_force_N_per_m', NaN, ...
    'binary_lambda_W', NaN, 'force_lambda_W', NaN, ...
    'binary_score', NaN, 'force_score', NaN, 'best_M0_score', NaN, ...
    'best_uniform_score', NaN, 'best_shuffled_score', NaN, ...
    'best_central_lane_score', NaN, 'best_protected_score', NaN, ...
    'force_margin_vs_protected', NaN, 'onset_score_at_force', NaN, ...
    'width_score_at_force', NaN, 'lowT_score_at_force', NaN, ...
    'diagnostic_note', ""), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    didx = deviceInputs.device == device;
    rows(k).film_force_N_per_m = deviceInputs.film_force_N_per_m(find(didx, 1, 'first'));
    rows(k).binary_lambda_W = lambda_for_device(cfg, deviceInputs, device, bestBinary);
    rows(k).force_lambda_W = lambda_for_device(cfg, deviceInputs, device, bestForce);
    rows(k).binary_score = interpolated_score(cfg, ledger, device, bestBinary, ...
        rows(k).binary_lambda_W);
    rows(k).force_score = interpolated_score(cfg, ledger, device, bestForce, ...
        rows(k).force_lambda_W);
    rows(k).best_M0_score = local_m0_score(ledger, device);
    rows(k).best_uniform_score = mechanism_best_score(ledger, device, "uniform weak links");
    rows(k).best_shuffled_score = mechanism_best_score(ledger, device, "shuffled weak links");
    rows(k).best_central_lane_score = mechanism_best_score(ledger, device, "central-lane / 1D-like");
    rows(k).best_protected_score = min([rows(k).best_M0_score, ...
        rows(k).best_uniform_score, rows(k).best_shuffled_score, ...
        rows(k).best_central_lane_score], [], 'omitnan');
    rows(k).force_margin_vs_protected = rows(k).best_protected_score - rows(k).force_score;
    comp = interpolated_components(cfg, ledger, device, bestForce, rows(k).force_lambda_W);
    rows(k).onset_score_at_force = comp.onset_score;
    rows(k).width_score_at_force = comp.width_score;
    rows(k).lowT_score_at_force = comp.lowT_score;
    rows(k).diagnostic_note = note_for_device(device, rows(k).force_margin_vs_protected);
end
preds = struct2table(rows);
end

function joint = build_joint_comparison(cfg, ledger, bestBinary, bestForce)
models = ["local Tc / M0"; "binary activation"; ...
    "force-modulated activation"; "uniform weak links"; ...
    "shuffled weak links"; "central-lane / 1D-like"];
rows = repmat(struct('model', "", 'joint_raw_score', NaN, ...
    'complexity_K', NaN, 'extra_penalty', NaN, ...
    'joint_penalized_score', NaN, 'status_note', ""), numel(models), 1);
for k = 1:numel(models)
    rows(k).model = models(k);
    switch models(k)
        case "local Tc / M0"
            scores = device_scores_for_mechanism(ledger, cfg.phase5B.halfEncapsulatedDevices, "M0");
            rows(k).complexity_K = 0;
            rows(k).extra_penalty = 0;
        case "binary activation"
            scores = [bestBinary.score_AS002; bestBinary.score_AS004; bestBinary.score_AS006];
            rows(k).complexity_K = complexity_for(bestBinary.model_level);
            rows(k).extra_penalty = 0;
        case "force-modulated activation"
            scores = [bestForce.score_AS002; bestForce.score_AS004; bestForce.score_AS006];
            rows(k).complexity_K = complexity_for(bestForce.model_level);
            rows(k).extra_penalty = q_penalty(cfg, "film_force_modulated_activation");
        case "uniform weak links"
            scores = device_scores_for_mechanism(ledger, cfg.phase5B.halfEncapsulatedDevices, "uniform weak links");
            rows(k).complexity_K = 0;
            rows(k).extra_penalty = 0;
        case "shuffled weak links"
            scores = device_scores_for_mechanism(ledger, cfg.phase5B.halfEncapsulatedDevices, "shuffled weak links");
            rows(k).complexity_K = 0;
            rows(k).extra_penalty = 0;
        otherwise
            scores = device_scores_for_mechanism(ledger, cfg.phase5B.halfEncapsulatedDevices, "central-lane / 1D-like");
            rows(k).complexity_K = 0;
            rows(k).extra_penalty = 0;
    end
    rows(k).joint_raw_score = finite_mean(scores);
    rows(k).joint_penalized_score = rows(k).joint_raw_score + ...
        cfg.phase5B.complexityPenaltyLambda .* rows(k).complexity_K + ...
        rows(k).extra_penalty;
    rows(k).status_note = "lower joint score is better";
end
joint = struct2table(rows);
joint = sortrows(joint, 'joint_penalized_score');
end

function profile = build_as004_profile(cfg, ledger, bestForce)
lambdaVals = cfg.phase5B2.lambdaProfileGrid(:);
rows = repmat(struct('device', "AS004", 'lambda_W', NaN, ...
    'score', NaN, 'RT_curve_score', NaN, 'onset_score', NaN, ...
    'width_score', NaN, 'lowT_score', NaN, 'note', ""), ...
    numel(lambdaVals), 1);
for k = 1:numel(lambdaVals)
    rows(k).lambda_W = lambdaVals(k);
    rows(k).score = interpolated_score(cfg, ledger, "AS004", bestForce, lambdaVals(k));
    comp = interpolated_components(cfg, ledger, "AS004", bestForce, lambdaVals(k));
    rows(k).RT_curve_score = comp.RT_curve_score;
    rows(k).onset_score = comp.onset_score;
    rows(k).width_score = comp.width_score;
    rows(k).lowT_score = comp.lowT_score;
    rows(k).note = "AS004 profile diagnoses whether intermediate-force response prefers zero, weak, or strong activation.";
end
profile = struct2table(rows);
end

function [bySeed, summary] = build_uncertainty(cfg, ledger, deviceInputs)
seeds = sort(unique(ledger.seed(isfinite(ledger.seed))));
rows = repmat(empty_uncertainty_row(), max(1, numel(seeds)), 1);
row = 0;
for k = 1:numel(seeds)
    seedLedger = ledger(ledger.seed == seeds(k), :);
    if isempty(seedLedger)
        continue;
    end
    fitLedger = build_full_series_fit_ledger(cfg, seedLedger, deviceInputs);
    bestForce = first_row(fitLedger, ...
        fitLedger.activation_law == "film_force_modulated_activation");
    row = row + 1;
    rows(row).seed = seeds(k);
    rows(row).lambda_B = bestForce.lambda_B;
    rows(row).q = bestForce.q;
    rows(row).lambdaW_AS002 = bestForce.lambdaW_AS002;
    rows(row).lambdaW_AS004 = bestForce.lambdaW_AS004;
    rows(row).lambdaW_AS006 = bestForce.lambdaW_AS006;
    rows(row).joint_penalized_score = bestForce.joint_penalized_score;
    rows(row).mechanism = string(bestForce.mechanism);
    rows(row).case_family = string(bestForce.case_family);
end
bySeed = struct2table(rows(1:row));

params = ["lambda_B"; "q"; "lambdaW_AS002"; "lambdaW_AS004"; "lambdaW_AS006"];
srows = repmat(struct('parameter', "", 'mean', NaN, 'median', NaN, ...
    'p16', NaN, 'p84', NaN, 'n', 0), numel(params), 1);
for k = 1:numel(params)
    vals = bySeed.(char(params(k)));
    vals = vals(isfinite(vals));
    srows(k).parameter = params(k);
    srows(k).n = numel(vals);
    if ~isempty(vals)
        srows(k).mean = mean(vals);
        srows(k).median = median(vals);
        srows(k).p16 = percentile(vals, 16);
        srows(k).p84 = percentile(vals, 84);
    end
end
summary = struct2table(srows);
end

function comp = interpolated_components(cfg, ledger, device, fitRow, lambdaW)
fields = ["RT_curve_score"; "onset_score"; "width_score"; "lowT_score"];
comp = struct('RT_curve_score', NaN, 'onset_score', NaN, ...
    'width_score', NaN, 'lowT_score', NaN);
for k = 1:numel(fields)
    localVal = local_component_score(ledger, device, fields(k));
    weakVal = weak_component_score(ledger, device, fitRow, fields(k));
    lambdaSolved = max(0, min(cfg.phase5B1.lambdaMax, 1 - fitRow.basis_gammaW));
    if isfinite(localVal) && isfinite(weakVal) && lambdaSolved > 0
        frac = max(0, min(1, lambdaW ./ lambdaSolved));
        comp.(char(fields(k))) = localVal + frac .* (weakVal - localVal);
    end
end
end

function basis = candidate_basis_rows(ledger)
idx = ledger.run_status == "scored" & ismember(ledger.model_level, ["M1"; "M2"]) & ...
    isfinite(ledger.gammaW) & ledger.gammaW < 1;
S = ledger(idx, :);
[~, keep] = unique(strcat(S.mechanism, "|", case_family(S.caseName), "|", ...
    string(S.seed)), 'stable');
basis = S(keep, :);
basis.case_family = case_family(basis.caseName);
end

function family = case_family(caseName)
family = regexprep(string(caseName), '_g[0-9_]+_p', '_p');
end

function grid = param_grid(cfg, family)
lambdaB = cfg.phase5B2.lambdaBGrid(:);
if string(family) == "binary_geometry_activation"
    rows = repmat(struct('lambda_B', NaN, 'q', NaN), numel(lambdaB), 1);
    for k = 1:numel(lambdaB)
        rows(k).lambda_B = lambdaB(k);
    end
else
    qVals = cfg.phase5B2.qGrid(:);
    rows = repmat(struct('lambda_B', NaN, 'q', NaN), ...
        numel(lambdaB) * numel(qVals), 1);
    row = 0;
    for i = 1:numel(lambdaB)
        for q = 1:numel(qVals)
            row = row + 1;
            rows(row).lambda_B = lambdaB(i);
            rows(row).q = qVals(q);
        end
    end
end
grid = struct2table(rows);
end

function scores = device_scores_for_mechanism(ledger, devices, mechanism)
scores = NaN(numel(devices), 1);
for k = 1:numel(devices)
    if string(mechanism) == "M0"
        scores(k) = local_m0_score(ledger, devices(k));
    else
        scores(k) = mechanism_best_score(ledger, devices(k), mechanism);
    end
end
end

function score = local_m0_score(ledger, device)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.model_level == "M0";
if any(idx)
    score = min(ledger.total_LevelA_score(idx));
else
    score = NaN;
end
end

function score = solved_weak_score(ledger, device, fitRow)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.mechanism == string(fitRow.mechanism) & ...
    ledger.caseName == string(fitRow.basis_caseName) & ...
    ledger.seed == fitRow.seed;
if any(idx)
    score = finite_mean(ledger.total_LevelA_score(idx));
else
    score = NaN;
end
end

function score = mechanism_best_score(ledger, device, mechanism)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.mechanism == string(mechanism);
if any(idx)
    score = min(ledger.total_LevelA_score(idx));
else
    score = NaN;
end
end

function score = local_component_score(ledger, device, fieldName)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.model_level == "M0";
score = best_component(ledger, idx, fieldName);
end

function score = weak_component_score(ledger, device, fitRow, fieldName)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.mechanism == string(fitRow.mechanism) & ...
    ledger.caseName == string(fitRow.basis_caseName) & ...
    ledger.seed == fitRow.seed;
score = best_component(ledger, idx, fieldName);
end

function val = best_component(ledger, idx, fieldName)
if ~any(idx)
    val = NaN;
    return;
end
rows = find(idx);
[~, local] = min(ledger.total_LevelA_score(idx));
val = ledger.(char(fieldName))(rows(local));
end

function gates = build_gates(cfg, archive, joint, heldout5B1, preservation5B1)
rows = repmat(empty_gate_row(), 7, 1);
row = 0;

row = row + 1;
rows(row).gate = "phase5B1_baseline_frozen";
rows(row).required = true;
rows(row).status = pass_fail(all(archive.exists));
rows(row).evidence = sprintf('%d/%d Phase 5B.1 baseline files found.', ...
    sum(archive.exists), height(archive));
rows(row).note = "5B.2 is interpretive consolidation and does not replace strict heldout.";

forceScore = model_score(joint, "force-modulated activation");
binaryScore = model_score(joint, "binary activation");
protectedScore = min(joint.joint_penalized_score(ismember(joint.model, ...
    ["local Tc / M0"; "uniform weak links"; "shuffled weak links"; ...
    "central-lane / 1D-like"])), [], 'omitnan');

row = row + 1;
rows(row).gate = "joint_force_beats_binary";
rows(row).required = true;
rows(row).status = pass_fail(forceScore < binaryScore);
rows(row).evidence = sprintf('force %.4g vs binary %.4g.', forceScore, binaryScore);
rows(row).note = "Full-series law must improve on binary activation after penalties.";

row = row + 1;
rows(row).gate = "joint_force_beats_protected_alternatives";
rows(row).required = true;
rows(row).status = pass_fail(forceScore < protectedScore);
rows(row).evidence = sprintf('force %.4g vs best protected %.4g.', ...
    forceScore, protectedScore);
rows(row).note = "Protected alternatives include M0, uniform, shuffled, and central lane.";

row = row + 1;
rows(row).gate = "strict_heldout_protected_survival";
rows(row).required = true;
if isempty(heldout5B1) || ~ismember('force_margin_vs_best_protected', heldout5B1.Properties.VariableNames)
    rows(row).status = "incomplete";
    rows(row).evidence = "Phase 5B.1 heldout table unavailable.";
else
    passCount = sum(heldout5B1.force_margin_vs_best_protected > 0);
    rows(row).status = pass_fail(passCount >= cfg.phase5B2.requireStrictHeldoutProtectedPasses);
    rows(row).evidence = sprintf('%d/3 strict heldout folds beat protected controls.', passCount);
end
rows(row).note = "This is the predeclared stopping rule inherited from 5B.1.";

row = row + 1;
rows(row).gate = "secondary_preservation_remains_intact";
rows(row).required = true;
if isempty(preservation5B1) || ~ismember('preservation_status', preservation5B1.Properties.VariableNames)
    rows(row).status = "incomplete";
    rows(row).evidence = "Phase 5B.1 secondary preservation table unavailable.";
else
    passCount = sum(preservation5B1.preservation_status == "pass");
    rows(row).status = pass_fail(passCount == height(preservation5B1));
    rows(row).evidence = sprintf('%d/%d secondary preservation rows pass.', ...
        passCount, height(preservation5B1));
end
rows(row).note = "Secondary probes remain independent heldout evidence.";

row = row + 1;
rows(row).gate = "no_AS004_specific_coefficient";
rows(row).required = true;
rows(row).status = "pass";
rows(row).evidence = "AS004 is diagnosed by S(lambda_W), not tuned independently.";
rows(row).note = "No AS004-specific activation parameter is introduced.";

row = row + 1;
rows(row).gate = "phase5B2_final_shared_force_law_attempt";
rows(row).required = false;
rows(row).status = "pass";
rows(row).evidence = "5B.2 predeclares this as the final shared film-force law consolidation.";
rows(row).note = "If gates fail, the conclusion is mixed/limited transfer, not another retuning round.";

gates = struct2table(rows(1:row));
end

function score = model_score(joint, modelName)
idx = joint.model == string(modelName);
if any(idx)
    score = joint.joint_penalized_score(find(idx, 1, 'first'));
else
    score = NaN;
end
end

function penalty = q_penalty(cfg, family)
if string(family) == "film_force_modulated_activation"
    penalty = cfg.phase5B1.qComplexityPenalty;
else
    penalty = 0;
end
end

function k = complexity_for(level)
switch string(level)
    case "M0"
        k = 0;
    case "M1"
        k = 1;
    case "M2"
        k = 2;
    otherwise
        k = 1;
end
end

function note = note_for_device(device, margin)
if string(device) == "AS004"
    note = "critical intermediate-force device; inspect lambda profile and score components";
elseif margin > 0
    note = "full-series force law beats protected alternatives";
else
    note = "protected alternatives remain sufficient";
end
end

function T = read_table(filePath)
if exist(filePath, 'file') ~= 2
    error('v8:phase5B2MissingFile', 'Required file not found: %s', char(filePath));
end
try
    T = readtable(filePath, 'TextType', 'string', 'VariableNamingRule', 'preserve');
catch
    T = readtable(filePath, 'TextType', 'string');
end
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
T = coerce_numeric_strings(T);
end

function T = read_optional_table(filePath)
if exist(filePath, 'file') ~= 2
    T = table();
else
    T = read_table(filePath);
end
end

function T = coerce_numeric_strings(T)
for k = 1:width(T)
    name = T.Properties.VariableNames{k};
    col = T.(name);
    if iscell(col)
        col = string(col);
    end
    if isstring(col)
        vals = str2double(col);
        nonempty = strlength(strtrim(col)) > 0 & ~ismissing(col);
        if any(nonempty) && all(isfinite(vals(nonempty)) | strcmpi(col(nonempty), "NaN"))
            T.(name) = vals;
        end
    end
end
end

function require_vars(T, requiredVars, filePath)
present = string(T.Properties.VariableNames);
missing = requiredVars(~ismember(requiredVars, present));
if ~isempty(missing)
    error('v8:phase5B2MissingColumns', ...
        'File %s is missing required columns: %s. Present columns: %s', ...
        char(filePath), strjoin(cellstr(missing), ', '), ...
        strjoin(cellstr(present), ', '));
end
end

function row = first_row(T, idx)
rows = find(idx);
if isempty(rows)
    error('v8:phase5B2MissingFit', 'No fit row matched the requested mask.');
end
row = table2struct(T(rows(1), :));
end

function row = empty_fit_row()
row = struct();
row.activation_law = "";
row.mechanism = "";
row.model_level = "";
row.case_family = "";
row.basis_caseName = "";
row.basis_gammaW = NaN;
row.basis_pW = NaN;
row.basis_alpha_gap = NaN;
row.seed = NaN;
row.lambda_B = NaN;
row.q = NaN;
row.mean_raw_score = NaN;
row.joint_penalized_score = NaN;
row.lambdaW_AS002 = NaN;
row.lambdaW_AS004 = NaN;
row.lambdaW_AS006 = NaN;
row.score_AS002 = NaN;
row.score_AS004 = NaN;
row.score_AS006 = NaN;
row.policy = "";
end

function row = empty_uncertainty_row()
row = struct();
row.seed = NaN;
row.lambda_B = NaN;
row.q = NaN;
row.lambdaW_AS002 = NaN;
row.lambdaW_AS004 = NaN;
row.lambdaW_AS006 = NaN;
row.joint_penalized_score = NaN;
row.mechanism = "";
row.case_family = "";
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

function p = percentile(x, pct)
x = sort(x(isfinite(x)));
if isempty(x)
    p = NaN;
    return;
end
if numel(x) == 1
    p = x(1);
    return;
end
q = 1 + (numel(x) - 1) .* pct ./ 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (x(hi) - x(lo)) .* (q - lo);
end
end

function status = pass_fail(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end
