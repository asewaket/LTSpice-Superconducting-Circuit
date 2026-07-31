function out = run_phase13E_missing_input_model_adequacy_audit(cfg)
%RUN_PHASE13E_MISSING_INPUT_MODEL_ADEQUACY_AUDIT Audit Phase 13D failures.
%
% This phase is diagnostic and read-only. It decomposes the frozen Phase
% 13C/13D prediction failures and ranks possible missing inputs without
% reopening optimization, labels, or device-specific fitting.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
temperatureRegionResiduals = build_temperature_region_residuals(cfg, inputs);
deviceFailureDecomposition = build_device_failure_decomposition(inputs, ...
    temperatureRegionResiduals);
thresholdCrossingFailureLedger = build_threshold_crossing_failure_ledger( ...
    inputs);
probeAsymmetryFailureLedger = build_probe_asymmetry_failure_ledger(inputs);
missingInputLedger = build_missing_input_ledger();
modelLayerDiagnosis = build_model_layer_diagnosis(inputs, ...
    deviceFailureDecomposition, thresholdCrossingFailureLedger, ...
    probeAsymmetryFailureLedger);
candidateUpgradeRanking = build_candidate_upgrade_ranking( ...
    modelLayerDiagnosis, missingInputLedger);
selectedUpgradeScope = build_selected_upgrade_scope(cfg, ...
    candidateUpgradeRanking);
prohibitedFlexibilityLedger = build_prohibited_flexibility_ledger();
claimUpdate = build_claim_update(inputs, selectedUpgradeScope);
gateSummary = build_gate_summary(cfg, inputs, temperatureRegionResiduals, ...
    thresholdCrossingFailureLedger, probeAsymmetryFailureLedger, ...
    missingInputLedger, modelLayerDiagnosis, candidateUpgradeRanking, ...
    selectedUpgradeScope, prohibitedFlexibilityLedger, claimUpdate);
handoffStatus = build_handoff_status(cfg, gateSummary, claimUpdate, ...
    selectedUpgradeScope, sourceProvenance);

writetable(deviceFailureDecomposition, ...
    cfg.phase13E.deviceFailureDecompositionFile);
writetable(temperatureRegionResiduals, ...
    cfg.phase13E.temperatureRegionResidualsFile);
writetable(thresholdCrossingFailureLedger, ...
    cfg.phase13E.thresholdCrossingFailureLedgerFile);
writetable(probeAsymmetryFailureLedger, ...
    cfg.phase13E.probeAsymmetryFailureLedgerFile);
writetable(missingInputLedger, cfg.phase13E.missingInputLedgerFile);
writetable(modelLayerDiagnosis, cfg.phase13E.modelLayerDiagnosisFile);
writetable(candidateUpgradeRanking, ...
    cfg.phase13E.candidateUpgradeRankingFile);
writetable(selectedUpgradeScope, cfg.phase13E.selectedUpgradeScopeFile);
writetable(prohibitedFlexibilityLedger, ...
    cfg.phase13E.prohibitedFlexibilityLedgerFile);
writetable(claimUpdate, cfg.phase13E.claimUpdateFile);
writetable(gateSummary, cfg.phase13E.gateSummaryFile);
writetable(handoffStatus, cfg.phase13E.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13E.sourceProvenanceFile);

try
    h = v800.plot_phase13E_missing_input_audit_summary(cfg, ...
        deviceFailureDecomposition, temperatureRegionResiduals, ...
        modelLayerDiagnosis, candidateUpgradeRanking, gateSummary);
catch ME
    warning('v8:phase13EPlotFailed', ...
        'Phase 13E missing-input audit summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.deviceFailureDecomposition = deviceFailureDecomposition;
out.temperatureRegionResiduals = temperatureRegionResiduals;
out.thresholdCrossingFailureLedger = thresholdCrossingFailureLedger;
out.probeAsymmetryFailureLedger = probeAsymmetryFailureLedger;
out.missingInputLedger = missingInputLedger;
out.modelLayerDiagnosis = modelLayerDiagnosis;
out.candidateUpgradeRanking = candidateUpgradeRanking;
out.selectedUpgradeScope = selectedUpgradeScope;
out.prohibitedFlexibilityLedger = prohibitedFlexibilityLedger;
out.claimUpdate = claimUpdate;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.deviceFailureDecomposition = ...
    cfg.phase13E.deviceFailureDecompositionFile;
paths.temperatureRegionResiduals = ...
    cfg.phase13E.temperatureRegionResidualsFile;
paths.thresholdCrossingFailureLedger = ...
    cfg.phase13E.thresholdCrossingFailureLedgerFile;
paths.probeAsymmetryFailureLedger = ...
    cfg.phase13E.probeAsymmetryFailureLedgerFile;
paths.missingInputLedger = cfg.phase13E.missingInputLedgerFile;
paths.modelLayerDiagnosis = cfg.phase13E.modelLayerDiagnosisFile;
paths.candidateUpgradeRanking = cfg.phase13E.candidateUpgradeRankingFile;
paths.selectedUpgradeScope = cfg.phase13E.selectedUpgradeScopeFile;
paths.prohibitedFlexibilityLedger = ...
    cfg.phase13E.prohibitedFlexibilityLedgerFile;
paths.claimUpdate = cfg.phase13E.claimUpdateFile;
paths.gateSummary = cfg.phase13E.gateSummaryFile;
paths.handoffStatus = cfg.phase13E.handoffStatusFile;
paths.sourceProvenance = cfg.phase13E.sourceProvenanceFile;
paths.figurePng = [cfg.phase13E.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13E.figureBaseFile '.pdf'];
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
    "phase13E_missing_input_model_adequacy_audit"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "read_only_failure_audit_after_phase13D"
    "Commit Phase 13E source first; rerun from clean source; commit diagnostic artifacts separately."
    ];
note = [
    "Phase 13E missing-input/model-adequacy audit."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No optimizer rerun, retuning, relabeling, or nonlinear physics."
    "Phase 13E artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.devicePredictions = read_required_table( ...
    cfg.phase13C2.deviceRTPredictionsFile);
inputs.fullCurveResiduals = read_required_table( ...
    cfg.phase13D.fullCurveAdequacyFile);
inputs.transitionCrossingStatus = read_required_table( ...
    cfg.phase13D.transitionCrossingStatusFile);
inputs.transitionCrossingConfusion = read_required_table( ...
    cfg.phase13D.transitionCrossingConfusionFile);
inputs.pairedProbeAdequacy = read_required_table( ...
    cfg.phase13D.pairedProbeAdequacyFile);
inputs.geometryFamilyAdequacy = read_required_table( ...
    cfg.phase13D.geometryFamilyAdequacyFile);
inputs.uncertaintyCoverage = read_required_table( ...
    cfg.phase13D.uncertaintyCoverageFile);
inputs.predictiveAdequacyDecision = read_required_table( ...
    cfg.phase13D.predictiveAdequacyDecisionFile);
inputs.phase13DGateSummary = read_required_table( ...
    cfg.phase13D.gateSummaryFile);
inputs.phase13DHandoffStatus = read_required_table( ...
    cfg.phase13D.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13E input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function T = build_temperature_region_residuals(cfg, inputs)
D = inputs.devicePredictions;
mask = string(D.probe_role) == "primary";
D = D(mask, :);
devices = unique(string(D.device), 'stable');
regions = string(cfg.phase13E.temperatureRegionNames(:));
edges = double(cfg.phase13E.temperatureRegionEdges(:));
rows = repmat(struct('device', "", 'temperature_region', "", ...
    'temperature_min_K', NaN, 'temperature_max_K', NaN, ...
    'n_points', 0, 'region_mse', NaN, 'region_bias', NaN, ...
    'region_mae', NaN, 'dominance_role', ""), ...
    numel(devices) * numel(regions), 1);
idx = 0;

for d = 1:numel(devices)
    C = D(string(D.device) == devices(d), :);
    Tgrid = double(C.temperature_K);
    tMin = min(Tgrid);
    tMax = max(Tgrid);
    scaled = (Tgrid - tMin) ./ max(eps, tMax - tMin);
    err = double(C.predicted_Rtilde_median) - double(C.observed_Rtilde);
    deviceMse = nan(numel(regions), 1);
    regionIndex = cell(numel(regions), 1);
    for r = 1:numel(regions)
        if r == numel(regions)
            inRegion = scaled >= edges(r) & scaled <= edges(r + 1);
        else
            inRegion = scaled >= edges(r) & scaled < edges(r + 1);
        end
        regionIndex{r} = inRegion;
        deviceMse(r) = mean(err(inRegion).^2, 'omitnan');
    end
    [~, dominantIdx] = max(deviceMse);
    for r = 1:numel(regions)
        idx = idx + 1;
        inRegion = regionIndex{r};
        rows(idx).device = devices(d);
        rows(idx).temperature_region = regions(r);
        rows(idx).temperature_min_K = min(Tgrid(inRegion));
        rows(idx).temperature_max_K = max(Tgrid(inRegion));
        rows(idx).n_points = sum(inRegion);
        rows(idx).region_mse = deviceMse(r);
        rows(idx).region_bias = mean(err(inRegion), 'omitnan');
        rows(idx).region_mae = mean(abs(err(inRegion)), 'omitnan');
        if r == dominantIdx
            rows(idx).dominance_role = "dominant_failure_region";
        else
            rows(idx).dominance_role = "secondary_region";
        end
    end
end
T = struct2table(rows);
end

function T = build_device_failure_decomposition(inputs, regionResiduals)
F = inputs.fullCurveResiduals;
devices = string(F.device);
dominant_region = strings(height(F), 1);
dominant_region_mse = nan(height(F), 1);
failure_type = strings(height(F), 1);
most_plausible_implication = strings(height(F), 1);
note = strings(height(F), 1);

for k = 1:height(F)
    R = regionResiduals(string(regionResiduals.device) == devices(k), :);
    [dominant_region_mse(k), idx] = max(double(R.region_mse));
    dominant_region(k) = string(R.temperature_region(idx));
    switch dominant_region(k)
        case "normal"
            failure_type(k) = "baseline_or_normal_state_mismatch";
            most_plausible_implication(k) = ...
                "normal_state_heterogeneity_or_baseline_law";
        case "onset"
            failure_type(k) = "onset_temperature_mismatch";
            most_plausible_implication(k) = ...
                "Tc_mapping_or_mechanical_amplitude";
        case "transition"
            failure_type(k) = "transition_shape_width_mismatch";
            most_plausible_implication(k) = ...
                "spatial_disorder_or_connectivity_distribution";
        otherwise
            failure_type(k) = "low_temperature_plateau_mismatch";
            most_plausible_implication(k) = ...
                "residual_shunt_or_incomplete_connectivity";
    end
    if string(F.adequacy_status(k)) == "partial_predictive_signal"
        note(k) = "Partial signal exists, but dominant residual still limits quantitative transfer.";
    elseif string(F.adequacy_status(k)) == "directional_only"
        note(k) = "Directional behavior exists without quantitative adequacy.";
    else
        note(k) = "Failure pattern is too large for shared quantitative R(T) prediction.";
    end
end

T = table(devices, string(F.residual_value), string(F.adequacy_status), ...
    dominant_region, dominant_region_mse, failure_type, ...
    most_plausible_implication, note, 'VariableNames', ...
    {'device','full_curve_residual','phase13D_adequacy_status', ...
    'dominant_region','dominant_region_mse','failure_type', ...
    'most_plausible_implication','note'});
end

function T = build_threshold_crossing_failure_ledger(inputs)
C = inputs.transitionCrossingStatus;
failureMask = string(C.T_comparison_status) ~= "both_cross" & ...
    string(C.T_comparison_status) ~= "neither_crosses";
T = C(failureMask, :);
if isempty(T)
    T = C(1:0, :);
end
end

function T = build_probe_asymmetry_failure_ledger(inputs)
P = inputs.pairedProbeAdequacy;
failureMask = string(P.probe_transfer_status) ~= ...
    "paired_probe_transfer_supported";
T = P(failureMask, :);
if isempty(T)
    T = P(1:0, :);
end
end

function T = build_missing_input_ledger()
candidate_missing_input = [
    "absolute_mechanical_amplitude"
    "interface_load_transfer"
    "device_thickness"
    "interface_transparency"
    "spatially_correlated_disorder"
    "residual_shunt_distribution"
    "normal_state_heterogeneity"
    "contact_probe_geometry_uncertainty"
    "crack_morphology"
    "nonmonotonic_constitutive_response"
    ];
why_it_may_matter = [
    "Phase 12B fields are normalized proxies, not calibrated strain."
    "Nominal coverage may not equal stress transmitted into MoTe2."
    "Thickness can affect strain transfer, normal resistance, and superconducting response."
    "Weak-link transparency may vary independently of geometric boundaries."
    "Current disorder law may not reproduce transition breadth."
    "A single shared shunt law may miss persistent low-temperature resistance."
    "Normal-state variation can distort normalized curve shape and asymmetry."
    "Four-probe response depends on current-injection and voltage-probe geometry."
    "AS005 crack proxy may be too simplified despite partial success."
    "Mechanical amplitude may not map monotonically to superconducting enhancement."
    ];
input_status = [
    "unmeasured"
    "potentially_recoverable"
    "measured_but_not_ingested"
    "unmeasured"
    "phenomenological_missing_physics"
    "phenomenological_missing_physics"
    "potentially_recoverable"
    "potentially_recoverable"
    "potentially_recoverable"
    "not_identifiable_from_current_data"
    ];
identifiability_risk = [
    "high"
    "medium"
    "medium"
    "high"
    "medium"
    "medium"
    "medium"
    "medium"
    "medium"
    "high"
    ];
T = table(candidate_missing_input, why_it_may_matter, input_status, ...
    identifiability_risk);
end

function T = build_model_layer_diagnosis(inputs, deviceFailures, ...
    thresholdLedger, probeLedger)
poorDevices = sum(string(deviceFailures.phase13D_adequacy_status) == ...
    "poor_quantitative_transfer");
failureTypes = string(deviceFailures.failure_type);
normalOrLowT = sum(contains(failureTypes, "baseline") | ...
    contains(failureTypes, "low_temperature"));
thresholdFailures = height(thresholdLedger);
probeFailures = height(probeLedger);

layer = [
    "mechanical_proxy_insufficiency"
    "constitutive_law_insufficiency"
    "electrical_network_insufficiency"
    ];
support_level = [
    conditional(poorDevices >= 4, "moderate", "low")
    conditional(thresholdFailures >= 6, "high", "moderate")
    conditional(probeFailures > 0 || normalOrLowT >= 3, "high", "moderate")
    ];
evidence = [
    "Several devices with different geometry classes remain weakly predicted."
    "Most transition thresholds are censored or fail to cross as observed."
    "Low-temperature/baseline failures and paired-probe limitations remain after shared mapping."
    ];
phase13E_interpretation = [
    "Normalized mechanical proxies are informative but not quantitatively sufficient."
    "The mapping from proxy fields to Tc/connectivity is too simple for full curves."
    "Scalar normalized R(T) network lacks enough baseline/shunt/probe-transfer structure."
    ];
T = table(layer, support_level, evidence, phase13E_interpretation);
end

function T = build_candidate_upgrade_ranking(layerDiagnosis, missingInputLedger)
upgrade = [
    "baseline_and_residual_shunt_upgrade"
    "interface_transfer_or_transparency_input"
    "spatial_disorder_correlation_upgrade"
    "mechanical_amplitude_calibration"
    "phase_or_electrothermal_dynamics"
    ];
physical_justification = [5; 4; 4; 3; 2];
multi_device_relevance = [5; 4; 3; 3; 2];
independent_input_availability = [4; 3; 2; 1; 1];
identifiability = [4; 3; 3; 2; 1];
overfit_risk_inverse = [4; 3; 3; 2; 1];
future_compatibility = [5; 4; 4; 3; 2];
score = physical_justification + multi_device_relevance + ...
    independent_input_availability + identifiability + ...
    overfit_risk_inverse + future_compatibility;
[score, order] = sort(score, 'descend');
upgrade = upgrade(order);
physical_justification = physical_justification(order);
multi_device_relevance = multi_device_relevance(order);
independent_input_availability = independent_input_availability(order);
identifiability = identifiability(order);
overfit_risk_inverse = overfit_risk_inverse(order);
future_compatibility = future_compatibility(order);
ranking = (1:numel(upgrade)).';
decision_role = repmat("candidate", numel(upgrade), 1);
decision_role(ranking <= 2) = "selected_for_bounded_future_test";
note = strings(numel(upgrade), 1);
for k = 1:numel(upgrade)
    note(k) = upgrade_note(upgrade(k), layerDiagnosis, missingInputLedger);
end
T = table(ranking, upgrade, score, physical_justification, ...
    multi_device_relevance, independent_input_availability, ...
    identifiability, overfit_risk_inverse, future_compatibility, ...
    decision_role, note);
end

function note = upgrade_note(upgrade, ~, ~)
switch string(upgrade)
    case "baseline_and_residual_shunt_upgrade"
        note = "Prioritize because AS001/control and low-temperature coverage expose baseline/shunt limitations.";
    case "interface_transfer_or_transparency_input"
        note = "Useful if fabrication or geometry metadata can constrain load transfer or transparency independently.";
    case "spatial_disorder_correlation_upgrade"
        note = "Potentially relevant to transition breadth but should remain shared and low-dimensional.";
    case "mechanical_amplitude_calibration"
        note = "Defer unless independent amplitude constraints become available.";
    otherwise
        note = "Defer until R(T) baseline scope is frozen; do not mask scalar-network limitations with new physics.";
end
end

function T = build_selected_upgrade_scope(cfg, ranking)
selected = ranking(string(ranking.decision_role) == ...
    "selected_for_bounded_future_test", :);
if height(selected) > cfg.phase13E.maxSelectedUpgradeCount
    selected = selected(1:cfg.phase13E.maxSelectedUpgradeCount, :);
end
upgrade = string(selected.upgrade);
scope_status = repmat("selected_bounded_scope", height(selected), 1);
allowed_test = strings(height(selected), 1);
prohibited_use = strings(height(selected), 1);
for k = 1:height(selected)
    switch upgrade(k)
        case "baseline_and_residual_shunt_upgrade"
            allowed_test(k) = "shared baseline/residual-conduction parameterization";
            prohibited_use(k) = "device-specific shunt fitting";
        otherwise
            allowed_test(k) = "shared interface/load-transfer or transparency input";
            prohibited_use(k) = "free per-device transparency labels";
    end
end
T = table(upgrade, scope_status, allowed_test, prohibited_use);
end

function T = build_prohibited_flexibility_ledger()
prohibited_flexibility = [
    "device_specific_mechanism_parameters"
    "transport_relabeling"
    "optimizer_rerun_inside_phase13E"
    "new_phase_dynamics"
    "unconstrained_Raman_to_transport_target"
    "per_device_threshold_tuning"
    ];
reason = [
    "Would erase leave-one-device-out predictive meaning."
    "Would reopen frozen Phase 6/13 labels."
    "Phase 13E is an audit, not a calibration phase."
    "Belongs only after bounded R(T) adequacy decisions."
    "Raman registration remains insufficient for direct target fitting."
    "Would turn the adequacy decision into post-hoc classification."
    ];
status = repmat("blocked_in_phase13E", numel(prohibited_flexibility), 1);
T = table(prohibited_flexibility, status, reason);
end

function T = build_claim_update(inputs, selectedUpgradeScope)
phase13DDecision = lookup_value(inputs.predictiveAdequacyDecision, ...
    "phase13D_decision");
field = [
    "phase13D_decision_consumed"
    "shared_quantitative_RT_predictor"
    "permitted_claim"
    "phase13E_decision"
    "selected_upgrade_count"
    ];
value = [
    phase13DDecision
    lookup_value(inputs.predictiveAdequacyDecision, ...
        "shared_quantitative_RT_predictive_model")
    "limited_device_level_predictive_information_AS005_partial_AS004_directional"
    "baseline_and_shunt_upgrade_plus_interface_transfer_audit_justified"
    string(height(selectedUpgradeScope))
    ];
note = [
    "Phase 13E consumes the frozen Phase 13D adequacy decision."
    "False means no universal quantitative six-device R(T) predictor."
    "Claim remains contextual and bounded by Phase 13D limitations."
    "No upgrade is implemented here; this is a scope selection."
    "Phase 13E selects at most two bounded future upgrades."
    ];
T = table(field, value, note);
end

function T = build_gate_summary(cfg, inputs, regionResiduals, thresholdLedger, ...
    probeLedger, missingInputLedger, modelLayerDiagnosis, ranking, ...
    selectedScope, prohibitedFlexibility, claimUpdate)
phase13DConsumed = any(string(inputs.phase13DHandoffStatus.field) == ...
    "phase13D_closure");
noRetuning = ~cfg.phase13E.allowOptimizerRerun && ...
    ~cfg.phase13E.allowConstitutiveRetuning && ...
    ~cfg.phase13E.allowDeviceSpecificFitting && ...
    ~cfg.phase13E.allowTransportRelabeling;
component = [
    "Phase 13D outputs consumed unchanged"
    "No optimizer rerun"
    "Residuals decomposed by temperature region"
    "Threshold non-crossings treated explicitly"
    "Probe failures assessed separately"
    "Missing inputs distinguished from missing physics"
    "Model layer diagnosis written"
    "Candidate upgrades ranked"
    "Selected upgrades bounded to one or two"
    "Prohibited flexibility ledger written"
    "Claim update frozen"
    ];
outcome = [
    passfail(phase13DConsumed)
    passfail(noRetuning)
    passfail(~isempty(regionResiduals))
    passfail(~isempty(thresholdLedger) || ...
        any(string(inputs.transitionCrossingStatus.T_comparison_status) == ...
        "neither_crosses"))
    passfail(~isempty(probeLedger))
    passfail(~isempty(missingInputLedger))
    passfail(~isempty(modelLayerDiagnosis))
    passfail(~isempty(ranking))
    passfail(height(selectedScope) >= 1 && ...
        height(selectedScope) <= cfg.phase13E.maxSelectedUpgradeCount)
    passfail(~isempty(prohibitedFlexibility))
    passfail(~isempty(claimUpdate))
    ];
note = [
    "Frozen Phase 13D adequacy decision is the starting point."
    "Phase 13E remains diagnostic/read-only."
    "Primary held-out residuals are split into lowT/transition/onset/normal regions."
    "Missing T90/T50/T10 numerical errors remain explicit categorical outcomes."
    "Paired-probe limitations are not folded into scalar residuals."
    "The missing-input ledger separates data gaps from missing physics."
    "Mechanical, constitutive, and electrical-network layers are assessed separately."
    "Upgrades are ranked by physical justification, data availability, identifiability, and overfit risk."
    "No broad model expansion is allowed."
    "Known overfitting routes are blocked."
    "The claim remains partial and bounded."
    ];
T = table(component, outcome, note);
end

function T = build_handoff_status(cfg, gateSummary, claimUpdate, ...
    selectedScope, sourceProvenance)
phasePass = all(string(gateSummary.outcome) == "pass");
field = [
    "phase13E_closure"
    "phase13E_decision"
    "selected_upgrades"
    "source_commit_sha"
    "next_phase"
    ];
value = [
    conditional(phasePass, "pass_missing_input_model_adequacy_audit", ...
        "fail_audit_incomplete")
    lookup_value(claimUpdate, "phase13E_decision")
    strjoin(string(selectedScope.upgrade), "|")
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase13E.nextPhase
    ];
note = [
    "Closure means diagnostic audit completeness, not a new predictor pass."
    "Frozen Phase 13E scope decision."
    "At most two bounded future upgrade candidates."
    "Source commit captured before output generation."
    "Recommended next phase remains bounded."
    ];
T = table(field, value, note);
end

function out = lookup_value(T, key)
if any(strcmp(T.Properties.VariableNames, 'field'))
    mask = string(T.field) == string(key);
elseif any(strcmp(T.Properties.VariableNames, 'item'))
    mask = string(T.item) == string(key);
else
    mask = false(height(T), 1);
end
if any(mask)
    out = string(T.value(find(mask, 1)));
else
    out = "";
end
end

function s = passfail(tf)
if tf
    s = "pass";
else
    s = "fail";
end
end

function s = conditional(tf, a, b)
if tf
    s = string(a);
else
    s = string(b);
end
end
