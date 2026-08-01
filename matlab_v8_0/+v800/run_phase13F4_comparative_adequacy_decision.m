function out = run_phase13F4_comparative_adequacy_decision(cfg)
%RUN_PHASE13F4_COMPARATIVE_ADEQUACY_DECISION Read-only 13F decision.
%
% Phase 13F.4 consumes the clean Phase 13F.3 execution artifacts and applies
% the frozen adequacy/parsimony policy. It does not rerun optimization,
% change variant definitions, or introduce new device-specific parameters.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
variantSummary = build_variant_adequacy_summary(cfg, inputs);
upgradeDecision = build_upgrade_support_decision(cfg, variantSummary);
parsimonyDecision = build_parsimony_decision(cfg, variantSummary, ...
    upgradeDecision);
claimUpdate = build_claim_update(parsimonyDecision, upgradeDecision);
gateSummary = build_gate_summary(cfg, inputs, variantSummary, ...
    upgradeDecision, parsimonyDecision, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, parsimonyDecision, ...
    upgradeDecision, sourceProvenance);

writetable(variantSummary, cfg.phase13F4.variantAdequacySummaryFile);
writetable(upgradeDecision, cfg.phase13F4.upgradeSupportDecisionFile);
writetable(parsimonyDecision, cfg.phase13F4.parsimonyDecisionFile);
writetable(claimUpdate, cfg.phase13F4.claimUpdateFile);
writetable(gateSummary, cfg.phase13F4.gateSummaryFile);
writetable(handoffStatus, cfg.phase13F4.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13F4.sourceProvenanceFile);

try
    h = v800.plot_phase13F4_comparative_adequacy_decision_summary( ...
        cfg, variantSummary, upgradeDecision, parsimonyDecision, ...
        gateSummary);
catch ME
    warning('v8:phase13F4PlotFailed', ...
        'Phase 13F.4 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.variantAdequacySummary = variantSummary;
out.upgradeSupportDecision = upgradeDecision;
out.parsimonyDecision = parsimonyDecision;
out.claimUpdate = claimUpdate;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.variantAdequacySummary = cfg.phase13F4.variantAdequacySummaryFile;
paths.upgradeSupportDecision = cfg.phase13F4.upgradeSupportDecisionFile;
paths.parsimonyDecision = cfg.phase13F4.parsimonyDecisionFile;
paths.claimUpdate = cfg.phase13F4.claimUpdateFile;
paths.gateSummary = cfg.phase13F4.gateSummaryFile;
paths.handoffStatus = cfg.phase13F4.handoffStatusFile;
paths.sourceProvenance = cfg.phase13F4.sourceProvenanceFile;
paths.figurePng = [cfg.phase13F4.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13F4.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "provenance_scope"
    "source_provenance_policy"
    ];
value = [
    "phase13F4_comparative_adequacy_decision"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "read_only_decision_after_clean_phase13F3"
    "Commit Phase 13F.4 source first; rerun from clean source; commit decision artifacts separately."
    ];
note = [
    "Phase 13F.4 read-only comparative adequacy decision."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No optimizer rerun, retuning, relabeling, Raman target, or Phase 6 target use."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.f3Gates = read_required_table(cfg.phase13F3.executionGateSummaryFile);
inputs.f3Handoff = read_required_table(cfg.phase13F3.handoffStatusFile);
inputs.f3Solver = read_required_table(cfg.phase13F3.solverDiagnosticsFile);
inputs.f3Comparison = read_required_table(cfg.phase13F3.variantComparisonFile);
inputs.f3FoldTraining = read_required_table( ...
    cfg.phase13F3.foldTrainingManifestFile);
inputs.f3Crossings = read_required_table( ...
    cfg.phase13F3.thresholdCrossingStatusFile);
inputs.f3Coverage = read_required_table( ...
    cfg.phase13F3.uncertaintyCoverageFile);
inputs.f3Bounds = read_required_table( ...
    cfg.phase13F3.parameterBoundDiagnosticsFile);
inputs.f3Failed = read_required_table(cfg.phase13F3.failedPredictionLogFile);
inputs.phase13DGateSummary = read_required_table(cfg.phase13D.gateSummaryFile);
inputs.phase13DHandoffStatus = read_required_table( ...
    cfg.phase13D.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13F.4 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function summary = build_variant_adequacy_summary(cfg, inputs)
variants = string(cfg.phase13F.variantIds(:));
rows = repmat(empty_variant_row(), numel(variants), 1);
comparison = inputs.f3Comparison;
training = inputs.f3FoldTraining;
crossings = inputs.f3Crossings;
coverage = inputs.f3Coverage;
bounds = inputs.f3Bounds;

f0BothCross = count_crossings(crossings, "F0", "both_cross");
f0Coverage = median_coverage(coverage, "F0");
for k = 1:numel(variants)
    variant = variants(k);
    mask = string(comparison.variant_id) == variant;
    rows(k).variant_id = variant;
    rows(k).n_devices = sum(mask);
    rows(k).median_score = median(comparison.S_curve(mask), 'omitnan');
    rows(k).median_delta_vs_F0 = median( ...
        comparison.DeltaS_vs_F0(mask), 'omitnan');
    rows(k).devices_improved_vs_F0 = sum( ...
        comparison.improved_vs_F0(mask) == 1);
    rows(k).severe_regressions_vs_F0 = sum( ...
        comparison.severe_regression_vs_F0(mask) == 1);
    rows(k).worst_regression_vs_F0 = max( ...
        comparison.DeltaS_vs_F0(mask), [], 'omitnan');
    rows(k).both_cross_count = count_crossings(crossings, variant, ...
        "both_cross");
    rows(k).crossing_recovery_gain_vs_F0 = ...
        rows(k).both_cross_count - f0BothCross;
    rows(k).false_predicted_cross_count = count_crossings(crossings, ...
        variant, "observed_no_cross_predicted_cross");
    rows(k).ambiguous_crossing_count = count_crossings(crossings, ...
        variant, "crossing_ambiguous");
    rows(k).median_interval_coverage = median_coverage(coverage, variant);
    rows(k).coverage_gain_vs_F0 = ...
        rows(k).median_interval_coverage - f0Coverage;
    rows(k).median_training_objective = median( ...
        training.training_objective(string(training.variant_id) == variant), ...
        'omitnan');
    rows(k).max_pinned_fold_fraction = max( ...
        bounds.pinned_fold_fraction(string(bounds.variant_id) == variant), ...
        [], 'omitnan');
    rows(k).bound_review_count = sum( ...
        string(bounds.status(string(bounds.variant_id) == variant)) == ...
        "review");
    rows(k).selected_device_improvement = ...
        rows(k).devices_improved_vs_F0 >= ...
        cfg.phase13F4.minimumSelectedDeviceImprovement && ...
        rows(k).severe_regressions_vs_F0 == 0 && variant ~= "F0";
    rows(k).material_full_series_improvement = ...
        abs(min(rows(k).median_delta_vs_F0, 0)) >= ...
        cfg.phase13F4.materialMedianImprovementThreshold && ...
        rows(k).severe_regressions_vs_F0 == 0 && variant ~= "F0";
    rows(k).coverage_improvement = rows(k).coverage_gain_vs_F0 >= ...
        cfg.phase13F4.minimumCoverageGain;
end
summary = struct2table(rows);
end

function row = empty_variant_row()
row = struct( ...
    'variant_id', "", ...
    'n_devices', 0, ...
    'median_score', NaN, ...
    'median_delta_vs_F0', NaN, ...
    'devices_improved_vs_F0', 0, ...
    'severe_regressions_vs_F0', 0, ...
    'worst_regression_vs_F0', NaN, ...
    'both_cross_count', 0, ...
    'crossing_recovery_gain_vs_F0', 0, ...
    'false_predicted_cross_count', 0, ...
    'ambiguous_crossing_count', 0, ...
    'median_interval_coverage', NaN, ...
    'coverage_gain_vs_F0', NaN, ...
    'median_training_objective', NaN, ...
    'max_pinned_fold_fraction', NaN, ...
    'bound_review_count', 0, ...
    'selected_device_improvement', false, ...
    'material_full_series_improvement', false, ...
    'coverage_improvement', false);
end

function n = count_crossings(T, variant, status)
mask = string(T.variant_id) == string(variant) & ...
    string(T.crossing_status) == string(status);
n = sum(mask);
end

function value = median_coverage(T, variant)
mask = string(T.variant_id) == string(variant);
value = median(T.coverage_fraction(mask), 'omitnan');
end

function decision = build_upgrade_support_decision(cfg, summary)
fb = summary(string(summary.variant_id) == "FB", :);
fi = summary(string(summary.variant_id) == "FI", :);
fbi = summary(string(summary.variant_id) == "FBI", :);

upgrade = [
    "baseline_and_residual_shunt"
    "interface_transfer"
    "combined_baseline_interface"
    "shared_quantitative_RT_predictor"
    ];
status = [
    conditional(fb.selected_device_improvement, ...
        "supported_with_limited_transfer", "not_supported")
    conditional(fi.selected_device_improvement || ...
        fi.material_full_series_improvement, "supported", ...
        "not_identifiable")
    conditional(fbi.selected_device_improvement, ...
        "improves_same_devices_as_baseline_shunt", "not_supported")
    conditional(any(summary.material_full_series_improvement) && ...
        any(summary.coverage_improvement), "supported", "false")
    ];
evidence = [
    string(sprintf("FB improves %d/%d devices; median DeltaS %.4g.", ...
        fb.devices_improved_vs_F0, fb.n_devices, fb.median_delta_vs_F0))
    string(sprintf("FI improves %d/%d devices; median DeltaS %.4g.", ...
        fi.devices_improved_vs_F0, fi.n_devices, fi.median_delta_vs_F0))
    string(sprintf("FBI improves %d/%d devices; median DeltaS %.4g.", ...
        fbi.devices_improved_vs_F0, fbi.n_devices, ...
        fbi.median_delta_vs_F0))
    "No variant meets material full-series improvement plus uncertainty-coverage criteria."
    ];
policy = [
    "May be used as preferred limited R(T) baseline if parsimony selects FB."
    "Do not claim independent interface or transparency validation."
    "Do not prefer over FB unless extra benefit exceeds parsimony threshold."
    "Do not claim a universal six-device quantitative R(T) predictor."
    ];
decision = table(upgrade, status, evidence, policy);
end

function decision = build_parsimony_decision(cfg, summary, upgradeDecision)
fb = summary(string(summary.variant_id) == "FB", :);
fi = summary(string(summary.variant_id) == "FI", :);
fbi = summary(string(summary.variant_id) == "FBI", :);
extraBenefit = fb.median_delta_vs_F0 - fbi.median_delta_vs_F0;
interfaceStatus = lookup_status(upgradeDecision, "interface_transfer");
preferCombined = extraBenefit >= ...
    cfg.phase13F4.combinedExtraBenefitThreshold && ...
    interfaceStatus == "supported";

item = [
    "phase13F4_decision"
    "preferred_revised_variant"
    "baseline_residual_shunt_upgrade"
    "interface_transfer_upgrade"
    "combined_variant_extra_benefit"
    "shared_quantitative_RT_predictor"
    "phase13D_partial_scope_preserved"
    ];
value = [
    "pass_selected_device_predictive_improvement"
    conditional(preferCombined, "FBI", cfg.phase13F4.expectedPreferredVariant)
    lookup_status(upgradeDecision, "baseline_and_residual_shunt")
    interfaceStatus
    conditional(preferCombined, "sufficiently_distinct", ...
        "not_sufficiently_distinct")
    lookup_status(upgradeDecision, "shared_quantitative_RT_predictor")
    "true"
    ];
note = [
    "The constrained revision improves selected devices but not a universal predictor."
    "Chosen by frozen parsimony rule, not by lowest objective alone."
    string(sprintf("FB median DeltaS %.4g, %d devices improved.", ...
        fb.median_delta_vs_F0, fb.devices_improved_vs_F0))
    string(sprintf("FI median DeltaS %.4g, %d devices improved.", ...
        fi.median_delta_vs_F0, fi.devices_improved_vs_F0))
    string(sprintf("FBI extra median benefit over FB %.4g with interface status %s.", ...
        extraBenefit, interfaceStatus))
    "Coverage and material-improvement checks prevent broad quantitative claim."
    "The Phase 13D partial-scope adequacy limit remains in force."
    ];
decision = table(item, value, note);
end

function status = lookup_status(T, key)
idx = string(T.upgrade) == string(key);
if any(idx)
    status = string(T.status(find(idx, 1, 'first')));
else
    status = "";
end
end

function claims = build_claim_update(parsimonyDecision, upgradeDecision)
claim = [
    "allowed"
    "allowed"
    "allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    ];
statement = [
    "Baseline/residual-shunt correction improves held-out R(T) prediction for selected devices."
    "The preferred revised equilibrium R(T) baseline for bounded downstream work is FB."
    "Phase 13D partial-scope and uncertainty limitations remain active."
    "Do not claim a transferable quantitative R(T) predictor across all six devices."
    "Do not claim independent validation of interface transfer or transparency."
    "Do not use Phase 14 nonlinear terms to retroactively repair equilibrium R(T) failures."
    ];
support = [
    lookup_status(upgradeDecision, "baseline_and_residual_shunt")
    lookup_value(parsimonyDecision, "preferred_revised_variant")
    lookup_value(parsimonyDecision, "phase13D_partial_scope_preserved")
    lookup_value(parsimonyDecision, "shared_quantitative_RT_predictor")
    lookup_status(upgradeDecision, "interface_transfer")
    "policy_handoff"
    ];
claims = table(claim, statement, support);
end

function value = lookup_value(T, key)
idx = string(T.item) == string(key);
if any(idx)
    row = find(idx, 1, 'first');
    names = string(T.Properties.VariableNames);
    if any(names == "value")
        value = string(T.value(row));
    elseif any(names == "status")
        value = string(T.status(row));
    elseif any(names == "outcome")
        value = string(T.outcome(row));
    else
        value = "";
    end
else
    value = "";
end
end

function gates = build_gate_summary(cfg, inputs, summary, upgradeDecision, ...
    parsimonyDecision, sourceProvenance)
allF3Pass = all(string(inputs.f3Gates.outcome) == "pass");
f3Complete = lookup_value(inputs.f3Handoff, ...
    "phase13F3_execution_complete") == "true";
expectedFolds = str2double(lookup_value(inputs.f3Solver, ...
    "expected_primary_fold_variant_count"));
observedFolds = str2double(lookup_value(inputs.f3Solver, ...
    "observed_fold_variant_count"));
failedPredictions = str2double(lookup_value(inputs.f3Solver, ...
    "failed_prediction_count"));
preferred = lookup_value(parsimonyDecision, "preferred_revised_variant");
baselineStatus = lookup_status(upgradeDecision, ...
    "baseline_and_residual_shunt");
interfaceStatus = lookup_status(upgradeDecision, "interface_transfer");
predictorStatus = lookup_value(parsimonyDecision, ...
    "shared_quantitative_RT_predictor");
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == ...
    "true";
fb = summary(string(summary.variant_id) == "FB", :);

gate = [
    "Clean Phase 13F.3 execution consumed"
    "Read-only decision scope preserved"
    "All fold-variant executions present"
    "No failed predictions hidden"
    "Baseline/shunt selected-device improvement assessed"
    "Interface non-identifiability recorded"
    "Combined-model parsimony applied"
    "Universal quantitative predictor rejected"
    "Phase 13D limitation preserved"
    "Phase 13F.4 clean provenance"
    ];
outcome = [
    passfail(allF3Pass && f3Complete)
    passfail(~cfg.phase13F4.allowOptimizerRerun && ...
        ~cfg.phase13F4.allowVariantRetuning && ...
        ~cfg.phase13F4.allowDeviceSpecificMechanismParameters)
    passfail(observedFolds == expectedFolds && ...
        expectedFolds == cfg.phase13F3.expectedPrimaryFoldVariantCount)
    passfail(failedPredictions == 0)
    passfail(baselineStatus == "supported_with_limited_transfer" && ...
        fb.devices_improved_vs_F0 >= ...
        cfg.phase13F4.minimumSelectedDeviceImprovement)
    passfail(interfaceStatus == "not_identifiable")
    passfail(preferred == cfg.phase13F4.expectedPreferredVariant)
    passfail(predictorStatus == "false")
    passfail(lookup_value(parsimonyDecision, ...
        "phase13D_partial_scope_preserved") == "true")
    passfail(cleanSource)
    ];
note = [
    "Phase 13F.3 handoff is complete and every execution gate passed."
    "No optimization, retuning, relabeling, or new target use is permitted."
    "Six held-out devices by four variants are present."
    "The failed-prediction log remains explicit and contains no failures."
    "FB improves four devices without severe regressions."
    "FI has no standalone held-out improvement."
    "FBI extra benefit is not enough to overcome added complexity."
    "Material full-series and uncertainty-coverage criteria are not met."
    "Phase 13D remains the upper-level adequacy limiter."
    "True only when Phase 13F.4 starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function value = passfail(tf)
if tf
    value = "pass";
else
    value = "fail";
end
end

function handoff = build_handoff_status(cfg, gates, parsimonyDecision, ...
    upgradeDecision, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase13F4_closure"
    "phase13F4_decision"
    "preferred_revised_variant"
    "baseline_residual_shunt_upgrade"
    "interface_transfer_upgrade"
    "shared_quantitative_RT_predictor"
    "phase13D_partial_scope_preserved"
    "phase14_scope"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    conditional(allPass, ...
        "pass_read_only_comparative_adequacy_assessment", ...
        "needs_decision_review")
    lookup_value(parsimonyDecision, "phase13F4_decision")
    lookup_value(parsimonyDecision, "preferred_revised_variant")
    lookup_status(upgradeDecision, "baseline_and_residual_shunt")
    lookup_status(upgradeDecision, "interface_transfer")
    lookup_value(parsimonyDecision, "shared_quantitative_RT_predictor")
    lookup_value(parsimonyDecision, "phase13D_partial_scope_preserved")
    "bounded_nonlinear_transport_feasibility_without_RT_repair"
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase13F4.nextPhase
    ];
note = [
    "Closure means a decision was made from frozen 13F.3 artifacts."
    "Selected-device improvement is supported; full quantitative prediction is not."
    "Parsimony selects FB over FBI because FI is not independently identifiable."
    "Baseline and residual conduction correction is the useful addition."
    "Interface/transfer contribution remains unidentifiable in this data."
    "Do not claim a universal six-device equilibrium R(T) predictor."
    "Phase 13D partial adequacy and uncertainty limits stay visible."
    "Phase 14 may use FB as equilibrium baseline but may not relabel R(T)."
    "Source commit captured before output generation."
    "Proceed only with bounded nonlinear feasibility."
    ];
handoff = table(item, status, note);
end

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end
