function out = build_phase5D_calibration_plan(cfg)
%BUILD_PHASE5D_CALIBRATION_PLAN Predeclare Phase 5D calibration artifacts.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

scope = build_scope();
nuisanceFamily = build_nuisance_family();
scoreDifferencePlan = build_score_difference_plan();
syntheticSplit = build_synthetic_split(cfg);
boundarySweep = build_boundary_sweep(cfg);
successCriteria = build_success_criteria(cfg);
handoffArchive = build_handoff_archive(cfg);

writetable(scope, cfg.phase5D.scopeFile);
writetable(nuisanceFamily, cfg.phase5D.nuisanceFamilyFile);
writetable(scoreDifferencePlan, cfg.phase5D.scoreDifferencePlanFile);
writetable(syntheticSplit, cfg.phase5D.syntheticSplitFile);
writetable(boundarySweep, cfg.phase5D.boundarySweepFile);
writetable(successCriteria, cfg.phase5D.successCriteriaFile);
writetable(handoffArchive, cfg.phase5D.handoffArchiveFile);

out = struct();
out.config = cfg;
out.scope = scope;
out.nuisanceFamily = nuisanceFamily;
out.scoreDifferencePlan = scoreDifferencePlan;
out.syntheticSplit = syntheticSplit;
out.boundarySweep = boundarySweep;
out.successCriteria = successCriteria;
out.handoffArchive = handoffArchive;
out.paths = struct();
out.paths.scope = cfg.phase5D.scopeFile;
out.paths.nuisanceFamily = cfg.phase5D.nuisanceFamilyFile;
out.paths.scoreDifferencePlan = cfg.phase5D.scoreDifferencePlanFile;
out.paths.syntheticSplit = cfg.phase5D.syntheticSplitFile;
out.paths.boundarySweep = cfg.phase5D.boundarySweepFile;
out.paths.successCriteria = cfg.phase5D.successCriteriaFile;
out.paths.handoffArchive = cfg.phase5D.handoffArchiveFile;
end

function scope = build_scope()
phase = repmat("Phase 5D", 6, 1);
item = [
    "objective"
    "frozen_input"
    "forbidden_action"
    "primary_decision"
    "evidence_tiers"
    "final_validation_policy"
    ];
status = [
    "predeclared"
    "predeclared"
    "predeclared"
    "predeclared"
    "predeclared"
    "predeclared"
    ];
description = [
    "Calibrate nuisance tolerance, score uncertainty, and unresolved decisions for the M0/M1/M2 hierarchy."
    "Use Phase 5C in-family and misspecification outputs as frozen diagnostic inputs."
    "Do not retune Phase 5C thresholds or classifier rules to make its misspecification panel pass."
    "Classify support for structured connectivity versus M0* using score separation relative to uncertainty."
    "Primary-only and paired-probe classifications are calibrated separately."
    "Final performance must be evaluated on independent validation seeds and perturbations, not the Phase 5C challenge set."
    ];
scope = table(phase, item, status, description);
end

function nuisance = build_nuisance_family()
parameter = [
    "Tc_mean_shift_K"
    "Tc_distribution_width_K"
    "residual_normal_shunt"
    "normalization_window_shift"
    "temperature_offset_K"
    "probe_registration_shift"
    "disorder_amplitude_scale"
    ];
role = [
    "local-Tc nuisance"
    "local-Tc nuisance"
    "non-mechanistic conduction floor"
    "measurement normalization nuisance"
    "temperature-axis nuisance"
    "registration nuisance"
    "disorder nuisance"
    ];
initial_bounds = [
    "predeclare from calibration set"
    "predeclare from calibration set"
    "predeclare from calibration set"
    "predeclare from calibration set"
    "predeclare from calibration set"
    "predeclare from calibration set"
    "predeclare from calibration set"
    ];
penalty_policy = [
    "penalize distance from zero shift"
    "penalize excessive broadening"
    "penalize large shunt"
    "penalize deviation from nominal normalization"
    "penalize temperature-axis drift"
    "penalize large registration displacement"
    "penalize outside-prior disorder"
    ];
included_in_M0star = true(numel(parameter), 1);
nuisance = table(parameter, role, initial_bounds, penalty_policy, ...
    included_in_M0star);
end

function plan = build_score_difference_plan()
comparison = [
    "structured_vs_M0star"
    "M1_vs_M2"
    "M0star_vs_M1"
    "M0star_vs_M2"
    ];
score_difference = [
    "S_structured_min - S_M0star"
    "S_M1 - S_M2"
    "S_M0star - S_M1"
    "S_M0star - S_M2"
    ];
uncertainty_sources = [
    "disorder seeds; measurement noise; normalization; interpolation; nuisance parameters; registration"
    "disorder seeds; measurement noise; secondary-probe availability"
    "M0* nuisance envelope; disorder seeds; normalization"
    "M0* nuisance envelope; disorder seeds; normalization"
    ];
decision_rule = [
    "use Z score and unresolved band"
    "report exact level only when separation is significant"
    "candidate support only outside unresolved band"
    "candidate support only outside unresolved band"
    ];
plan = table(comparison, score_difference, uncertainty_sources, ...
    decision_rule);
end

function split = build_synthetic_split(cfg)
split_name = [
    "calibration"
    "independent_validation"
    "phase5C_misspecification_archive"
    ];
seed_range = [
    string(sprintf('%d-%d', cfg.phase5D.calibrationSeeds(1), cfg.phase5D.calibrationSeeds(end)))
    string(sprintf('%d-%d', cfg.phase5D.validationSeeds(1), cfg.phase5D.validationSeeds(end)))
    string(sprintf('%d-%d', cfg.phase5C.misspecSeeds(1), cfg.phase5C.misspecSeeds(end)))
    ];
purpose = [
    "select nuisance bounds, penalties, unresolved threshold, and Zcrit"
    "evaluate frozen calibrated decision rule"
    "diagnostic set that motivated Phase 5D; not final proof after calibration"
    ];
reuse_policy = [
    "may tune calibration"
    "no tuning after evaluation begins"
    "do not reuse as final validation set"
    ];
split = table(split_name, seed_range, purpose, reuse_policy);
end

function sweep = build_boundary_sweep(cfg)
lambda_W = cfg.phase5D.boundaryLambdaW(:);
n = numel(lambda_W);
rows = repmat(struct('lambda_W', NaN, 'target_observable', "", ...
    'primary_expected_behavior', "", 'two_probe_expected_behavior', ""), n, 1);
for k = 1:n
    rows(k).lambda_W = lambda_W(k);
    rows(k).target_observable = "P(structured), P(unresolved), P(M0star)";
    if lambda_W(k) == 0
        rows(k).primary_expected_behavior = "M0star supported or unresolved; low false structured";
        rows(k).two_probe_expected_behavior = "M0star supported or unresolved; low false structured";
    elseif lambda_W(k) <= 0.10
        rows(k).primary_expected_behavior = "mostly unresolved near boundary";
        rows(k).two_probe_expected_behavior = "more structured support than primary-only when detectable";
    else
        rows(k).primary_expected_behavior = "increasing structured support with calibrated confidence";
        rows(k).two_probe_expected_behavior = "higher structured detection than primary-only";
    end
end
sweep = struct2table(rows);
end

function criteria = build_success_criteria(cfg)
criterion = [
    "false_structured_promotion_M0star"
    "confident_M0star_for_weak_structured"
    "near_boundary_unresolved_behavior"
    "strong_structured_detection"
    "two_probe_improvement"
    "M1_M2_recovery_not_collapsed"
    "independent_validation_consistency"
    ];
target = [
    string(sprintf('<= %.2f', cfg.phase5D.falseStructuredTarget))
    string(sprintf('<= %.2f', cfg.phase5D.confidentM0WeakStructuredTarget))
    "unresolved should dominate ambiguous near-boundary cases"
    "high detection rate for strong structured cases"
    "paired probes improve or tie primary-only detection"
    "M0* nuisance expansion must not absorb clear M1/M2 cases"
    "frozen calibration performs similarly on new seeds and perturbations"
    ];
required = true(numel(criterion), 1);
predeclared_before_validation = true(numel(criterion), 1);
criteria = table(criterion, target, required, predeclared_before_validation);
end

function archive = build_handoff_archive(cfg)
files = [
    artifact("phase5C_label_mapping_policy", cfg.phase5C.labelPolicyFile)
    artifact("phase5C_synthetic_manifest", cfg.phase5C.syntheticManifestFile)
    artifact("phase5C_synthetic_score_ledger", cfg.phase5C.scoreLedgerFile)
    artifact("phase5C_recovery_matrix", cfg.phase5C.recoveryMatrixFile)
    artifact("phase5C_recovery_summary", cfg.phase5C.recoverySummaryFile)
    artifact("phase5C_misspecification_manifest", cfg.phase5C.misspecManifestFile)
    artifact("phase5C_misspecification_score_ledger", cfg.phase5C.misspecScoreLedgerFile)
    artifact("phase5C_misspecification_summary", cfg.phase5C.misspecSummaryFile)
    artifact("phase5C_misspecification_gates", cfg.phase5C.misspecGateFile)
    artifact("phase5C_handoff_status", cfg.phase5C.handoffStatusFile)
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
    rows(k).freeze_policy = "Phase 5C is frozen; misspecification failures motivate Phase 5D calibration.";
end
archive = struct2table(rows);
end

function a = artifact(name, pathValue)
a = struct('name', string(name), 'path', string(pathValue));
end
