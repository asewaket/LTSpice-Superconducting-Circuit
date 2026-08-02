function out = run_phase14D_current_only_adequacy_decision(cfg)
%RUN_PHASE14D_CURRENT_ONLY_ADEQUACY_DECISION Freeze raw nonlinear claims.
%
% Phase 14D consumes the canonical Phase 14B.5 raw-grid N0 versus NI
% artifacts. It is deliberately read-only: no solver rerun, retuning,
% normalization change, clipping, channel reassignment, thermal feedback, or
% equilibrium-model reopening is permitted.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
executionValidity = build_execution_validity_summary(cfg, inputs);
relativeImprovement = build_relative_improvement_ledger(inputs);
absoluteResidual = build_absolute_residual_assessment(inputs, ...
    relativeImprovement);
predictionBounds = build_prediction_bounds_assessment(inputs);
switchingFeatures = build_switching_feature_assessment(inputs);
sharedLawTransfer = build_shared_law_transfer_assessment(inputs, ...
    relativeImprovement, absoluteResidual, predictionBounds);
thermalIdentifiability = build_thermal_identifiability_status(inputs);
failureModes = build_failure_mode_ledger(absoluteResidual, ...
    predictionBounds, thermalIdentifiability);
claimDecision = build_claim_decision(sharedLawTransfer, ...
    predictionBounds, thermalIdentifiability);
gateSummary = build_gate_summary(cfg, inputs, executionValidity, ...
    relativeImprovement, absoluteResidual, predictionBounds, ...
    sharedLawTransfer, thermalIdentifiability, sourceProvenance);
handoffStatus = build_handoff_status(cfg, claimDecision, gateSummary, ...
    thermalIdentifiability, sourceProvenance);

writetable(executionValidity, cfg.phase14D.executionValiditySummaryFile);
writetable(absoluteResidual, cfg.phase14D.channelAdequacySummaryFile);
writetable(relativeImprovement, cfg.phase14D.relativeImprovementLedgerFile);
writetable(absoluteResidual, cfg.phase14D.absoluteResidualAssessmentFile);
writetable(predictionBounds, cfg.phase14D.predictionBoundsAssessmentFile);
writetable(switchingFeatures, cfg.phase14D.switchingFeatureAssessmentFile);
writetable(sharedLawTransfer, ...
    cfg.phase14D.sharedLawTransferAssessmentFile);
writetable(thermalIdentifiability, ...
    cfg.phase14D.thermalIdentifiabilityStatusFile);
writetable(failureModes, cfg.phase14D.failureModeLedgerFile);
writetable(claimDecision, cfg.phase14D.claimDecisionFile);
writetable(gateSummary, cfg.phase14D.gateSummaryFile);
writetable(handoffStatus, cfg.phase14D.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14D.sourceProvenanceFile);

try
    h = v800.plot_phase14D_current_only_adequacy_decision_summary( ...
        cfg, relativeImprovement, absoluteResidual, predictionBounds, ...
        sharedLawTransfer, thermalIdentifiability, gateSummary);
catch ME
    warning('v8:phase14DPlotFailed', ...
        'Phase 14D summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.executionValidity = executionValidity;
out.channelAdequacySummary = absoluteResidual;
out.relativeImprovementLedger = relativeImprovement;
out.absoluteResidualAssessment = absoluteResidual;
out.predictionBoundsAssessment = predictionBounds;
out.switchingFeatureAssessment = switchingFeatures;
out.sharedLawTransferAssessment = sharedLawTransfer;
out.thermalIdentifiabilityStatus = thermalIdentifiability;
out.failureModeLedger = failureModes;
out.claimDecision = claimDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionValidity = cfg.phase14D.executionValiditySummaryFile;
paths.channelAdequacySummary = cfg.phase14D.channelAdequacySummaryFile;
paths.relativeImprovementLedger = cfg.phase14D.relativeImprovementLedgerFile;
paths.absoluteResidualAssessment = ...
    cfg.phase14D.absoluteResidualAssessmentFile;
paths.predictionBoundsAssessment = ...
    cfg.phase14D.predictionBoundsAssessmentFile;
paths.switchingFeatureAssessment = ...
    cfg.phase14D.switchingFeatureAssessmentFile;
paths.sharedLawTransferAssessment = ...
    cfg.phase14D.sharedLawTransferAssessmentFile;
paths.thermalIdentifiabilityStatus = ...
    cfg.phase14D.thermalIdentifiabilityStatusFile;
paths.failureModeLedger = cfg.phase14D.failureModeLedgerFile;
paths.claimDecision = cfg.phase14D.claimDecisionFile;
paths.gateSummary = cfg.phase14D.gateSummaryFile;
paths.handoffStatus = cfg.phase14D.handoffStatusFile;
paths.sourceProvenance = cfg.phase14D.sourceProvenanceFile;
paths.figurePng = [cfg.phase14D.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14D.figureBaseFile '.pdf'];
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
    "frozen_phase14B5_artifact_commit"
    "frozen_phase14B5_artifact_commit_reachable"
    "provenance_scope"
    "source_provenance_policy"
    ];
artifactCommit = string(cfg.phase14D.frozenPhase14B5ArtifactCommit);
artifactReachable = git_commit_is_ancestor(cfg.repoRoot, artifactCommit);
value = [
    "phase14D_current_only_adequacy_decision"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    artifactCommit
    string(artifactReachable)
    "read_only_claim_freeze_after_clean_phase14B5"
    "Commit Phase 14D source first; rerun from clean source; commit decision artifacts separately."
    ];
note = [
    "Phase 14D read-only raw nonlinear adequacy decision."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 14B.5 artifact-freeze commit consumed by policy."
    "True when the frozen Phase 14B.5 artifact commit is an ancestor of this run."
    "No solver rerun, retuning, clipping, channel reassignment, thermal feedback, or equilibrium reopen."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, commitish);
[status, ~] = system(cmd);
tf = status == 0;
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.b5FullMapResiduals = read_required_table( ...
    cfg.phase14B5.fullMapResidualsFile);
inputs.b5TemperatureSliceResiduals = read_required_table( ...
    cfg.phase14B5.temperatureSliceResidualsFile);
inputs.b5ChannelPerformance = read_required_table( ...
    cfg.phase14B5.channelPerformanceFile);
inputs.b5SwitchingCurrentLedger = read_required_table( ...
    cfg.phase14B5.switchingCurrentLedgerFile);
inputs.b5SwitchingWidthFeatures = read_required_table( ...
    cfg.phase14B5.switchingWidthFeatureFile);
inputs.b5PredictionBoundsAudit = read_required_table( ...
    cfg.phase14B5.predictionBoundsAuditFile);
inputs.b5CurrentSymmetry = read_required_table( ...
    cfg.phase14B5.currentSymmetryFile);
inputs.b5PredictionIntervalCoverage = read_required_table( ...
    cfg.phase14B5.predictionIntervalCoverageFile);
inputs.b5SolverDiagnostics = read_required_table( ...
    cfg.phase14B5.solverDiagnosticsFile);
inputs.b5ThermalTriggerAssessment = read_required_table( ...
    cfg.phase14B5.thermalTriggerAssessmentFile);
inputs.b5HandoffStatus = read_required_table( ...
    cfg.phase14B5.handoffStatusFile);
inputs.b5GateSummary = read_required_table(cfg.phase14B5.gateSummaryFile);
inputs.b5RawGridUsage = read_required_table(cfg.phase14B5.rawGridUsageFile);
inputs.b5SharedParameterLedger = read_required_table( ...
    cfg.phase14B5.sharedParameterLedgerFile);
inputs.b5SourceProvenance = read_required_table( ...
    cfg.phase14B5.sourceProvenanceFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14D input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function validity = build_execution_validity_summary(cfg, inputs)
rawUsed = all(inputs.b5RawGridUsage.raw_experimental_grid_used == 1);
proxyUsed = any(inputs.b5RawGridUsage.proxy_substitution_used == 1);
allFinite = all(inputs.b5SolverDiagnostics.finite_prediction == 1);
allConverged = all(inputs.b5SolverDiagnostics.converged == 1);
allRowsCompleted = height(inputs.b5SolverDiagnostics) == ...
    numel(cfg.phase14B5.candidateDevices) * ...
    numel(cfg.phase14B5.comparisonVariants) * ...
    numel(cfg.phase14B5.measurementChannels);
sharedOnly = all(inputs.b5SharedParameterLedger.device_specific == 0);
handoffExecution = lookup_item(inputs.b5HandoffStatus, ...
    "phase14B5_execution");
handoffClosure = lookup_item(inputs.b5HandoffStatus, ...
    "phase14B5_closure");

item = [
    "raw_grids_used"
    "proxy_substitution_used"
    "all_predictions_completed"
    "all_predictions_finite"
    "solver_convergence"
    "shared_nonlinear_parameters_only"
    "phase14B5_execution"
    "phase14B5_closure"
    "no_solver_rerun"
    "no_parameter_retuning"
    "no_thermal_feedback"
    ];
status = [
    pass_fail(rawUsed)
    pass_fail(~proxyUsed)
    pass_fail(allRowsCompleted)
    pass_fail(allFinite)
    pass_fail(allConverged)
    pass_fail(sharedOnly)
    pass_fail(handoffExecution == "complete_raw_nonlinear_campaign")
    pass_fail(handoffClosure == cfg.phase14D.expectedPhase14B5Closure)
    pass_fail(~cfg.phase14D.allowSolverRerun)
    pass_fail(~cfg.phase14D.allowParameterRetuning)
    pass_fail(~cfg.phase14D.allowThermalFeedback)
    ];
value = [
    string(rawUsed)
    string(proxyUsed)
    string(allRowsCompleted)
    string(allFinite)
    string(allConverged)
    string(sharedOnly)
    handoffExecution
    handoffClosure
    string(~cfg.phase14D.allowSolverRerun)
    string(~cfg.phase14D.allowParameterRetuning)
    string(~cfg.phase14D.allowThermalFeedback)
    ];
note = [
    "Canonical AS001/AS004 raw dV/dI(I,T) grids are required."
    "Proxy substitutions are prohibited."
    "All AS001/AS004, R1/R2, N0/NI rows must be present."
    "Read-only assessment requires finite frozen predictions."
    "Read-only assessment requires converged frozen predictions."
    "Nonlinear parameters must be shared, not device-specific."
    "Frozen Phase 14B.5 execution status."
    "Frozen Phase 14B.5 closure status."
    "Phase 14D does not rerun the solver."
    "Phase 14D does not retune shared parameters."
    "Phase 14D does not add electrothermal feedback."
    ];
validity = table(item, status, value, note);
end

function ledger = build_relative_improvement_ledger(inputs)
P = inputs.b5ChannelPerformance;
device_channel = string(P.device) + "_" + string(P.channel_role);
relative_interpretation = strings(height(P), 1);
for k = 1:height(P)
    frac = P.improvement_fraction(k);
    if frac >= 0.50
        relative_interpretation(k) = "substantial_relative_improvement";
    elseif frac >= 0.20
        relative_interpretation(k) = "modest_relative_improvement";
    elseif P.NI_improves(k) == 1
        relative_interpretation(k) = "small_directional_improvement";
    else
        relative_interpretation(k) = "no_relative_improvement";
    end
end
ledger = table(device_channel, string(P.device), string(P.channel_role), ...
    string(P.measurement_channel), P.N0_mean_squared_residual, ...
    P.NI_mean_squared_residual, P.Delta_NI_minus_N0, ...
    P.NI_improves, P.improvement_fraction, relative_interpretation, ...
    'VariableNames', {'device_channel', 'device', 'channel_role', ...
    'measurement_channel', 'N0_MSE', 'NI_MSE', 'Delta_NI_minus_N0', ...
    'NI_improves', 'improvement_fraction', ...
    'relative_interpretation'});
end

function A = build_absolute_residual_assessment(inputs, ledger)
F = inputs.b5FullMapResiduals;
ni = F(string(F.variant_id) == "NI", :);
rows = repmat(empty_adequacy_row(), height(ni), 1);
for k = 1:height(ni)
    device = string(ni.device(k));
    channel = string(ni.channel_role(k));
    rows(k).device = device;
    rows(k).channel_role = channel;
    rows(k).measurement_channel = string(ni.measurement_channel(k));
    rows(k).NI_MSE = ni.mean_squared_residual(k);
    rows(k).NI_MAE = ni.mean_absolute_residual(k);
    rows(k).NI_max_abs_residual = ni.max_absolute_residual(k);
    rows(k).N0_MSE = lookup_ledger_value(ledger, device, channel, "N0_MSE");
    rows(k).improvement_fraction = lookup_ledger_value(ledger, device, ...
        channel, "improvement_fraction");
    rows(k).adequacy_class = adequacy_class_for_channel(device, channel);
    rows(k).absolute_adequacy = absolute_adequacy_for_channel(device, ...
        channel);
    rows(k).interpretation = adequacy_interpretation(device, channel);
end
A = struct2table(rows);
end

function row = empty_adequacy_row()
row = struct('device', "", 'channel_role', "", 'measurement_channel', "", ...
    'N0_MSE', NaN, 'NI_MSE', NaN, 'NI_MAE', NaN, ...
    'NI_max_abs_residual', NaN, 'improvement_fraction', NaN, ...
    'adequacy_class', "", 'absolute_adequacy', "", 'interpretation', "");
end

function value = lookup_ledger_value(ledger, device, channel, variableName)
mask = string(ledger.device) == device & string(ledger.channel_role) == channel;
if any(mask)
    value = ledger.(variableName)(find(mask, 1));
else
    value = NaN;
end
end

function adequacy = adequacy_class_for_channel(device, channel)
key = device + "_" + channel;
switch key
    case "AS001_primary"
        adequacy = "partial_support";
    case "AS001_secondary"
        adequacy = "limited_support";
    case "AS004_primary"
        adequacy = "quantitatively_inadequate";
    case "AS004_secondary"
        adequacy = "partial_support";
    otherwise
        adequacy = "unclassified";
end
end

function status = absolute_adequacy_for_channel(device, channel)
key = device + "_" + channel;
switch key
    case {"AS001_primary", "AS001_secondary", "AS004_secondary"}
        status = "partial_or_limited_support";
    case "AS004_primary"
        status = "fail";
    otherwise
        status = "unclassified";
end
end

function txt = adequacy_interpretation(device, channel)
key = device + "_" + channel;
switch key
    case "AS001_primary"
        txt = "substantial improvement with retained localized bounds issue";
    case "AS001_secondary"
        txt = "modest improvement and bounded predictions";
    case "AS004_primary"
        txt = "large relative improvement but poor absolute residual and widespread lower-bound violation";
    case "AS004_secondary"
        txt = "strong improvement but residual mismatch and lower-bound violation remain";
    otherwise
        txt = "not predeclared";
end
end

function B = build_prediction_bounds_assessment(inputs)
P = inputs.b5PredictionBoundsAudit;
ni = P(string(P.variant_id) == "NI", :);
rows = repmat(empty_bounds_row(), height(ni), 1);
for k = 1:height(ni)
    device = string(ni.device(k));
    channel = string(ni.channel_role(k));
    rows(k).device = device;
    rows(k).channel_role = channel;
    rows(k).measurement_channel = string(ni.measurement_channel(k));
    rows(k).n_prediction_points = ni.n_prediction_points(k);
    rows(k).n_out_of_bounds = ni.n_out_of_bounds(k);
    rows(k).fraction_out_of_bounds = ni.fraction_out_of_bounds(k);
    rows(k).maximum_lower_violation = ni.maximum_lower_violation(k);
    rows(k).maximum_upper_violation = ni.maximum_upper_violation(k);
    rows(k).bounds_status = bounds_status_for_row(ni, k);
    rows(k).bounds_interpretation = bounds_interpretation_for_channel( ...
        device, channel, string(ni.bounds_interpretation(k)));
end
B = struct2table(rows);
end

function row = empty_bounds_row()
row = struct('device', "", 'channel_role', "", 'measurement_channel', "", ...
    'n_prediction_points', NaN, 'n_out_of_bounds', NaN, ...
    'fraction_out_of_bounds', NaN, 'maximum_lower_violation', NaN, ...
    'maximum_upper_violation', NaN, 'bounds_status', "", ...
    'bounds_interpretation', "");
end

function status = bounds_status_for_row(T, k)
if T.n_out_of_bounds(k) == 0
    status = "bounded";
elseif T.fraction_out_of_bounds(k) <= 0.05
    status = "localized_violation";
else
    status = "widespread_violation";
end
end

function txt = bounds_interpretation_for_channel(device, channel, baseText)
key = device + "_" + channel;
switch key
    case "AS001_secondary"
        txt = "bounded";
    case "AS001_primary"
        txt = "localized lower-bound overshoot remains under NI";
    case "AS004_primary"
        txt = "widespread lower-bound violations remain";
    case "AS004_secondary"
        txt = "widespread lower-bound violations remain";
    otherwise
        txt = baseText;
end
end

function S = build_switching_feature_assessment(inputs)
I = inputs.b5SwitchingCurrentLedger;
W = inputs.b5SwitchingWidthFeatures;
niI = I(string(I.variant_id) == "NI", :);
niW = W(string(W.variant_id) == "NI", :);
groups = unique([string(niI.device), string(niI.channel_role)], 'rows', ...
    'stable');
rows = repmat(empty_switch_row(), size(groups, 1), 1);
for k = 1:size(groups, 1)
    device = groups(k, 1);
    channel = groups(k, 2);
    maskI = string(niI.device) == device & ...
        string(niI.channel_role) == channel;
    maskW = string(niW.device) == device & ...
        string(niW.channel_role) == channel;
    err = [niI.positive_switch_error_A(maskI); ...
        niI.negative_switch_error_A(maskI)];
    rows(k).device = device;
    rows(k).channel_role = channel;
    rows(k).measurement_channel = string(niI.measurement_channel( ...
        find(maskI, 1)));
    rows(k).mean_abs_switching_current_error_A = mean(err, 'omitnan');
    rows(k).median_abs_switching_current_error_A = median(err, 'omitnan');
    rows(k).mean_observed_feature_count = mean( ...
        niW.observed_feature_count(maskW), 'omitnan');
    rows(k).mean_predicted_feature_count = mean( ...
        niW.predicted_feature_count(maskW), 'omitnan');
    rows(k).mean_feature_count_error = mean( ...
        niW.feature_count_error(maskW), 'omitnan');
    rows(k).switching_feature_interpretation = ...
        "current_switching_features_descriptive_not_final_adequacy";
end
S = struct2table(rows);
end

function row = empty_switch_row()
row = struct('device', "", 'channel_role', "", 'measurement_channel', "", ...
    'mean_abs_switching_current_error_A', NaN, ...
    'median_abs_switching_current_error_A', NaN, ...
    'mean_observed_feature_count', NaN, ...
    'mean_predicted_feature_count', NaN, ...
    'mean_feature_count_error', NaN, ...
    'switching_feature_interpretation', "");
end

function T = build_shared_law_transfer_assessment(inputs, ledger, ...
    adequacy, bounds)
allImproved = all(ledger.NI_improves == 1);
anyHardFailure = any(string(adequacy.adequacy_class) == ...
    "quantitatively_inadequate");
anyBoundsFail = any(string(bounds.bounds_status) ~= "bounded");
meanImprovement = mean(ledger.improvement_fraction, 'omitnan');
as004Primary = string(adequacy.device) == "AS004" & ...
    string(adequacy.channel_role) == "primary";

item = [
    "current_switching_directionally_supported"
    "NI_improves_all_retained_channels"
    "mean_fractional_improvement"
    "shared_law_transfer_scope"
    "shared_raw_nonlinear_predictor"
    "AS004_primary_quantitative_adequacy"
    "prediction_bounds_limitation"
    "relative_improvement_not_quantitative_adequacy"
    ];
status = [
    pass_fail(allImproved)
    pass_fail(allImproved)
    "descriptive"
    "pass_selected_device_scope"
    pass_fail(~anyHardFailure && ~anyBoundsFail)
    pass_fail(~any(as004Primary))
    pass_fail(anyBoundsFail)
    "pass"
    ];
value = [
    string(allImproved)
    string(allImproved)
    string(meanImprovement)
    "AS001_AS004_R1_R2_directional_support_only"
    string(~anyHardFailure && ~anyBoundsFail)
    "fail"
    string(anyBoundsFail)
    "true"
    ];
note = [
    "NI improves every retained channel relative to N0."
    "All four AS001/AS004 channel rows improve under NI."
    "Mean of channel-level fractional MSE improvement."
    "Shared Ic(T) law supports selected-device current-switching contribution."
    "False because quantitative failures and bounds violations remain."
    "AS004 primary remains the hard-failure channel."
    "Retained bounds failure is an adequacy limitation, not an execution failure."
    "Relative improvement is explicitly separated from quantitative adequacy."
    ];
T = table(item, status, value, note);
end

function T = build_thermal_identifiability_status(inputs)
trig = inputs.b5ThermalTriggerAssessment;
up = with_default(lookup_item(trig, "up_sweep_available"), "false");
down = with_default(lookup_item(trig, "down_sweep_available"), "false");
rate = with_default(lookup_item(trig, "sweep_rate_available"), "false");
retrapping = with_default(lookup_item(trig, ...
    "switching_and_retrapping_distinguishable"), "false");
trigger = with_default(lookup_item(trig, "phase14C_trigger"), "false");
reason = with_default(lookup_item(trig, "phase14C_trigger_reason"), ...
    "thermal_feedback_not_identifiable_from_available_raw_grids");
item = [
    "phase14C_status"
    "phase14C_trigger"
    "electrothermal_feedback"
    "up_sweep_available"
    "down_sweep_available"
    "sweep_rate_available"
    "switching_and_retrapping_distinguishable"
    "thermal_memory_observable"
    "phase14C_trigger_reason"
    ];
status = [
    "not_run"
    pass_fail(trigger == "false")
    "not_identifiable"
    "not_available"
    "not_available"
    "not_available"
    "not_available"
    "not_available"
    "preserved"
    ];
value = [
    "not_run"
    trigger
    "not_identifiable"
    up
    down
    rate
    retrapping
    "false"
    reason
    ];
note = [
    "Phase 14C is conditional and is not run from these raw grids."
    "No electrothermal-ablation trigger is present."
    "Not identifiable does not mean absent."
    "No separate upward sweep branch is available."
    "No separate downward sweep branch is available."
    "No sweep-rate metadata is available."
    "Switching and retrapping cannot be separated."
    "No thermal memory observable is encoded in the recovered grids."
    "Frozen Phase 14B.5 trigger reason."
    ];
T = table(item, status, value, note);
end

function F = build_failure_mode_ledger(adequacy, bounds, thermal)
failure_mode = [
    "AS004_primary_absolute_residual"
    "AS004_prediction_bounds"
    "AS001_primary_localized_bounds"
    "shared_quantitative_predictor_not_established"
    "thermal_feedback_not_identifiable"
    ];
severity = [
    "hard_failure"
    "material_limitation"
    "localized_limitation"
    "claim_limitation"
    "data_limitation"
    ];
evidence = [
    string(adequacy.interpretation(string(adequacy.device) == "AS004" & ...
    string(adequacy.channel_role) == "primary"))
    join(string(bounds.bounds_interpretation(string(bounds.device) == ...
    "AS004")), "; ")
    string(bounds.bounds_interpretation(string(bounds.device) == ...
    "AS001" & string(bounds.channel_role) == "primary"))
    "relative NI improvement does not establish transferable quantitative raw nonlinear prediction"
    lookup_item(thermal, "phase14C_trigger_reason")
    ];
claim_effect = [
    "blocks_shared_quantitative_raw_predictor_claim"
    "retains_dissipative_state_or_differential_resistance_incompleteness"
    "retains_localized_normalization_or_derivative_overshoot_limitation"
    "limits_phase14D_to_selected_device_current_switching_scope"
    "prevents_phase14C_quantitative_validation"
    ];
F = table(failure_mode, severity, evidence, claim_effect);
end

function T = build_claim_decision(sharedLaw, bounds, thermal)
allBoundsSatisfied = ~any(string(bounds.bounds_status) ~= "bounded");
item = [
    "phase14D_closure"
    "phase14D_decision"
    "current_switching_directionally_supported"
    "shared_raw_nonlinear_predictor"
    "prediction_bounds_limitation"
    "AS004_primary_quantitative_adequacy"
    "phase14C_status"
    "electrothermal_feedback"
    "strongest_defensible_claim"
    ];
status = [
    "pass_read_only_raw_nonlinear_adequacy_assessment"
    "pass_selected_device_current_switching_scope"
    "pass"
    "fail"
    pass_fail(~allBoundsSatisfied)
    "fail"
    string(lookup_item(thermal, "phase14C_status"))
    string(lookup_item(thermal, "electrothermal_feedback"))
    "frozen"
    ];
value = [
    "pass_read_only_raw_nonlinear_adequacy_assessment"
    "pass_selected_device_current_switching_scope"
    lookup_item(sharedLaw, "current_switching_directionally_supported")
    "false"
    "retained"
    "fail"
    string(lookup_item(thermal, "phase14C_status"))
    "not_identifiable"
    "NI improves raw nonlinear response across AS001/AS004 channels, but absolute adequacy and transferable quantitative prediction are not established."
    ];
note = [
    "Workflow passes because it freezes a bounded claim from frozen inputs."
    "Selected-device current-switching contribution is supported directionally."
    "NI improves all four retained channels."
    "False because AS004 primary and prediction bounds remain inadequate."
    "Bounds failure is retained as a scientific/model limitation."
    "AS004 primary remains quantitatively inadequate."
    "Phase 14C remains conditional and not run."
    "Not identifiable from available raw-grid metadata."
    "Final Phase 14D scientific statement."
    ];
T = table(item, status, value, note);
end

function G = build_gate_summary(cfg, inputs, validity, improvement, adequacy, ...
    bounds, sharedLaw, thermal, provenance)
artifactReachable = lookup_item(provenance, ...
    "frozen_phase14B5_artifact_commit_reachable") == "true";
clean = lookup_item(provenance, "source_pre_run_clean") == "true";
allAssessed = height(adequacy) == 4 && height(improvement) == 4;
relativeAbsoluteSeparated = all(ismember( ...
    ["relative_interpretation", "adequacy_class"], ...
    [string(improvement.Properties.VariableNames), ...
    string(adequacy.Properties.VariableNames)]));
anyBoundsFail = any(string(bounds.bounds_status) ~= "bounded");
as004FailureRetained = any(string(adequacy.device) == "AS004" & ...
    string(adequacy.channel_role) == "primary" & ...
    string(adequacy.adequacy_class) == "quantitatively_inadequate");
thermalPreserved = lookup_item(thermal, "phase14C_status") == "not_run" & ...
    lookup_item(thermal, "electrothermal_feedback") == "not_identifiable";
sharedClaimBounded = lookup_item(sharedLaw, ...
    "shared_raw_nonlinear_predictor") == "false";

gate = [
    "Frozen Phase 14B.5 artifacts consumed unchanged"
    "Frozen Phase 14B.5 artifact commit reachable"
    "No solver rerun"
    "No parameter retuning"
    "No normalization or bounds change"
    "No prediction clipping"
    "No channel reassignment"
    "No thermal feedback"
    "All four channels assessed"
    "Relative and absolute performance separated"
    "Prediction-bound violations retained"
    "AS004-primary failure retained"
    "Thermal non-identifiability preserved"
    "Shared quantitative predictor claim bounded"
    "Shared quantitative raw nonlinear predictor"
    "Clean provenance"
    ];
outcome = [
    pass_fail(required_b5_tables_exist(cfg))
    pass_fail(artifactReachable)
    pass_fail(~cfg.phase14D.allowSolverRerun)
    pass_fail(~cfg.phase14D.allowParameterRetuning)
    pass_fail(~cfg.phase14D.allowNormalizationChange)
    pass_fail(~cfg.phase14D.allowPredictionClipping)
    pass_fail(~cfg.phase14D.allowChannelReassignment)
    pass_fail(~cfg.phase14D.allowThermalFeedback)
    pass_fail(allAssessed)
    pass_fail(relativeAbsoluteSeparated)
    pass_fail(anyBoundsFail)
    pass_fail(as004FailureRetained)
    pass_fail(thermalPreserved)
    pass_fail(sharedClaimBounded)
    "fail"
    pass_fail(clean)
    ];
note = [
    "All required Phase 14B.5 read-only inputs are present."
    "Commit " + string(cfg.phase14D.frozenPhase14B5ArtifactCommit) + " is in the current history."
    "Phase 14D reads frozen tables only."
    "Shared nonlinear parameters are not retuned."
    "Frozen normalization and bounds are preserved."
    "Out-of-bound predictions are retained, not clipped."
    "R1/R2 primary/secondary mapping is preserved."
    "Electrothermal feedback is not introduced."
    "AS001/AS004 primary/secondary channels are all assessed."
    "Directional improvement is not treated as adequacy."
    "Bounds failures remain explicit."
    "AS004 primary remains quantitatively inadequate."
    "14C is not run because thermal evidence is not identifiable."
    "No universal shared quantitative predictor is claimed."
    "Scientific adequacy gate fails by design; it is not a workflow failure."
    "True only for clean source before Phase 14D writes outputs."
    ];
G = table(gate, outcome, note);
end

function tf = required_b5_tables_exist(cfg)
paths = [
    string(cfg.phase14B5.fullMapResidualsFile)
    string(cfg.phase14B5.temperatureSliceResidualsFile)
    string(cfg.phase14B5.channelPerformanceFile)
    string(cfg.phase14B5.switchingCurrentLedgerFile)
    string(cfg.phase14B5.switchingWidthFeatureFile)
    string(cfg.phase14B5.predictionBoundsAuditFile)
    string(cfg.phase14B5.currentSymmetryFile)
    string(cfg.phase14B5.predictionIntervalCoverageFile)
    string(cfg.phase14B5.solverDiagnosticsFile)
    string(cfg.phase14B5.thermalTriggerAssessmentFile)
    string(cfg.phase14B5.handoffStatusFile)
    ];
tf = all(arrayfun(@(p) exist(char(p), 'file') == 2, paths));
end

function H = build_handoff_status(cfg, claim, gates, thermal, provenance)
workflowPass = all(string(gates.outcome) == "pass" | ...
    string(gates.gate) == "Shared quantitative raw nonlinear predictor");
artifactCommit = string(cfg.phase14D.frozenPhase14B5ArtifactCommit);
item = [
    "phase14D_closure"
    "phase14D_decision"
    "execution_integrity"
    "current_switching_directionally_supported"
    "shared_raw_nonlinear_predictor"
    "prediction_bounds_limitation"
    "AS004_primary_quantitative_adequacy"
    "phase14C_status"
    "phase14C_trigger_reason"
    "electrothermal_feedback"
    "source_phase14B5_artifact_commit"
    "source_pre_run_clean"
    "next_phase"
    ];
status = [
    lookup_item(claim, "phase14D_closure")
    lookup_item(claim, "phase14D_decision")
    pass_fail(workflowPass)
    lookup_item(claim, "current_switching_directionally_supported")
    "false"
    "retained"
    "fail"
    lookup_item(thermal, "phase14C_status")
    lookup_item(thermal, "phase14C_trigger_reason")
    lookup_item(thermal, "electrothermal_feedback")
    artifactCommit
    lookup_item(provenance, "source_pre_run_clean")
    string(cfg.phase14D.nextPhase)
    ];
note = [
    "Read-only assessment closes as a bounded claim freeze."
    "The selected-device NI contribution is supported, not quantitative transfer."
    "Workflow integrity permits a failing adequacy claim."
    "NI improves all retained channels."
    "Not established because bounds and AS004 primary adequacy fail."
    "Bounds failures are carried into Phase 15/claim text."
    "AS004 primary is the hard nonlinear residual failure."
    "Phase 14C remains conditional and is not executed here."
    "Frozen raw-grid metadata do not identify thermal feedback."
    "Heating is not proven absent; it is not identifiable here."
    "Canonical Phase 14B.5 artifact input."
    "True only when source was clean before writing Phase 14D artifacts."
    "Next roadmap phase."
    ];
H = table(item, status, note);
end

function value = lookup_item(T, item)
if any(strcmp(T.Properties.VariableNames, 'item'))
    key = string(T.item);
elseif any(strcmp(T.Properties.VariableNames, 'gate'))
    key = string(T.gate);
else
    value = "";
    return;
end
idx = key == string(item);
if ~any(idx)
    value = "";
    return;
end
row = find(idx, 1, 'first');
if any(strcmp(T.Properties.VariableNames, 'value'))
    value = string(T.value(row));
elseif any(strcmp(T.Properties.VariableNames, 'status'))
    value = string(T.status(row));
elseif any(strcmp(T.Properties.VariableNames, 'outcome'))
    value = string(T.outcome(row));
else
    value = "";
end
end

function value = with_default(value, fallback)
s = string(value);
if isempty(s)
    value = string(fallback);
    return;
end
s = s(1);
if ismissing(s)
    value = string(fallback);
    return;
end
if strlength(strtrim(s)) == 0
    value = string(fallback);
else
    value = s;
end
end

function out = pass_fail(tf)
if tf
    out = "pass";
else
    out = "fail";
end
end
