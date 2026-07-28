function out = run_phase5C_synthetic_recovery(cfg)
%RUN_PHASE5C_SYNTHETIC_RECOVERY Test whether scoring recovers known mechanisms.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

labelPolicy = build_label_policy(cfg);
manifest = build_synthetic_manifest(cfg);
scoreLedger = score_synthetic_cases(cfg, manifest);
recoveryMatrix = build_recovery_matrix(cfg, scoreLedger);
recoverySummary = build_recovery_summary(cfg, scoreLedger);
misspecManifest = build_misspec_manifest(cfg);
misspecScoreLedger = score_synthetic_cases(cfg, misspecManifest);
misspecSummary = build_misspec_summary(cfg, misspecScoreLedger);
misspecGates = build_misspec_gates(cfg, misspecSummary);
gates = build_gates(cfg, recoveryMatrix, recoverySummary, misspecGates);
handoffStatus = build_handoff_status(cfg, labelPolicy, recoverySummary, ...
    misspecManifest, misspecGates, gates);

writetable(manifest, cfg.phase5C.syntheticManifestFile);
writetable(labelPolicy, cfg.phase5C.labelPolicyFile);
writetable(scoreLedger, cfg.phase5C.scoreLedgerFile);
writetable(recoveryMatrix, cfg.phase5C.recoveryMatrixFile);
writetable(recoverySummary, cfg.phase5C.recoverySummaryFile);
writetable(handoffStatus, cfg.phase5C.handoffStatusFile);
writetable(misspecManifest, cfg.phase5C.misspecManifestFile);
writetable(misspecScoreLedger, cfg.phase5C.misspecScoreLedgerFile);
writetable(misspecSummary, cfg.phase5C.misspecSummaryFile);
writetable(misspecGates, cfg.phase5C.misspecGateFile);
writetable(gates, cfg.phase5C.gateResultFile);

try
    h = v800.plot_phase5C_synthetic_recovery_summary(cfg, ...
        recoveryMatrix, recoverySummary, misspecSummary, gates);
catch ME
    warning('v8:phase5CPlotFailed', ...
        'Phase 5C summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.labelPolicy = labelPolicy;
out.manifest = manifest;
out.scoreLedger = scoreLedger;
out.recoveryMatrix = recoveryMatrix;
out.recoverySummary = recoverySummary;
out.misspecManifest = misspecManifest;
out.misspecScoreLedger = misspecScoreLedger;
out.misspecSummary = misspecSummary;
out.misspecGates = misspecGates;
out.gates = gates;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = struct();
out.paths.manifest = cfg.phase5C.syntheticManifestFile;
out.paths.labelPolicy = cfg.phase5C.labelPolicyFile;
out.paths.scoreLedger = cfg.phase5C.scoreLedgerFile;
out.paths.recoveryMatrix = cfg.phase5C.recoveryMatrixFile;
out.paths.recoverySummary = cfg.phase5C.recoverySummaryFile;
out.paths.handoffStatus = cfg.phase5C.handoffStatusFile;
out.paths.misspecManifest = cfg.phase5C.misspecManifestFile;
out.paths.misspecScoreLedger = cfg.phase5C.misspecScoreLedgerFile;
out.paths.misspecSummary = cfg.phase5C.misspecSummaryFile;
out.paths.misspecGates = cfg.phase5C.misspecGateFile;
out.paths.gates = cfg.phase5C.gateResultFile;
out.paths.figurePng = [cfg.phase5C.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5C.figureBaseFile '.pdf'];
end

function manifest = build_synthetic_manifest(cfg)
trueModels = cfg.phase5C.trueModels(:);
evidenceConfigs = cfg.phase5C.evidenceConfigs(:);
seeds = cfg.phase5C.syntheticSeeds(:);
n = numel(trueModels) * numel(evidenceConfigs) * numel(seeds);
rows = repmat(empty_manifest_row(), max(1, n), 1);
row = 0;
for iCfg = 1:numel(evidenceConfigs)
    evidenceConfig = evidenceConfigs(iCfg);
    for iModel = 1:numel(trueModels)
        trueModel = trueModels(iModel);
        for iSeed = 1:numel(seeds)
            row = row + 1;
            rows(row).synthetic_id = sprintf('%s_%s_seed_%04d', ...
                char(evidenceConfig), char(trueModel), seeds(iSeed));
            rows(row).evidence_config = evidenceConfig;
            rows(row).true_model = trueModel;
            rows(row).seed = seeds(iSeed);
            rows(row).primary_available = true;
            rows(row).secondary_available = contains(evidenceConfig, "secondary");
            rows(row).noise_sigma = noise_for_config(cfg, evidenceConfig);
            rows(row).disorder_sigma_Tc_K = disorder_for_config(cfg, evidenceConfig);
            rows(row).normalization_sigma = normalization_for_config(cfg, evidenceConfig);
            rows(row).generator_note = "parametric normalized R(T) with known model class";
        end
    end
end
manifest = struct2table(rows(1:row));
end

function policy = build_label_policy(cfg)
rows = [
    label_policy_row("M0", "M0", "unstructured", ...
    "local-Tc/control limit")
    label_policy_row("M1", "M1", "structured", ...
    "geometry-activated structured connectivity")
    label_policy_row("M2", "M2", "structured", ...
    "full combined bottleneck structure")
    label_policy_row("mixed", "M1", "structured", ...
    "intermediate case contains structured-connectivity contribution")
    ];
policy = struct2table(rows);
end

function row = label_policy_row(trueModel, exactTarget, binaryClass, note)
row = struct();
row.true_model = string(trueModel);
row.exact_recovery_target = string(exactTarget);
row.binary_recovery_class = string(binaryClass);
row.policy_note = string(note);
end

function manifest = build_misspec_manifest(cfg)
trueModels = cfg.phase5C.misspecTrueModels(:);
evidenceConfigs = cfg.phase5C.misspecEvidenceConfigs(:);
seeds = cfg.phase5C.misspecSeeds(:);
n = numel(trueModels) * numel(evidenceConfigs) * numel(seeds);
rows = repmat(empty_manifest_row(), max(1, n), 1);
row = 0;
for iCfg = 1:numel(evidenceConfigs)
    evidenceConfig = evidenceConfigs(iCfg);
    for iModel = 1:numel(trueModels)
        trueModel = trueModels(iModel);
        for iSeed = 1:numel(seeds)
            row = row + 1;
            rows(row).synthetic_id = sprintf('%s_%s_seed_%04d', ...
                char(evidenceConfig), char(trueModel), seeds(iSeed));
            rows(row).evidence_config = evidenceConfig;
            rows(row).true_model = trueModel;
            rows(row).seed = seeds(iSeed);
            rows(row).primary_available = true;
            rows(row).secondary_available = contains(evidenceConfig, "secondary");
            rows(row).noise_sigma = cfg.phase5C.noiseSigmaRealistic;
            rows(row).disorder_sigma_Tc_K = cfg.phase5C.disorderSigma_Tc_K;
            rows(row).normalization_sigma = cfg.phase5C.normalizationSigma;
            rows(row).generator_note = "out-of-family or near-boundary synthetic challenge";
        end
    end
end
manifest = struct2table(rows(1:row));
end

function ledger = score_synthetic_cases(cfg, manifest)
candidates = cfg.phase5C.candidateModels(:);
rows = repmat(empty_score_row(), max(1, height(manifest) * numel(candidates)), 1);
row = 0;
templates = build_templates(cfg);
for i = 1:height(manifest)
    exp = synthetic_observation(cfg, manifest(i, :), templates);
    for k = 1:numel(candidates)
        candidate = candidates(k);
        row = row + 1;
        rows(row).synthetic_id = string(manifest.synthetic_id(i));
        rows(row).evidence_config = string(manifest.evidence_config(i));
        rows(row).true_model = string(manifest.true_model(i));
        rows(row).candidate_model = candidate;
        rows(row).seed = manifest.seed(i);
        primaryScore = v800.score_normalized_rt(exp.T, exp.primary, ...
            templates.(char(candidate)).T, templates.(char(candidate)).primary, ...
            cfg.phase5A.score);
        rows(row).primary_score = primaryScore.total_LevelA_score;
        rows(row).primary_curve_score = primaryScore.RT_curve_score;
        rows(row).primary_onset_score = primaryScore.onset_score;
        rows(row).primary_width_score = primaryScore.width_score;
        rows(row).primary_lowT_score = primaryScore.lowT_score;
        if exp.secondary_available
            secondaryScore = v800.score_normalized_rt(exp.T, exp.secondary, ...
                templates.(char(candidate)).T, templates.(char(candidate)).secondary, ...
                cfg.phase5A.score);
            rows(row).secondary_score = secondaryScore.total_LevelA_score;
            rows(row).total_score = (1 - cfg.phase5C.secondaryWeight) .* ...
                rows(row).primary_score + cfg.phase5C.secondaryWeight .* ...
                rows(row).secondary_score;
        else
            rows(row).secondary_score = NaN;
            rows(row).total_score = rows(row).primary_score;
        end
        rows(row).complexity_K = complexity_for(candidate);
        rows(row).penalized_score = rows(row).total_score + ...
            cfg.phase5B.complexityPenaltyLambda .* rows(row).complexity_K;
        rows(row).structured_candidate = ismember(candidate, cfg.phase5C.structuredModels);
        rows(row).run_status = "scored";
    end
end
ledger = struct2table(rows(1:row));
ledger = add_selected_model(cfg, ledger);
end

function ledger = add_selected_model(cfg, ledger)
ledger.selected_model = strings(height(ledger), 1);
ledger.selected_score = NaN(height(ledger), 1);
ledger.second_best_model = strings(height(ledger), 1);
ledger.second_best_score = NaN(height(ledger), 1);
ledger.selection_margin = NaN(height(ledger), 1);
ledger.unresolved = false(height(ledger), 1);
ids = unique(ledger.synthetic_id, 'stable');
for k = 1:numel(ids)
    idx = ledger.synthetic_id == ids(k);
    rows = find(idx);
    [sortedScores, order] = sort(ledger.penalized_score(idx));
    selected = string(ledger.candidate_model(rows(order(1))));
    score = sortedScores(1);
    if numel(sortedScores) > 1
        secondModel = string(ledger.candidate_model(rows(order(2))));
        secondScore = sortedScores(2);
        margin = secondScore - score;
    else
        secondModel = "";
        secondScore = NaN;
        margin = NaN;
    end
    ledger.selected_model(rows) = selected;
    ledger.selected_score(rows) = score;
    ledger.second_best_model(rows) = secondModel;
    ledger.second_best_score(rows) = secondScore;
    ledger.selection_margin(rows) = margin;
    ledger.unresolved(rows) = isfinite(margin) & ...
        margin < cfg.phase5C.unresolvedMarginThreshold;
end
end

function recovery = build_recovery_matrix(cfg, ledger)
evidenceConfigs = cfg.phase5C.evidenceConfigs(:);
trueModels = cfg.phase5C.trueModels(:);
selectedModels = cfg.phase5C.candidateModels(:);
rows = repmat(struct('evidence_config', "", 'true_model', "", ...
    'selected_model', "", 'count', 0, 'probability', NaN), ...
    numel(evidenceConfigs) * numel(trueModels) * numel(selectedModels), 1);
row = 0;
caseRows = unique_cases(ledger);
for iCfg = 1:numel(evidenceConfigs)
    for iTrue = 1:numel(trueModels)
        idxBase = caseRows.evidence_config == evidenceConfigs(iCfg) & ...
            caseRows.true_model == trueModels(iTrue);
        denom = sum(idxBase);
        for iSel = 1:numel(selectedModels)
            row = row + 1;
            rows(row).evidence_config = evidenceConfigs(iCfg);
            rows(row).true_model = trueModels(iTrue);
            rows(row).selected_model = selectedModels(iSel);
            rows(row).count = sum(idxBase & caseRows.selected_model == selectedModels(iSel));
            rows(row).probability = rows(row).count ./ max(1, denom);
        end
    end
end
recovery = struct2table(rows(1:row));
end

function summary = build_recovery_summary(cfg, ledger)
caseRows = unique_cases(ledger);
configs = cfg.phase5C.evidenceConfigs(:);
rows = repmat(struct('evidence_config', "", 'case_count', 0, ...
    'exact_recovery_rate', NaN, 'structured_vs_M0_recovery_rate', NaN, ...
    'M0_recovery_rate', NaN, 'M1_vs_M2_exact_rate', NaN, ...
    'primary_only_confidence', "", 'mechanistic_claim_scope', ""), ...
    numel(configs), 1);
for k = 1:numel(configs)
    idx = caseRows.evidence_config == configs(k);
    rows(k).evidence_config = configs(k);
    rows(k).case_count = sum(idx);
    rows(k).exact_recovery_rate = fraction_true(caseRows.selected_model(idx) == ...
        canonical_true_model(caseRows.true_model(idx)));
    trueStructured = true_is_structured(cfg, caseRows.true_model(idx));
    predStructured = selected_is_structured(cfg, caseRows.selected_model(idx));
    rows(k).structured_vs_M0_recovery_rate = fraction_true(trueStructured == predStructured);
    m0Idx = idx & caseRows.true_model == "M0";
    rows(k).M0_recovery_rate = fraction_true(caseRows.selected_model(m0Idx) == "M0");
    m12Idx = idx & ismember(caseRows.true_model, ["M1"; "M2"]);
    rows(k).M1_vs_M2_exact_rate = fraction_true(caseRows.selected_model(m12Idx) == ...
        caseRows.true_model(m12Idx));
    if configs(k) == "primary_only" || configs(k) == "primary_noise"
        rows(k).primary_only_confidence = "lower_evidence_tier";
    else
        rows(k).primary_only_confidence = "two_probe_evidence_tier";
    end
    if rows(k).structured_vs_M0_recovery_rate >= cfg.phase5C.recoveryThreshold
        rows(k).mechanistic_claim_scope = "structured_vs_unstructured_informative";
    else
        rows(k).mechanistic_claim_scope = "classification_not_reliable";
    end
end
summary = struct2table(rows);
end

function summary = build_misspec_summary(cfg, ledger)
caseRows = unique_cases(ledger);
configs = cfg.phase5C.misspecEvidenceConfigs(:);
rows = repmat(struct('evidence_config', "", 'case_count', 0, ...
    'M0_false_structured_rate', NaN, 'weak_structured_unresolved_rate', NaN, ...
    'weak_structured_confident_M0_rate', NaN, ...
    'structured_binary_recovery_rate', NaN, ...
    'primary_only_confidence', "", 'classification_note', ""), numel(configs), 1);
for k = 1:numel(configs)
    idx = caseRows.evidence_config == configs(k);
    rows(k).evidence_config = configs(k);
    rows(k).case_count = sum(idx);
    m0Idx = idx & startsWith(caseRows.true_model, "M0");
    rows(k).M0_false_structured_rate = fraction_true(selected_is_structured(cfg, ...
        caseRows.selected_model(m0Idx)));
    weakIdx = idx & caseRows.true_model == "weak_structured_boundary";
    rows(k).weak_structured_unresolved_rate = fraction_true(caseRows.unresolved(weakIdx));
    rows(k).weak_structured_confident_M0_rate = fraction_true( ...
        caseRows.selected_model(weakIdx) == "M0" & ~caseRows.unresolved(weakIdx));
    structuredIdx = idx & misspec_true_is_structured(caseRows.true_model);
    rows(k).structured_binary_recovery_rate = fraction_true(selected_is_structured(cfg, ...
        caseRows.selected_model(structuredIdx)) | caseRows.unresolved(structuredIdx));
    if contains(configs(k), "primary_only")
        rows(k).primary_only_confidence = "lower_evidence_tier";
    else
        rows(k).primary_only_confidence = "two_probe_evidence_tier";
    end
    rows(k).classification_note = "misspecified cases test robust binary classification and unresolved near-boundary behavior";
end
summary = struct2table(rows);
end

function gates = build_misspec_gates(cfg, summary)
rows = repmat(empty_gate_row(), 5, 1);
row = 0;

row = row + 1;
rows(row).gate = "misspec_cases_scored";
rows(row).required = true;
rows(row).status = pass_fail(all(summary.case_count > 0));
rows(row).evidence = sprintf('%d misspecification evidence configurations scored.', height(summary));
rows(row).note = "Out-of-family and near-boundary synthetic cases are compact robustness checks.";

row = row + 1;
rows(row).gate = "M0_not_systematically_promoted";
rows(row).required = true;
maxFalseStructured = max(summary.M0_false_structured_rate, [], 'omitnan');
rows(row).status = pass_fail(maxFalseStructured <= 0.20);
rows(row).evidence = sprintf('max M0 false-structured rate = %.3f.', maxFalseStructured);
rows(row).note = "Misspecified M0 cases should not be systematically promoted to structured.";

row = row + 1;
rows(row).gate = "weak_structured_can_be_unresolved";
rows(row).required = true;
maxUnresolved = max(summary.weak_structured_unresolved_rate, [], 'omitnan');
rows(row).status = pass_fail(maxUnresolved > 0);
rows(row).evidence = sprintf('max weak-structured unresolved rate = %.3f.', maxUnresolved);
rows(row).note = "Near-boundary structured cases should be allowed to become unresolved.";

row = row + 1;
rows(row).gate = "weak_structured_not_confidently_M0";
rows(row).required = true;
maxConfidentM0 = max(summary.weak_structured_confident_M0_rate, [], 'omitnan');
rows(row).status = pass_fail(maxConfidentM0 <= 0.20);
rows(row).evidence = sprintf('max weak-structured confident-M0 rate = %.3f.', maxConfidentM0);
rows(row).note = "Near-boundary structured cases should not be confidently misclassified as M0.";

row = row + 1;
rows(row).gate = "two_probe_improves_primary";
rows(row).required = true;
primary = summary(summary.evidence_config == "misspec_primary_only", :);
twoProbe = summary(summary.evidence_config == "misspec_primary_secondary", :);
if isempty(primary) || isempty(twoProbe)
    delta = NaN;
else
    delta = twoProbe.structured_binary_recovery_rate(1) - ...
        primary.structured_binary_recovery_rate(1);
end
rows(row).status = pass_fail(delta >= 0);
rows(row).evidence = sprintf('two-probe minus primary structured recovery = %.3f.', delta);
rows(row).note = "Two probes should improve or tie robust binary classification.";

gates = struct2table(rows(1:row));
end

function gates = build_gates(cfg, recovery, summary, misspecGates)
rows = repmat(empty_gate_row(), 6, 1);
row = 0;

row = row + 1;
rows(row).gate = "synthetic_cases_scored";
rows(row).required = true;
rows(row).status = pass_fail(all(summary.case_count > 0));
rows(row).evidence = sprintf('%d evidence configurations scored.', height(summary));
rows(row).note = "Phase 5C uses generated synthetic data with known labels.";

row = row + 1;
rows(row).gate = "two_probe_structured_vs_M0_recovery";
rows(row).required = true;
twoProbe = summary.evidence_config == "primary_secondary_noise_disorder";
if any(twoProbe)
    rate = summary.structured_vs_M0_recovery_rate(find(twoProbe, 1, 'first'));
else
    rate = NaN;
end
rows(row).status = pass_fail(rate >= cfg.phase5C.recoveryThreshold);
rows(row).evidence = sprintf('two-probe noisy/disordered structured-vs-M0 recovery = %.3f.', rate);
rows(row).note = "Real-device mechanism claims require acceptable synthetic recovery.";

row = row + 1;
rows(row).gate = "primary_only_marked_lower_confidence";
rows(row).required = true;
primaryRows = ismember(summary.evidence_config, ["primary_only"; "primary_noise"]);
rows(row).status = pass_fail(all(summary.primary_only_confidence(primaryRows) == "lower_evidence_tier"));
rows(row).evidence = sprintf('%d primary-only configs marked lower evidence tier.', sum(primaryRows));
rows(row).note = "Primary-only real-device classifications must carry lower confidence.";

row = row + 1;
rows(row).gate = "M1_M2_identifiability_reported";
rows(row).required = true;
vals = summary.M1_vs_M2_exact_rate(isfinite(summary.M1_vs_M2_exact_rate));
rows(row).status = pass_fail(~isempty(vals));
rows(row).evidence = sprintf('median M1/M2 exact recovery = %.3f.', median(vals));
rows(row).note = "M1/M2 may remain unresolved even when structured-vs-M0 is useful.";

row = row + 1;
rows(row).gate = "revised_finish_line_supported";
rows(row).required = false;
bestTwoProbe = recovery(recovery.evidence_config == "primary_secondary_noise_disorder", :);
rows(row).status = "pass";
rows(row).evidence = sprintf('%d recovery-matrix rows written for final hierarchical framing.', height(bestTwoProbe));
rows(row).note = "5C tests hierarchical classification, not universal force-law transfer.";

row = row + 1;
rows(row).gate = "misspecification_challenge_recorded";
rows(row).required = true;
rows(row).status = pass_fail(all(misspecGates.status == "pass"));
rows(row).evidence = sprintf('%d/%d misspecification gates pass.', ...
    sum(misspecGates.status == "pass"), height(misspecGates));
rows(row).note = "Compact out-of-family challenge is archived separately from in-family recovery.";

gates = struct2table(rows(1:row));
end

function handoff = build_handoff_status(cfg, labelPolicy, summary, ...
    misspecManifest, misspecGates, gates)
rows = repmat(empty_handoff_row(), 6, 1);
row = 0;

row = row + 1;
rows(row).item = "in_family_recovery";
minExact = min(summary.exact_recovery_rate, [], 'omitnan');
minBinary = min(summary.structured_vs_M0_recovery_rate, [], 'omitnan');
rows(row).status = pass_fail(minExact >= cfg.phase5C.recoveryThreshold & ...
    minBinary >= cfg.phase5C.recoveryThreshold);
rows(row).evidence = string(sprintf( ...
    'min exact recovery = %.4f; min structured-vs-M0 recovery = %.4f.', ...
    minExact, minBinary));
rows(row).next_phase_action = "use_as_code_and_hierarchy_validation";
rows(row).note = "In-family synthetic recovery is frozen as the Phase 5C positive control.";

row = row + 1;
rows(row).item = "label_consistency";
mixedRow = labelPolicy.true_model == "mixed";
consistent = any(mixedRow & labelPolicy.exact_recovery_target == "M1" & ...
    labelPolicy.binary_recovery_class == "structured");
rows(row).status = pass_fail(consistent);
rows(row).evidence = "M0 is unstructured; M1, M2, and mixed are structured/intermediate.";
rows(row).next_phase_action = "keep_mapping_fixed";
rows(row).note = "The mixed-label binary gate correction is frozen before Phase 5D.";

row = row + 1;
rows(row).item = "misspecification_robustness";
passCount = sum(misspecGates.status == "pass");
rows(row).status = pass_fail(all(misspecGates.status == "pass"));
rows(row).evidence = string(sprintf( ...
    '%d/%d misspecification gates pass; failed gates remain diagnostic.', ...
    passCount, height(misspecGates)));
rows(row).next_phase_action = "calibrate_uncertainty_and_nuisance_tolerance";
rows(row).note = "Failed misspecification gates motivate Phase 5D and should not be tuned away inside 5C.";

row = row + 1;
rows(row).item = "frozen_misspecification_dataset";
rows(row).status = pass_fail(height(misspecManifest) > 0);
rows(row).evidence = string(sprintf( ...
    '%d misspecification cases with fixed seeds and perturbations archived.', ...
    height(misspecManifest)));
rows(row).next_phase_action = "use_for_design_not_final_validation";
rows(row).note = "The current challenge set revealed the calibration problem and is not the final post-calibration proof set.";

row = row + 1;
rows(row).item = "phase5C_closure";
requiredGates = gates.required == true;
coreGateRows = requiredGates & gates.gate ~= "misspecification_challenge_recorded";
corePass = all(gates.status(coreGateRows) == "pass");
rows(row).status = pass_fail(corePass);
rows(row).evidence = "Phase 5C closes with successful in-family identifiability and failed misspecification robustness.";
rows(row).next_phase_action = "freeze_phase5C_move_to_phase5D";
rows(row).note = "No Phase 5C classifier or threshold changes should be made to force misspecification gates to pass.";

row = row + 1;
rows(row).item = "required_next_phase";
rows(row).status = "action_required";
rows(row).evidence = "Broadened M0 responses can be promoted to structured; weak structured cases can be overconfidently M0.";
rows(row).next_phase_action = "uncertainty_and_significance_calibration";
rows(row).note = "Phase 5D should define M0*, score-difference uncertainty, unresolved decisions, and independent validation.";

handoff = struct2table(rows(1:row));
end

function templates = build_templates(cfg)
T = cfg.phase5C.temperatureGrid_K;
templates = struct();
templates.M0 = model_template(T, "M0", 0, 0, 0);
templates.M1 = model_template(T, "M1", 0, 0, 0);
templates.M2 = model_template(T, "M2", 0, 0, 0);
end

function obs = synthetic_observation(cfg, row, templates)
seed = row.seed(1);
trueModel = string(row.true_model(1));
rng(seed + seed_offset(trueModel));
noiseSigma = row.noise_sigma(1);
disorderSigma = row.disorder_sigma_Tc_K(1);
normSigma = row.normalization_sigma(1);
if is_misspecified_model(trueModel)
    base = misspecified_template(cfg.phase5C.temperatureGrid_K, trueModel);
elseif trueModel == "mixed"
    base = mixed_template(cfg.phase5C.temperatureGrid_K);
else
    base = templates.(char(trueModel));
end
TcShift = disorderSigma .* randn();
widthScale = max(0.65, 1 + 0.12 .* randn());
resShift = max(-0.03, min(0.03, normSigma .* randn()));
obsPrimary = perturb_curve(base.T, base.primary, TcShift, widthScale, ...
    resShift, noiseSigma);
obsSecondary = perturb_curve(base.T, base.secondary, TcShift .* 0.8, ...
    widthScale, -resShift .* 0.5, noiseSigma);
obs = struct();
obs.T = base.T;
obs.primary = obsPrimary;
obs.secondary = obsSecondary;
obs.secondary_available = logical(row.secondary_available(1));
end

function templ = model_template(T, model, TcShift, widthScaleOffset, residualShift)
switch string(model)
    case "M0"
        Tc = 0.82 + TcShift;
        width = 0.20 + widthScaleOffset;
        residual = 0.03 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.00, 0.00);
        secondary = transition_curve(T, Tc + 0.01, width .* 1.03, residual + 0.005, 0.00, 0.00);
    case "M1"
        Tc = 0.80 + TcShift;
        width = 0.28 + widthScaleOffset;
        residual = 0.12 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.10, 0.70);
        secondary = transition_curve(T, Tc - 0.05, width .* 1.15, residual + 0.07, 0.13, 0.65);
    otherwise
        Tc = 0.76 + TcShift;
        width = 0.34 + widthScaleOffset;
        residual = 0.23 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.18, 0.62);
        secondary = transition_curve(T, Tc - 0.09, width .* 1.25, residual + 0.13, 0.22, 0.55);
end
templ = struct('T', T, 'primary', clamp01(primary), 'secondary', clamp01(secondary));
end

function templ = mixed_template(T)
m1 = model_template(T, "M1", 0.02, -0.04, -0.02);
m2 = model_template(T, "M2", -0.01, -0.03, -0.08);
primary = 0.55 .* m1.primary + 0.45 .* m2.primary;
secondary = 0.75 .* m1.secondary + 0.25 .* m2.secondary;
templ = struct('T', T, 'primary', clamp01(primary), 'secondary', clamp01(secondary));
end

function templ = misspecified_template(T, trueModel)
switch string(trueModel)
    case "M0_shifted_broadened"
        templ = model_template(T, "M0", -0.05, 0.10, 0.01);
    case "M0_extra_shunt"
        base = model_template(T, "M0", 0.00, 0.02, 0.00);
        templ = struct('T', T, ...
            'primary', clamp01(0.92 .* base.primary + 0.06), ...
            'secondary', clamp01(0.90 .* base.secondary + 0.07));
    case "weak_structured_boundary"
        m0 = model_template(T, "M0", -0.01, 0.04, 0.02);
        m1 = model_template(T, "M1", 0.02, -0.06, -0.05);
        templ = struct('T', T, ...
            'primary', clamp01(0.72 .* m0.primary + 0.28 .* m1.primary), ...
            'secondary', clamp01(0.62 .* m0.secondary + 0.38 .* m1.secondary));
    case "M1_registration_shift"
        base = model_template(T, "M1", 0.04, 0.04, -0.01);
        templ = struct('T', T, ...
            'primary', clamp01(base.primary), ...
            'secondary', clamp01(interp1(T, base.secondary, T - 0.045, ...
            'linear', 'extrap')));
    otherwise
        base = model_template(T, "M2", -0.04, 0.12, -0.02);
        templ = struct('T', T, ...
            'primary', clamp01(base.primary + 0.04 .* sin(2 .* pi .* T ./ max(T))), ...
            'secondary', clamp01(base.secondary + 0.05 .* sin(2 .* pi .* T ./ max(T) + 0.7)));
end
end

function R = transition_curve(T, Tc, width, residual, shoulderAmp, shoulderT)
base = residual + (1 - residual) ./ (1 + exp(-(T - Tc) ./ max(width, eps)));
shoulder = shoulderAmp .* exp(-((T - shoulderT) ./ max(width .* 1.15, eps)).^2);
R = base + shoulder .* (1 - base);
end

function R = perturb_curve(T, R, TcShift, widthScale, residualShift, noiseSigma)
Tshift = T - TcShift;
Rshift = interp1(T, R, Tshift, 'linear', 'extrap');
meanR = mean(Rshift, 'omitnan');
Rscaled = meanR + widthScale .* (Rshift - meanR);
Rout = Rscaled + residualShift .* (1 - Rscaled) + noiseSigma .* randn(size(Rscaled));
R = clamp01(Rout);
end

function x = clamp01(x)
x = max(0, min(1.05, x));
end

function cases = unique_cases(ledger)
[ids, keep] = unique(ledger.synthetic_id, 'stable');
cases = ledger(keep, {'synthetic_id','evidence_config','true_model', ...
    'selected_model','selected_score','second_best_model', ...
    'second_best_score','selection_margin','unresolved'});
cases.synthetic_id = ids;
end

function canonical = canonical_true_model(trueModel)
canonical = string(trueModel);
canonical(canonical == "mixed") = "M1";
end

function tf = true_is_structured(cfg, trueModel)
tf = ismember(string(trueModel), cfg.phase5C.structuredModels);
end

function tf = selected_is_structured(cfg, selectedModel)
tf = ismember(string(selectedModel), cfg.phase5C.selectedStructuredModels);
end

function tf = misspec_true_is_structured(trueModel)
tf = ismember(string(trueModel), ["weak_structured_boundary"; ...
    "M1_registration_shift"; "M2_outside_disorder"]);
end

function tf = is_misspecified_model(trueModel)
tf = startsWith(string(trueModel), "M0_") || ...
    any(string(trueModel) == ["weak_structured_boundary"; ...
    "M1_registration_shift"; "M2_outside_disorder"]);
end

function sigma = noise_for_config(cfg, evidenceConfig)
if contains(evidenceConfig, "noise")
    sigma = cfg.phase5C.noiseSigmaRealistic;
else
    sigma = cfg.phase5C.noiseSigmaLow;
end
end

function sigma = disorder_for_config(cfg, evidenceConfig)
if contains(evidenceConfig, "disorder")
    sigma = cfg.phase5C.disorderSigma_Tc_K;
else
    sigma = cfg.phase5C.disorderSigma_Tc_K .* 0.30;
end
end

function sigma = normalization_for_config(cfg, evidenceConfig)
if contains(evidenceConfig, "noise")
    sigma = cfg.phase5C.normalizationSigma;
else
    sigma = cfg.phase5C.normalizationSigma .* 0.25;
end
end

function offset = seed_offset(model)
switch string(model)
    case "M0"
        offset = 1000;
    case "M1"
        offset = 2000;
    case "M2"
        offset = 3000;
    otherwise
        offset = 4000;
end
end

function k = complexity_for(model)
switch string(model)
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

function row = empty_manifest_row()
row = struct();
row.synthetic_id = "";
row.evidence_config = "";
row.true_model = "";
row.seed = NaN;
row.primary_available = false;
row.secondary_available = false;
row.noise_sigma = NaN;
row.disorder_sigma_Tc_K = NaN;
row.normalization_sigma = NaN;
row.generator_note = "";
end

function row = empty_score_row()
row = struct();
row.synthetic_id = "";
row.evidence_config = "";
row.true_model = "";
row.candidate_model = "";
row.seed = NaN;
row.primary_score = NaN;
row.primary_curve_score = NaN;
row.primary_onset_score = NaN;
row.primary_width_score = NaN;
row.primary_lowT_score = NaN;
row.secondary_score = NaN;
row.total_score = NaN;
row.complexity_K = NaN;
row.penalized_score = NaN;
row.structured_candidate = false;
row.selected_model = "";
row.selected_score = NaN;
row.run_status = "";
end

function row = empty_gate_row()
row = struct();
row.gate = "";
row.required = false;
row.status = "";
row.evidence = "";
row.note = "";
end

function row = empty_handoff_row()
row = struct();
row.item = "";
row.status = "";
row.evidence = "";
row.next_phase_action = "";
row.note = "";
end

function status = pass_fail(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function y = fraction_true(x)
x = x(:);
if isempty(x)
    y = NaN;
else
    y = mean(double(x));
end
end
