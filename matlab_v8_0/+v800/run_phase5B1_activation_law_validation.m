function out = run_phase5B1_activation_law_validation(cfg)
%RUN_PHASE5B1_ACTIVATION_LAW_VALIDATION Fit global weak-link activation laws.
%
% Phase 5B.1 consumes the frozen Phase 5A/5B ledgers. It does not rewrite
% those baseline results; it asks whether a compact global activation rule
% can explain the half-encapsulated AS002/AS004/AS006 series.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

baselineArchive = build_baseline_archive(cfg);
deviceInputs = build_device_activation_inputs(cfg);
primaryLedger = read_table(cfg.phase5A.frozenTransferLedgerFile);
secondaryEvidence = read_optional_table(cfg.phase5B.deviceEvidenceFile);
phase5BGates = read_optional_table(cfg.phase5B.gateResultFile);

require_vars(primaryLedger, ["device"; "mechanism"; "role"; "model_level"; ...
    "caseName"; "gammaW"; "pW"; "alpha_gap"; "seed"; ...
    "total_LevelA_score"; "run_status"], cfg.phase5A.frozenTransferLedgerFile);

fitLedger = build_activation_fit_ledger(cfg, primaryLedger, deviceInputs);
heldout = build_activation_heldout(cfg, primaryLedger, deviceInputs, fitLedger);
secondaryPreservation = build_secondary_preservation(cfg, secondaryEvidence);
gates = build_activation_gates(cfg, baselineArchive, heldout, ...
    secondaryPreservation, phase5BGates);

writetable(baselineArchive, cfg.phase5B1.baselineArchiveFile);
writetable(deviceInputs, cfg.phase5B1.deviceActivationFile);
writetable(fitLedger, cfg.phase5B1.fitLedgerFile);
writetable(heldout, cfg.phase5B1.heldoutFile);
writetable(secondaryPreservation, cfg.phase5B1.secondaryPreservationFile);
writetable(gates, cfg.phase5B1.gateResultFile);

try
    h = v800.plot_phase5B1_activation_summary(cfg, heldout, ...
        secondaryPreservation, gates);
catch ME
    warning('v8:phase5B1PlotFailed', ...
        'Phase 5B.1 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.baselineArchive = baselineArchive;
out.deviceInputs = deviceInputs;
out.fitLedger = fitLedger;
out.heldout = heldout;
out.secondaryPreservation = secondaryPreservation;
out.gates = gates;
out.figure = h;
out.paths = struct();
out.paths.baselineArchive = cfg.phase5B1.baselineArchiveFile;
out.paths.deviceInputs = cfg.phase5B1.deviceActivationFile;
out.paths.fitLedger = cfg.phase5B1.fitLedgerFile;
out.paths.heldout = cfg.phase5B1.heldoutFile;
out.paths.secondaryPreservation = cfg.phase5B1.secondaryPreservationFile;
out.paths.gates = cfg.phase5B1.gateResultFile;
out.paths.figurePng = [cfg.phase5B1.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5B1.figureBaseFile '.pdf'];
end

function archive = build_baseline_archive(cfg)
files = [
    artifact("phase5A_rt_manifest", cfg.phase5A.rtManifestFile)
    artifact("phase5A_frozen_basin", cfg.phase5A.frozenBasinFile)
    artifact("phase5A_primary_ledger", cfg.phase5A.frozenTransferLedgerFile)
    artifact("phase5A_device_summary", cfg.phase5A.summaryFile)
    artifact("phase5A_strict_lodo", cfg.phase5A.leaveOneOutFile)
    artifact("phase5A_gates", cfg.phase5A.gateResultFile)
    artifact("phase5B_freeze_manifest", cfg.phase5B.freezeManifestFile)
    artifact("phase5B_secondary_manifest", cfg.phase5B.secondaryManifestFile)
    artifact("phase5B_secondary_ledger", cfg.phase5B.secondaryLedgerFile)
    artifact("phase5B_device_evidence", cfg.phase5B.deviceEvidenceFile)
    artifact("phase5B_strict_class_heldout", cfg.phase5B.classHeldoutFile)
    artifact("phase5B_activation_plan", cfg.phase5B.activationPlanFile)
    artifact("phase5B_six_pass_one_fail_gates", cfg.phase5B.gateResultFile)
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
    rows(k).freeze_policy = "Phase 5B.1 consumes this file as immutable baseline evidence.";
end
archive = struct2table(rows);
end

function a = artifact(name, pathValue)
a = struct('name', string(name), 'path', string(pathValue));
end

function inputs = build_device_activation_inputs(cfg)
devices = cfg.devices(:);
rows = repmat(struct('device', "", 'B_half_encapsulated', false, ...
    'C_crack', false, 'film_force_N_per_m', NaN, ...
    'force_source', "", 'activation_role', ""), numel(devices), 1);
forceTable = cfg.phase5B1.halfEncapsulatedForce_N_per_m;
for k = 1:numel(devices)
    device = string(devices(k));
    rows(k).device = device;
    rows(k).B_half_encapsulated = any(cfg.phase5B.halfEncapsulatedDevices == device);
    rows(k).C_crack = device == string(cfg.phase5B1.crackDevice);
    fidx = forceTable.device == device;
    if any(fidx)
        rows(k).film_force_N_per_m = forceTable.film_force_N_per_m(find(fidx, 1, 'first'));
        rows(k).force_source = "frozen Phase 5B.1 plan value";
    else
        rows(k).film_force_N_per_m = 0;
        rows(k).force_source = "control or crack-only device; force not used";
    end
    if rows(k).B_half_encapsulated
        rows(k).activation_role = "half_encapsulated_validation";
    elseif rows(k).C_crack
        rows(k).activation_role = "crack_activation_auxiliary";
    else
        rows(k).activation_role = "local_Tc_control";
    end
end
inputs = struct2table(rows);
end

function fitLedger = build_activation_fit_ledger(cfg, ledger, deviceInputs)
devices = cfg.phase5B.halfEncapsulatedDevices(:);
rows = repmat(empty_fit_row(), 0, 1);
for k = 1:numel(devices)
    withheld = devices(k);
    trainDevices = devices(devices ~= withheld);
    families = ["binary_geometry_activation", ...
        "film_force_modulated_activation"];
    for iFamily = 1:numel(families)
        family = families(iFamily);
        [fitRow, ~] = fit_one_family(cfg, ledger, deviceInputs, ...
            trainDevices, family);
        fitRow.withheld_device = withheld;
        fitRow.training_devices = string(strjoin(cellstr(trainDevices), "|"));
        rows(end+1, 1) = fitRow; %#ok<AGROW>
    end
end
fitLedger = struct2table(rows);
end

function heldout = build_activation_heldout(cfg, ledger, deviceInputs, fitLedger)
devices = cfg.phase5B.halfEncapsulatedDevices(:);
rows = repmat(empty_heldout_row(), numel(devices), 1);
for k = 1:numel(devices)
    withheld = devices(k);
    binaryFit = fitLedger(fitLedger.withheld_device == withheld & ...
        fitLedger.activation_law == "binary_geometry_activation", :);
    forceFit = fitLedger(fitLedger.withheld_device == withheld & ...
        fitLedger.activation_law == "film_force_modulated_activation", :);
    rows(k).test = "half_encapsulated_activation_heldout";
    rows(k).withheld_device = withheld;
    rows(k).training_devices = string(forceFit.training_devices(1));

    [binaryScore, binaryLambda] = predict_score_from_fit(cfg, ledger, ...
        deviceInputs, withheld, binaryFit);
    [forceScore, forceLambda] = predict_score_from_fit(cfg, ledger, ...
        deviceInputs, withheld, forceFit);
    alts = protected_alternative_scores(ledger, withheld);

    rows(k).binary_score = binaryScore;
    rows(k).force_modulated_score = forceScore;
    rows(k).binary_lambda_W = binaryLambda;
    rows(k).force_lambda_W = forceLambda;
    rows(k).best_M0_score = alts.bestM0;
    rows(k).best_uniform_score = alts.uniform;
    rows(k).best_shuffled_score = alts.shuffled;
    rows(k).best_central_lane_score = alts.centralLane;
    rows(k).best_required_control_score = alts.bestRequiredControl;
    rows(k).best_protected_alternative_score = min([alts.bestM0, ...
        alts.uniform, alts.shuffled, alts.centralLane], [], 'omitnan');
    rows(k).force_margin_vs_binary_after_q_penalty = binaryScore - ...
        forceScore - cfg.phase5B1.qComplexityPenalty;
    rows(k).force_margin_vs_best_protected = ...
        rows(k).best_protected_alternative_score - forceScore;
    if forceFit.training_mean_score(1) < binaryFit.training_mean_score(1)
        selectedFit = forceFit;
        rows(k).training_selected_activation_law = "film_force_modulated_activation";
        rows(k).training_selected_score = forceFit.training_mean_score(1);
        rows(k).training_selected_heldout_score = forceScore;
        rows(k).training_selected_lambda_W = forceLambda;
    else
        selectedFit = binaryFit;
        rows(k).training_selected_activation_law = "binary_geometry_activation";
        rows(k).training_selected_score = binaryFit.training_mean_score(1);
        rows(k).training_selected_heldout_score = binaryScore;
        rows(k).training_selected_lambda_W = binaryLambda;
    end
    rows(k).training_selected_mechanism = string(selectedFit.mechanism(1));
    rows(k).training_selected_case_family = string(selectedFit.case_family(1));
    rows(k).training_selected_seed = selectedFit.seed(1);
    rows(k).selected_mechanism = string(forceFit.mechanism(1));
    rows(k).selected_case_family = string(forceFit.case_family(1));
    rows(k).selected_seed = forceFit.seed(1);
    rows(k).lambda_B = forceFit.lambda_B(1);
    rows(k).lambda_C = forceFit.lambda_C(1);
    rows(k).q = forceFit.q(1);
    rows(k).status = pass_fail(rows(k).force_margin_vs_binary_after_q_penalty > 0 && ...
        rows(k).force_margin_vs_best_protected > 0);
    rows(k).note = "Training selects law, coefficients, mechanism, and global tuple; heldout row is not reselected.";
end
heldout = struct2table(rows);
end

function [bestRow, candidates] = fit_one_family(cfg, ledger, deviceInputs, ...
    trainDevices, family)
basis = candidate_basis_rows(ledger);
paramGrid = activation_param_grid(cfg, family);
rows = repmat(empty_fit_row(), max(1, height(basis) * height(paramGrid)), 1);
row = 0;
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
        rows(row).lambda_C = paramGrid.lambda_C(iParam);
        rows(row).q = paramGrid.q(iParam);
        scores = NaN(numel(trainDevices), 1);
        lambdas = NaN(numel(trainDevices), 1);
        for k = 1:numel(trainDevices)
            [scores(k), lambdas(k)] = predict_score_for_basis(cfg, ledger, ...
                deviceInputs, trainDevices(k), rows(row));
        end
        rows(row).training_device_count = numel(trainDevices);
        rows(row).training_mean_score = finite_mean(scores);
        rows(row).training_mean_lambda_W = finite_mean(lambdas);
        rows(row).score_surface_policy = "linear interpolation between local-M0 and solved frozen weak-link row";
    end
end
candidates = struct2table(rows(1:row));
candidates = sortrows(candidates, {'training_mean_score','activation_law','mechanism'});
bestRow = candidates(1, :);
bestRow = table2struct(bestRow);
end

function [score, lambdaW] = predict_score_from_fit(cfg, ledger, deviceInputs, device, fitRow)
row = table2struct(fitRow(1, :));
[score, lambdaW] = predict_score_for_basis(cfg, ledger, deviceInputs, device, row);
end

function [score, lambdaW] = predict_score_for_basis(cfg, ledger, deviceInputs, device, fitRow)
lambdaW = activation_lambda(cfg, deviceInputs, device, fitRow);
weakScore = solved_weak_score(ledger, device, fitRow);
localScore = local_m0_score(ledger, device);
lambdaSolved = max(0, min(cfg.phase5B1.lambdaMax, 1 - fitRow.basis_gammaW));
if ~isfinite(localScore) || ~isfinite(weakScore) || ~isfinite(lambdaSolved) || lambdaSolved <= 0
    score = NaN;
    return;
end
frac = max(0, min(1, lambdaW ./ lambdaSolved));
score = localScore + frac .* (weakScore - localScore);
score = score + cfg.phase5B.complexityPenaltyLambda .* complexity_for(fitRow.model_level);
if string(fitRow.activation_law) == "film_force_modulated_activation"
    score = score + cfg.phase5B1.qComplexityPenalty;
end
end

function lambdaW = activation_lambda(cfg, deviceInputs, device, fitRow)
idx = deviceInputs.device == string(device);
if ~any(idx)
    lambdaW = NaN;
    return;
end
k = find(idx, 1, 'first');
B = double(deviceInputs.B_half_encapsulated(k));
C = double(deviceInputs.C_crack(k));
F = abs(deviceInputs.film_force_N_per_m(k));
switch string(fitRow.activation_law)
    case "binary_geometry_activation"
        lambdaW = fitRow.lambda_B .* B + fitRow.lambda_C .* C;
    case "film_force_modulated_activation"
        forceFactor = (F ./ cfg.phase5B1.F0_N_per_m) .^ fitRow.q;
        lambdaW = fitRow.lambda_B .* B .* forceFactor + fitRow.lambda_C .* C;
    otherwise
        lambdaW = NaN;
end
lambdaW = max(cfg.phase5B1.lambdaLowerBound, ...
    min(cfg.phase5B1.lambdaMax, lambdaW));
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

function score = local_m0_score(ledger, device)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.model_level == "M0";
if any(idx)
    score = min(ledger.total_LevelA_score(idx));
else
    score = NaN;
end
end

function alts = protected_alternative_scores(ledger, device)
alts = struct();
alts.bestM0 = local_m0_score(ledger, device);
alts.uniform = mechanism_best_score(ledger, device, "uniform weak links");
alts.shuffled = mechanism_best_score(ledger, device, "shuffled weak links");
alts.centralLane = mechanism_best_score(ledger, device, "central-lane / 1D-like");
alts.bestRequiredControl = mechanism_role_best_score(ledger, device, "required_control");
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

function score = mechanism_role_best_score(ledger, device, role)
idx = ledger.device == string(device) & ledger.run_status == "scored" & ...
    ledger.role == string(role);
if any(idx)
    score = min(ledger.total_LevelA_score(idx));
else
    score = NaN;
end
end

function grid = activation_param_grid(cfg, family)
lambdaB = cfg.phase5B1.lambdaBGrid(:);
lambdaC = cfg.phase5B1.lambdaCGrid(:);
if string(family) == "binary_geometry_activation"
    rows = repmat(struct('lambda_B', NaN, 'lambda_C', NaN, 'q', NaN), ...
        numel(lambdaB) * numel(lambdaC), 1);
    row = 0;
    for i = 1:numel(lambdaB)
        for j = 1:numel(lambdaC)
            row = row + 1;
            rows(row).lambda_B = lambdaB(i);
            rows(row).lambda_C = lambdaC(j);
            rows(row).q = NaN;
        end
    end
else
    qVals = cfg.phase5B1.qGrid(:);
    rows = repmat(struct('lambda_B', NaN, 'lambda_C', NaN, 'q', NaN), ...
        numel(lambdaB) * numel(lambdaC) * numel(qVals), 1);
    row = 0;
    for i = 1:numel(lambdaB)
        for j = 1:numel(lambdaC)
            for q = 1:numel(qVals)
                row = row + 1;
                rows(row).lambda_B = lambdaB(i);
                rows(row).lambda_C = lambdaC(j);
                rows(row).q = qVals(q);
            end
        end
    end
end
grid = struct2table(rows);
end

function preservation = build_secondary_preservation(cfg, evidence)
devices = ["AS001"; "AS004"; "AS006"];
rows = repmat(struct('device', "", 'secondary_status', "", ...
    'phase5B_preferred_model', "", 'phase5B_conclusion', "", ...
    'preservation_status', "", 'note', ""), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    if isempty(evidence) || ~ismember('device', evidence.Properties.VariableNames)
        eidx = false;
    else
        eidx = evidence.device == device;
    end
    if ~any(eidx)
        rows(k).secondary_status = "missing_evidence_row";
        rows(k).phase5B_preferred_model = "unresolved";
        rows(k).phase5B_conclusion = "Phase 5B evidence table unavailable.";
        rows(k).preservation_status = "incomplete";
        rows(k).note = "Secondary preservation could not be checked.";
        continue;
    end
    j = find(eidx, 1, 'first');
    rows(k).secondary_status = string(evidence.secondary_probe_status(j));
    rows(k).phase5B_preferred_model = string(evidence.preferred_model(j));
    rows(k).phase5B_conclusion = string(evidence.evidence_conclusion(j));
    if any(device == ["AS004"; "AS006"])
        ok = ismember(string(evidence.preferred_model(j)), ["M1"; "M2"; "structured"]);
        rows(k).preservation_status = pass_fail(ok);
        rows(k).note = "Structured secondary evidence must survive because secondary traces are not used in activation-law fitting.";
    else
        ok = ismember(string(evidence.preferred_model(j)), ["M0"; "unresolved"]);
        rows(k).preservation_status = pass_fail(ok);
        rows(k).note = "AS001 is expected to remain mixed/unresolved or reduce to M0 without special tuning.";
    end
end
preservation = struct2table(rows);
end

function gates = build_activation_gates(cfg, archive, heldout, preservation, phase5BGates)
rows = repmat(empty_gate_row(), 7, 1);
row = 0;

row = row + 1;
rows(row).gate = "phase5B_baseline_frozen";
rows(row).required = true;
rows(row).status = pass_fail(all(archive.exists));
rows(row).evidence = sprintf('%d/%d baseline files found.', ...
    sum(archive.exists), height(archive));
rows(row).note = "5B.1 writes a separate archive and does not rewrite Phase 5B baseline results.";

row = row + 1;
rows(row).gate = "activation_bounds_frozen";
rows(row).required = true;
okBounds = cfg.phase5B1.lambdaLowerBound == 0 && ...
    cfg.phase5B1.lambdaUpperBound == 1 && ...
    cfg.phase5B1.qLowerBound == 0.5 && cfg.phase5B1.qUpperBound == 3.0 && ...
    cfg.phase5B1.F0_N_per_m == 40;
rows(row).status = pass_fail(okBounds);
rows(row).evidence = sprintf('lambda in [%g,%g], q in [%g,%g], F0=%g N/m.', ...
    cfg.phase5B1.lambdaLowerBound, cfg.phase5B1.lambdaUpperBound, ...
    cfg.phase5B1.qLowerBound, cfg.phase5B1.qUpperBound, ...
    cfg.phase5B1.F0_N_per_m);
rows(row).note = "The bounds are fixed before heldout outcomes are interpreted.";

row = row + 1;
rows(row).gate = "no_device_specific_lambdas";
rows(row).required = true;
rows(row).status = "pass";
rows(row).evidence = "Only global lambda_B, lambda_C, and q are searched.";
rows(row).note = "No lambda_W,d parameter is fitted independently.";

row = row + 1;
rows(row).gate = "force_modulated_beats_binary";
rows(row).required = true;
okForce = heldout.force_margin_vs_binary_after_q_penalty > 0;
rows(row).status = pass_fail(sum(okForce) >= 2);
rows(row).evidence = sprintf('%d/%d heldout folds beat binary after q penalty.', ...
    sum(okForce), height(heldout));
rows(row).note = "Training improvement alone is insufficient; this gate uses heldout folds.";

row = row + 1;
rows(row).gate = "force_modulated_beats_protected_alternatives";
rows(row).required = true;
okProtected = heldout.force_margin_vs_best_protected > 0;
rows(row).status = pass_fail(sum(okProtected) >= 2);
rows(row).evidence = sprintf('%d/%d heldout folds beat M0/uniform/shuffled/central-lane.', ...
    sum(okProtected), height(heldout));
rows(row).note = "The activation law must beat protected alternatives, not just binary geometry.";

row = row + 1;
rows(row).gate = "secondary_probe_evidence_preserved";
rows(row).required = true;
okSecondary = preservation.preservation_status == "pass";
rows(row).status = pass_fail(all(okSecondary));
rows(row).evidence = sprintf('%d/%d secondary preservation checks pass.', ...
    sum(okSecondary), height(preservation));
rows(row).note = "Secondary probes remain held out from activation-law training.";

row = row + 1;
rows(row).gate = "phase5B_prior_gate_status_recorded";
rows(row).required = false;
if isempty(phase5BGates)
    rows(row).status = "incomplete";
    rows(row).evidence = "Phase 5B gate table unavailable.";
else
    rows(row).status = "pass";
    rows(row).evidence = sprintf('Phase 5B baseline had %d pass, %d fail, %d incomplete gates.', ...
        sum(phase5BGates.status == "pass"), sum(phase5BGates.status == "fail"), ...
        sum(phase5BGates.status == "incomplete"));
end
rows(row).note = "This records, rather than overwrites, the six-pass/one-fail baseline.";

gates = struct2table(rows(1:row));
end

function T = read_table(filePath)
if exist(filePath, 'file') ~= 2
    error('v8:phase5B1MissingFile', 'Required file not found: %s', char(filePath));
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
    error('v8:phase5B1MissingColumns', ...
        'File %s is missing required columns: %s. Present columns: %s', ...
        char(filePath), strjoin(cellstr(missing), ', '), ...
        strjoin(cellstr(present), ', '));
end
end

function row = empty_fit_row()
row = struct();
row.withheld_device = "";
row.training_devices = "";
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
row.lambda_C = NaN;
row.q = NaN;
row.training_device_count = 0;
row.training_mean_score = NaN;
row.training_mean_lambda_W = NaN;
row.score_surface_policy = "";
end

function row = empty_heldout_row()
row = struct();
row.test = "";
row.withheld_device = "";
row.training_devices = "";
row.binary_score = NaN;
row.force_modulated_score = NaN;
row.binary_lambda_W = NaN;
row.force_lambda_W = NaN;
row.best_M0_score = NaN;
row.best_uniform_score = NaN;
row.best_shuffled_score = NaN;
row.best_central_lane_score = NaN;
row.best_required_control_score = NaN;
row.best_protected_alternative_score = NaN;
row.force_margin_vs_binary_after_q_penalty = NaN;
row.force_margin_vs_best_protected = NaN;
row.training_selected_activation_law = "";
row.training_selected_score = NaN;
row.training_selected_heldout_score = NaN;
row.training_selected_lambda_W = NaN;
row.training_selected_mechanism = "";
row.training_selected_case_family = "";
row.training_selected_seed = NaN;
row.selected_mechanism = "";
row.selected_case_family = "";
row.selected_seed = NaN;
row.lambda_B = NaN;
row.lambda_C = NaN;
row.q = NaN;
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

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function status = pass_fail(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end
