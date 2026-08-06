function out = run_phase15E_field_model_adequacy_decision(cfg)
%RUN_PHASE15E_FIELD_MODEL_ADEQUACY_DECISION Freeze AS006 field claims.
%
% Phase 15E is deliberately read-only. It consumes the canonical Phase 15D
% AS006 P0/PB/Pphi execution artifacts and decides the strongest defensible
% field-model claim without rerunning the solver, retuning any parameter,
% fitting a period, changing holdouts, clipping bounds, or adding new physics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
executionValidity = build_execution_validity_summary(cfg, inputs);
variantResiduals = build_variant_residual_comparison(inputs);
currentRegion = build_current_region_assessment(inputs);
criticalEnvelope = build_critical_current_envelope_assessment(inputs);
oscillationMorphology = build_oscillation_morphology_assessment(cfg, inputs);
turningPoints = build_turning_point_comparison(inputs);
predictionBounds = build_prediction_bounds_assessment(inputs);
channelTransfer = build_channel_transfer_summary(inputs, variantResiduals, ...
    currentRegion, predictionBounds, oscillationMorphology);
complexityLedger = build_complexity_identifiability_ledger(cfg, ...
    variantResiduals, oscillationMorphology, predictionBounds);
mechanismClaims = build_mechanism_claim_ledger(inputs, variantResiduals, ...
    currentRegion, criticalEnvelope, oscillationMorphology, ...
    predictionBounds, complexityLedger);
preferredVariant = build_preferred_variant_decision(variantResiduals, ...
    complexityLedger);
claimDecision = build_claim_decision(preferredVariant, mechanismClaims);
gateSummary = build_gate_summary(cfg, executionValidity, variantResiduals, ...
    currentRegion, criticalEnvelope, oscillationMorphology, ...
    predictionBounds, complexityLedger, mechanismClaims, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, claimDecision, gateSummary, ...
    sourceProvenance);

writetable(executionValidity, cfg.phase15E.executionValiditySummaryFile);
writetable(variantResiduals, cfg.phase15E.variantResidualComparisonFile);
writetable(currentRegion, cfg.phase15E.currentRegionAssessmentFile);
writetable(criticalEnvelope, ...
    cfg.phase15E.criticalCurrentEnvelopeAssessmentFile);
writetable(oscillationMorphology, ...
    cfg.phase15E.oscillationMorphologyAssessmentFile);
writetable(turningPoints, cfg.phase15E.turningPointComparisonFile);
writetable(predictionBounds, cfg.phase15E.predictionBoundsAssessmentFile);
writetable(channelTransfer, cfg.phase15E.channelTransferSummaryFile);
writetable(complexityLedger, ...
    cfg.phase15E.complexityIdentifiabilityLedgerFile);
writetable(mechanismClaims, cfg.phase15E.mechanismClaimLedgerFile);
writetable(preferredVariant, cfg.phase15E.preferredVariantDecisionFile);
writetable(claimDecision, cfg.phase15E.claimDecisionFile);
writetable(gateSummary, cfg.phase15E.gateSummaryFile);
writetable(handoffStatus, cfg.phase15E.handoffStatusFile);
writetable(sourceProvenance, cfg.phase15E.sourceProvenanceFile);

try
    h = v800.plot_phase15E_field_model_adequacy_decision_summary( ...
        cfg, variantResiduals, currentRegion, criticalEnvelope, ...
        oscillationMorphology, predictionBounds, preferredVariant, ...
        gateSummary);
catch ME
    warning('v8:phase15EPlotFailed', ...
        'Phase 15E summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.executionValidity = executionValidity;
out.variantResidualComparison = variantResiduals;
out.currentRegionAssessment = currentRegion;
out.criticalCurrentEnvelopeAssessment = criticalEnvelope;
out.oscillationMorphologyAssessment = oscillationMorphology;
out.turningPointComparison = turningPoints;
out.predictionBoundsAssessment = predictionBounds;
out.channelTransferSummary = channelTransfer;
out.complexityIdentifiabilityLedger = complexityLedger;
out.mechanismClaimLedger = mechanismClaims;
out.preferredVariantDecision = preferredVariant;
out.claimDecision = claimDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionValidity = cfg.phase15E.executionValiditySummaryFile;
paths.variantResidualComparison = cfg.phase15E.variantResidualComparisonFile;
paths.currentRegionAssessment = cfg.phase15E.currentRegionAssessmentFile;
paths.criticalCurrentEnvelopeAssessment = ...
    cfg.phase15E.criticalCurrentEnvelopeAssessmentFile;
paths.oscillationMorphologyAssessment = ...
    cfg.phase15E.oscillationMorphologyAssessmentFile;
paths.turningPointComparison = cfg.phase15E.turningPointComparisonFile;
paths.predictionBoundsAssessment = ...
    cfg.phase15E.predictionBoundsAssessmentFile;
paths.channelTransferSummary = cfg.phase15E.channelTransferSummaryFile;
paths.complexityIdentifiabilityLedger = ...
    cfg.phase15E.complexityIdentifiabilityLedgerFile;
paths.mechanismClaimLedger = cfg.phase15E.mechanismClaimLedgerFile;
paths.preferredVariantDecision = cfg.phase15E.preferredVariantDecisionFile;
paths.claimDecision = cfg.phase15E.claimDecisionFile;
paths.gateSummary = cfg.phase15E.gateSummaryFile;
paths.handoffStatus = cfg.phase15E.handoffStatusFile;
paths.sourceProvenance = cfg.phase15E.sourceProvenanceFile;
paths.figurePng = [cfg.phase15E.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase15E.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
artifactCommit = string(cfg.phase15E.frozenPhase15DArtifactCommit);
artifactReachable = git_commit_is_ancestor(cfg.repoRoot, artifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase15D_artifact_commit"
    "frozen_phase15D_artifact_commit_reachable"
    "provenance_scope"
    "source_provenance_policy"
    ];
value = [
    "phase15E_field_model_adequacy_decision"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    artifactCommit
    string(artifactReachable)
    "read_only_AS006_field_adequacy_after_clean_phase15D"
    "Commit Phase 15E source first; rerun from clean source; commit decision artifacts separately."
    ];
note = [
    "Phase 15E read-only AS006 field-model adequacy decision."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 15D artifact-freeze commit consumed by policy."
    "True when the frozen Phase 15D artifact commit is an ancestor of this run."
    "No solver rerun, parameter retuning, period fitting, topology, thermal memory, or R1/R2 split loop."
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
inputs.d15Manifest = read_required_table( ...
    cfg.phase15D.executionManifestFile);
inputs.d15Residuals = read_required_table( ...
    cfg.phase15D.variantResidualsFile);
inputs.d15Heldout = read_required_table( ...
    cfg.phase15D.heldoutFieldWindowFile);
inputs.d15CurrentRegion = read_required_table( ...
    cfg.phase15D.currentRangeTransferFile);
inputs.d15FieldSymmetry = read_required_table( ...
    cfg.phase15D.fieldSymmetryFile);
inputs.d15CriticalEnvelope = read_required_table( ...
    cfg.phase15D.criticalCurrentEnvelopeFile);
inputs.d15Oscillation = read_required_table( ...
    cfg.phase15D.oscillatoryStructureFile);
inputs.d15ZeroField = read_required_table( ...
    cfg.phase15D.zeroFieldInheritanceFile);
inputs.d15Bounds = read_required_table( ...
    cfg.phase15D.predictionBoundsAuditFile);
inputs.d15SharedState = read_required_table( ...
    cfg.phase15D.sharedPhaseStateFile);
inputs.d15ChannelTransform = read_required_table( ...
    cfg.phase15D.channelTransformAuditFile);
inputs.d15GateSummary = read_required_table(cfg.phase15D.gateSummaryFile);
inputs.d15Handoff = read_required_table(cfg.phase15D.handoffStatusFile);
inputs.d15SourceProvenance = read_required_table( ...
    cfg.phase15D.sourceProvenanceFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 15E input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function validity = build_execution_validity_summary(cfg, inputs)
closure = lookup_item(inputs.d15Handoff, "phase15D_closure");
integrity = lookup_item(inputs.d15Handoff, "execution_integrity");
allD15GatesPass = all(string(inputs.d15GateSummary.outcome) == "pass");
sourceClean = lookup_item(inputs.d15SourceProvenance, ...
    "source_pre_run_clean") == "true";
rawUsed = lookup_item(inputs.d15Handoff, "raw_AS006_residuals_used") == ...
    "true";
sharedState = lookup_item(inputs.d15Handoff, "shared_phase_state") == ...
    "true";
noPeriodFit = lookup_item(inputs.d15Handoff, "manual_period_fit") == ...
    "false";
noTopology = lookup_item(inputs.d15Handoff, "topological_term_used") == ...
    "false";
noThermal = lookup_item(inputs.d15Handoff, "thermal_memory_used") == ...
    "false";
noSplitLoop = lookup_item(inputs.d15Handoff, ...
    "independent_R1_R2_loop_parameters") == "false";

item = [
    "phase15D_closure_consumed"
    "phase15D_execution_integrity"
    "phase15D_all_gates_passed"
    "phase15D_clean_provenance"
    "raw_AS006_residuals_used"
    "no_solver_rerun"
    "no_parameter_retuning"
    "no_period_fit"
    "no_topology_term"
    "no_vortex_term"
    "no_thermal_memory"
    "no_magnetic_screening"
    "shared_R1_R2_phase_state"
    "no_independent_R1_R2_phase_parameters"
    ];
status = [
    pass_fail(closure == cfg.phase15E.expectedPhase15DClosure)
    pass_fail(integrity == cfg.phase15E.expectedPhase15DIntegrity)
    pass_fail(allD15GatesPass)
    pass_fail(sourceClean)
    pass_fail(rawUsed)
    pass_fail(~cfg.phase15E.allowSolverRerun)
    pass_fail(~cfg.phase15E.allowParameterRetuning)
    pass_fail(noPeriodFit && ~cfg.phase15E.allowPeriodFit)
    pass_fail(noTopology && ~cfg.phase15E.allowTopologyTerm)
    pass_fail(~cfg.phase15E.allowVortexTerm)
    pass_fail(noThermal && ~cfg.phase15E.allowThermalMemory)
    pass_fail(~cfg.phase15E.allowMagneticScreening)
    pass_fail(sharedState)
    pass_fail(noSplitLoop && ...
    ~cfg.phase15E.allowIndependentR1R2PhaseParameters)
    ];
value = [
    closure
    integrity
    string(allD15GatesPass)
    string(sourceClean)
    string(rawUsed)
    string(~cfg.phase15E.allowSolverRerun)
    string(~cfg.phase15E.allowParameterRetuning)
    string(noPeriodFit && ~cfg.phase15E.allowPeriodFit)
    string(noTopology && ~cfg.phase15E.allowTopologyTerm)
    string(~cfg.phase15E.allowVortexTerm)
    string(noThermal && ~cfg.phase15E.allowThermalMemory)
    string(~cfg.phase15E.allowMagneticScreening)
    string(sharedState)
    string(noSplitLoop && ...
    ~cfg.phase15E.allowIndependentR1R2PhaseParameters)
    ];
note = [
    "Canonical Phase 15D execution closure is required."
    "Phase 15D execution integrity must pass."
    "Phase 15D execution gates must all pass."
    "Phase 15D artifacts must come from a clean provenance run."
    "Phase 15E consumes the raw AS006 residuals emitted by Phase 15D."
    "Phase 15E is read-only and does not rerun the solver."
    "Phase 15E does not retune parameters."
    "Observed oscillation period is not fit."
    "No topological superconductivity term or claim is introduced."
    "No vortex mechanism is introduced."
    "No electrothermal memory or hysteresis model is introduced."
    "No magnetic screening term is introduced."
    "R1/R2 are assessed from one shared phase state."
    "Independent channel phase parameters remain prohibited."
    ];
validity = table(item, status, value, note);
end

function T = build_variant_residual_comparison(inputs)
R = inputs.d15Residuals;
rows = strings(0, 1);
variant = strings(0, 1);
channel = strings(0, 1);
MSE = zeros(0, 1);
corrValue = zeros(0, 1);
delta_vs_P0 = zeros(0, 1);
fractional_gain_vs_P0 = zeros(0, 1);
delta_Pphi_vs_PB = zeros(0, 1);
incremental_interpretation = strings(0, 1);
for c = reshape(unique(string(R.channel), 'stable'), 1, [])
    p0 = row_value(R, "P0", c, "mean_squared_residual");
    pb = row_value(R, "PB", c, "mean_squared_residual");
    pp = row_value(R, "Pphi", c, "mean_squared_residual");
    dPhi = pb - pp;
    fracPhi = safe_divide(dPhi, pb);
    for v = ["P0", "PB", "Pphi"]
        mse = row_value(R, v, c, "mean_squared_residual");
        rows(end+1, 1) = v + "_" + c; %#ok<AGROW>
        variant(end+1, 1) = v; %#ok<AGROW>
        channel(end+1, 1) = c; %#ok<AGROW>
        MSE(end+1, 1) = mse; %#ok<AGROW>
        corrValue(end+1, 1) = row_value(R, v, c, "map_correlation"); %#ok<AGROW>
        delta_vs_P0(end+1, 1) = p0 - mse; %#ok<AGROW>
        fractional_gain_vs_P0(end+1, 1) = safe_divide(p0 - mse, p0); %#ok<AGROW>
        if v == "Pphi"
            delta_Pphi_vs_PB(end+1, 1) = dPhi; %#ok<AGROW>
            if fracPhi > 0 && fracPhi < 0.03
                interp = "small_incremental_gain_over_PB";
            elseif fracPhi >= 0.03
                interp = "material_incremental_gain_over_PB";
            else
                interp = "no_incremental_gain_over_PB";
            end
        else
            delta_Pphi_vs_PB(end+1, 1) = NaN; %#ok<AGROW>
            interp = "not_Pphi_increment";
        end
        incremental_interpretation(end+1, 1) = interp; %#ok<AGROW>
    end
end
T = table(rows, variant, channel, MSE, corrValue, delta_vs_P0, ...
    fractional_gain_vs_P0, delta_Pphi_vs_PB, ...
    incremental_interpretation, 'VariableNames', {'case_id', 'variant', ...
    'channel', 'mean_squared_residual', 'map_correlation', ...
    'MSE_gain_vs_P0', 'fractional_MSE_gain_vs_P0', ...
    'Pphi_MSE_gain_vs_PB', 'incremental_interpretation'});
end

function T = build_current_region_assessment(inputs)
C = inputs.d15CurrentRegion;
rows = repmat(empty_region_row(), height(C), 1);
for k = 1:height(C)
    variant = string(C.variant(k));
    channel = string(C.channel(k));
    p0Mask = string(C.variant) == "P0" & string(C.channel) == channel;
    p0Low = C.low_current_mse(find(p0Mask, 1));
    p0High = C.high_current_mse(find(p0Mask, 1));
    rows(k).variant = variant;
    rows(k).channel = channel;
    rows(k).low_current_mse = C.low_current_mse(k);
    rows(k).high_current_mse = C.high_current_mse(k);
    rows(k).low_current_gain_vs_P0 = p0Low - C.low_current_mse(k);
    rows(k).high_current_gain_vs_P0 = p0High - C.high_current_mse(k);
    rows(k).low_current_fractional_gain = ...
        safe_divide(rows(k).low_current_gain_vs_P0, p0Low);
    rows(k).high_current_fractional_gain = ...
        safe_divide(rows(k).high_current_gain_vs_P0, p0High);
    if variant == "PB" || variant == "Pphi"
        if rows(k).low_current_gain_vs_P0 > 0 && ...
                rows(k).high_current_gain_vs_P0 <= 0
            txt = "low_current_improved_high_current_weak";
        elseif rows(k).low_current_gain_vs_P0 > 0 && ...
                rows(k).high_current_gain_vs_P0 > 0
            txt = "low_and_high_current_improved";
        else
            txt = "no_current_region_transfer_gain";
        end
    else
        txt = "baseline";
    end
    rows(k).region_interpretation = txt;
end
T = struct2table(rows);
end

function row = empty_region_row()
row = struct('variant', "", 'channel', "", 'low_current_mse', NaN, ...
    'high_current_mse', NaN, 'low_current_gain_vs_P0', NaN, ...
    'high_current_gain_vs_P0', NaN, 'low_current_fractional_gain', NaN, ...
    'high_current_fractional_gain', NaN, 'region_interpretation', "");
end

function T = build_critical_current_envelope_assessment(inputs)
E = inputs.d15CriticalEnvelope;
rows = repmat(empty_envelope_row(), height(E), 1);
for k = 1:height(E)
    variant = string(E.variant(k));
    channel = string(E.channel(k));
    p0Mask = string(E.variant) == "P0" & string(E.channel) == channel;
    p0Error = E.mean_abs_Ic_error_A(find(p0Mask, 1));
    rows(k).variant = variant;
    rows(k).channel = channel;
    rows(k).mean_abs_Ic_error_A = E.mean_abs_Ic_error_A(k);
    rows(k).Ic_envelope_correlation = E.Ic_envelope_correlation(k);
    rows(k).Ic_error_reduction_vs_P0_A = p0Error - E.mean_abs_Ic_error_A(k);
    rows(k).Ic_error_fractional_reduction_vs_P0 = ...
        safe_divide(rows(k).Ic_error_reduction_vs_P0_A, p0Error);
    if variant == "PB" || variant == "Pphi"
        rows(k).envelope_interpretation = ...
            "field_dependent_envelope_substantially_improved";
    else
        rows(k).envelope_interpretation = "zero_field_current_baseline";
    end
end
T = struct2table(rows);
end

function row = empty_envelope_row()
row = struct('variant', "", 'channel', "", ...
    'mean_abs_Ic_error_A', NaN, 'Ic_envelope_correlation', NaN, ...
    'Ic_error_reduction_vs_P0_A', NaN, ...
    'Ic_error_fractional_reduction_vs_P0', NaN, ...
    'envelope_interpretation', "");
end

function T = build_oscillation_morphology_assessment(cfg, inputs)
O = inputs.d15Oscillation;
channels = unique(string(O.channel), 'stable');
rows = repmat(empty_oscillation_row(), numel(channels) * 3, 1);
idx = 0;
for c = reshape(channels, 1, [])
    obsMask = string(O.source) == "observed" & string(O.channel) == c;
    observedPeaks = O.peak_count(find(obsMask, 1));
    observedTroughs = O.trough_count(find(obsMask, 1));
    observedTurning = observedPeaks + observedTroughs;
    for v = ["P0", "PB", "Pphi"]
        idx = idx + 1;
        modelMask = string(O.source) == v & string(O.channel) == c;
        modelPeaks = O.peak_count(find(modelMask, 1));
        modelTroughs = O.trough_count(find(modelMask, 1));
        modelTurning = modelPeaks + modelTroughs;
        excess = modelTurning - observedTurning;
        rows(idx).variant = v;
        rows(idx).channel = c;
        rows(idx).observed_turning_points = observedTurning;
        rows(idx).model_turning_points = modelTurning;
        rows(idx).turning_point_excess = excess;
        rows(idx).observed_oscillation_score = ...
            O.oscillation_score(find(obsMask, 1));
        rows(idx).model_oscillation_score = ...
            O.oscillation_score(find(modelMask, 1));
        if v == "Pphi" && excess >= ...
                cfg.phase15E.largeTurningPointOverproductionThreshold
            interp = "overproduced_oscillation_morphology";
        elseif v == "PB" && modelTurning == 0
            interp = "nonoscillatory_field_suppression";
        elseif v == "P0"
            interp = "zero_field_current_baseline_no_field_oscillation";
        else
            interp = "oscillation_morphology_not_hard_failure";
        end
        rows(idx).morphology_interpretation = interp;
    end
end
T = struct2table(rows);
end

function row = empty_oscillation_row()
row = struct('variant', "", 'channel', "", ...
    'observed_turning_points', NaN, 'model_turning_points', NaN, ...
    'turning_point_excess', NaN, 'observed_oscillation_score', NaN, ...
    'model_oscillation_score', NaN, 'morphology_interpretation', "");
end

function T = build_turning_point_comparison(inputs)
O = inputs.d15Oscillation;
source = string(O.source);
channel = string(O.channel);
peak_count = O.peak_count;
trough_count = O.trough_count;
turning_point_count = peak_count + trough_count;
manual_period_fit = O.manual_period_fit;
oscillation_score = O.oscillation_score;
T = table(source, channel, peak_count, trough_count, turning_point_count, ...
    oscillation_score, manual_period_fit);
end

function T = build_prediction_bounds_assessment(inputs)
B = inputs.d15Bounds;
bounds_interpretation = strings(height(B), 1);
for k = 1:height(B)
    if string(B.bounds_status(k)) == "widespread_violation"
        bounds_interpretation(k) = "widespread_prediction_bound_violation_retained";
    elseif string(B.bounds_status(k)) == "localized_violation"
        bounds_interpretation(k) = "localized_prediction_bound_violation_retained";
    else
        bounds_interpretation(k) = "bounded";
    end
end
T = table(string(B.variant), string(B.channel), B.normalized_half_width, ...
    B.fraction_outside_bounds, string(B.bounds_status), ...
    bounds_interpretation, 'VariableNames', {'variant', 'channel', ...
    'normalized_half_width', 'fraction_outside_bounds', ...
    'bounds_status', 'bounds_interpretation'});
end

function T = build_channel_transfer_summary(inputs, residuals, currentRegion, ...
    bounds, oscillation)
channels = unique(string(inputs.d15Residuals.channel), 'stable');
rows = repmat(empty_channel_row(), numel(channels), 1);
for k = 1:numel(channels)
    c = channels(k);
    p0 = residuals.mean_squared_residual( ...
        string(residuals.variant) == "P0" & string(residuals.channel) == c);
    pb = residuals.mean_squared_residual( ...
        string(residuals.variant) == "PB" & string(residuals.channel) == c);
    pp = residuals.mean_squared_residual( ...
        string(residuals.variant) == "Pphi" & string(residuals.channel) == c);
    pphiLow = currentRegion.low_current_fractional_gain( ...
        string(currentRegion.variant) == "Pphi" & ...
        string(currentRegion.channel) == c);
    pphiHigh = currentRegion.high_current_fractional_gain( ...
        string(currentRegion.variant) == "Pphi" & ...
        string(currentRegion.channel) == c);
    pphiBounds = bounds.fraction_outside_bounds( ...
        string(bounds.variant) == "Pphi" & string(bounds.channel) == c);
    pphiMorph = oscillation.morphology_interpretation( ...
        string(oscillation.variant) == "Pphi" & ...
        string(oscillation.channel) == c);
    rows(k).channel = c;
    rows(k).PB_improves_over_P0 = pb < p0;
    rows(k).Pphi_improves_over_P0 = pp < p0;
    rows(k).Pphi_improves_over_PB = pp < pb;
    rows(k).Pphi_fractional_gain_vs_PB = safe_divide(pb - pp, pb);
    rows(k).low_current_response = current_region_text(pphiLow);
    rows(k).high_current_response = current_region_text(pphiHigh);
    rows(k).prediction_bounds = bounds_text(pphiBounds);
    rows(k).oscillation_morphology = pphiMorph;
    rows(k).quantitative_adequacy = "fail";
end
T = struct2table(rows);
end

function row = empty_channel_row()
row = struct('channel', "", 'PB_improves_over_P0', false, ...
    'Pphi_improves_over_P0', false, 'Pphi_improves_over_PB', false, ...
    'Pphi_fractional_gain_vs_PB', NaN, 'low_current_response', "", ...
    'high_current_response', "", 'prediction_bounds', "", ...
    'oscillation_morphology', "", 'quantitative_adequacy', "");
end

function txt = current_region_text(fracGain)
if fracGain > 0.10
    txt = "improved";
elseif fracGain > 0
    txt = "weakly_improved";
else
    txt = "weak";
end
end

function txt = bounds_text(fraction)
if fraction == 0
    txt = "pass";
elseif fraction <= 0.05
    txt = "localized_violation";
else
    txt = "fail_widespread_violation";
end
end

function T = build_complexity_identifiability_ledger(cfg, residuals, ...
    oscillation, bounds)
variants = ["P0"; "PB"; "Pphi"];
complexity_level = [1; 2; 3];
mean_MSE = zeros(3, 1);
mean_gain_vs_P0 = zeros(3, 1);
mean_Pphi_gain_vs_PB = [NaN; NaN; NaN];
oscillation_morphology = strings(3, 1);
bounds_status = strings(3, 1);
identifiability_status = strings(3, 1);
for k = 1:numel(variants)
    v = variants(k);
    mask = string(residuals.variant) == v;
    mean_MSE(k) = mean(residuals.mean_squared_residual(mask), 'omitnan');
    mean_gain_vs_P0(k) = mean(residuals.MSE_gain_vs_P0(mask), 'omitnan');
    bmask = string(bounds.variant) == v;
    if any(string(bounds.bounds_status(bmask)) ~= "bounded")
        bounds_status(k) = "bounds_fail";
    else
        bounds_status(k) = "bounds_pass";
    end
    omask = string(oscillation.variant) == v;
    if any(string(oscillation.morphology_interpretation(omask)) == ...
            "overproduced_oscillation_morphology")
        oscillation_morphology(k) = "overproduced";
    elseif v == "PB"
        oscillation_morphology(k) = "nonoscillatory";
    else
        oscillation_morphology(k) = "not_overproduced";
    end
    if v == "PB"
        identifiability_status(k) = "preferred_parsimonious_field_baseline";
    elseif v == "Pphi"
        identifiability_status(k) = ...
            "directionally_informative_but_morphology_inadequate";
    else
        identifiability_status(k) = "baseline_current_only_field_model";
    end
end
pbMean = mean_MSE(variants == "PB");
ppMean = mean_MSE(variants == "Pphi");
mean_Pphi_gain_vs_PB(variants == "Pphi") = pbMean - ppMean;
manual_period_fit = repmat(~cfg.phase15E.allowPeriodFit, 3, 1);
T = table(variants, complexity_level, mean_MSE, mean_gain_vs_P0, ...
    mean_Pphi_gain_vs_PB, oscillation_morphology, bounds_status, ...
    identifiability_status, manual_period_fit, 'VariableNames', ...
    {'variant', 'complexity_level', 'mean_MSE', 'mean_MSE_gain_vs_P0', ...
    'mean_Pphi_MSE_gain_vs_PB', 'oscillation_morphology', ...
    'prediction_bounds_status', 'identifiability_status', ...
    'no_manual_period_fit'});
end

function T = build_mechanism_claim_ledger(inputs, residuals, currentRegion, ...
    envelope, oscillation, bounds, complexity)
pbSupported = all(residuals.MSE_gain_vs_P0( ...
    string(residuals.variant) == "PB") > 0) && ...
    all(envelope.Ic_error_reduction_vs_P0_A( ...
    string(envelope.variant) == "PB") > 0);
ppSupported = all(residuals.MSE_gain_vs_P0( ...
    string(residuals.variant) == "Pphi") > 0);
ppIncrement = mean(residuals.Pphi_MSE_gain_vs_PB( ...
    string(residuals.variant) == "Pphi"), 'omitnan');
ppMorphFail = any(string(oscillation.morphology_interpretation) == ...
    "overproduced_oscillation_morphology");
boundsFail = any(string(bounds.bounds_status) ~= "bounded");
highCurrentWeak = any(currentRegion.high_current_gain_vs_P0( ...
    string(currentRegion.variant) == "Pphi") <= 0);
zeroFieldPass = all(inputs.d15ZeroField.zero_field_inheritance_pass);
sharedPhase = all(inputs.d15SharedState.R1_R2_shared_phase_state);

claim = [
    "monotonic_field_suppression"
    "static_phase_interference"
    "phase_interference_quantitative_adequacy"
    "oscillation_morphology"
    "shared_quantitative_field_predictor"
    "AS006_quantitative_field_predictor"
    "prediction_bounds_limitation"
    "high_current_transfer"
    "zero_field_inheritance"
    "R1_R2_shared_phase_state"
    "Josephson_dynamics_established"
    "vortex_mechanism_established"
    "topological_mechanism_established"
    "preferred_field_baseline"
    ];
status = [
    pass_fail(pbSupported)
    "directionally_informative"
    "fail"
    pass_fail(ppMorphFail)
    "fail"
    "fail"
    pass_fail(boundsFail)
    pass_fail(highCurrentWeak)
    pass_fail(zeroFieldPass)
    pass_fail(sharedPhase)
    "false"
    "false"
    "false"
    "PB"
    ];
value = [
    string(pbSupported)
    "limited_low_current_incremental_value"
    "false"
    "overproduced"
    "false"
    "false"
    "retained"
    "weak"
    string(zeroFieldPass)
    string(sharedPhase)
    "false"
    "false"
    "false"
    string(complexity.variant(string(complexity.identifiability_status) == ...
    "preferred_parsimonious_field_baseline"))
    ];
note = [
    "PB improves full-map residuals and Ic-envelope error relative to P0."
    "Pphi has a small MSE gain over PB but this is not sufficient for adequacy."
    "Fails because morphology and bounds remain inadequate."
    "Pphi produces many more turning points than observed."
    "No shared quantitative field predictor is established."
    "Even for AS006, quantitative field adequacy is not established."
    "Prediction-bound failures are preserved."
    "High-current transfer is weak or negative."
    "PB/Pphi recover P0 at nearest zero field."
    "Pphi uses one shared phase envelope for R1/R2."
    "Phase 15 uses a static constrained solver, not RSJ dynamics."
    "No vortex model is introduced."
    "No topology term or topological claim is introduced."
    "Parsimonious field-suppression baseline is preferred over Pphi."
    ];
T = table(claim, status, value, note);
end

function T = build_preferred_variant_decision(residuals, complexity)
pbRows = string(residuals.variant) == "PB";
ppRows = string(residuals.variant) == "Pphi";
pbMean = mean(residuals.mean_squared_residual(pbRows), 'omitnan');
ppMean = mean(residuals.mean_squared_residual(ppRows), 'omitnan');
incrementalGain = pbMean - ppMean;
incrementalFraction = safe_divide(incrementalGain, pbMean);
ppComplex = complexity(string(complexity.variant) == "Pphi", :);
ppMorphFail = string(ppComplex.oscillation_morphology) == "overproduced";
preferred = "PB";
decision = "pass_selected_device_field_suppression_scope";
phaseAwareStatus = "directionally_informative_but_inadequate";
if incrementalFraction >= 0.03 && ~ppMorphFail
    preferred = "Pphi";
    decision = "pass_selected_device_static_phase_interference_scope";
    phaseAwareStatus = "selected_but_quantitative_adequacy_unproven";
end
item = [
    "preferred_field_variant"
    "phase15E_decision"
    "Pphi_mean_MSE_gain_vs_PB"
    "Pphi_fractional_MSE_gain_vs_PB"
    "phase_aware_extension"
    "parsimonious_baseline"
    "quantitative_adequacy"
    ];
status = [
    preferred
    decision
    "descriptive"
    "descriptive"
    phaseAwareStatus
    "PB"
    "fail"
    ];
value = [
    preferred
    decision
    string(incrementalGain)
    string(incrementalFraction)
    phaseAwareStatus
    "PB"
    "false"
    ];
note = [
    "Preferred variant follows residual improvement, morphology, and complexity."
    "Phase 15E closes as field-suppression scope, not phase adequacy."
    "Mean PB MSE minus mean Pphi MSE across R1/R2."
    "Increment is small relative to PB and outweighed by morphology failure."
    "Pphi remains useful but not quantitatively adequate."
    "PB is retained as the parsimonious AS006 field baseline."
    "Quantitative field adequacy is not established."
    ];
T = table(item, status, value, note);
end

function T = build_claim_decision(preferred, claims)
item = [
    "phase15E_closure"
    "phase15E_decision"
    "monotonic_field_suppression"
    "static_phase_interference"
    "preferred_field_variant"
    "Pphi_incremental_value"
    "phase_interference_quantitative_adequacy"
    "shared_quantitative_field_predictor"
    "AS006_quantitative_field_predictor"
    "prediction_bounds_limitation"
    "high_current_transfer"
    "oscillation_morphology"
    "zero_field_inheritance"
    "R1_R2_shared_phase_state"
    "Josephson_dynamics_established"
    "vortex_mechanism_established"
    "topological_mechanism_established"
    "strongest_defensible_claim"
    ];
status = [
    "pass_read_only_AS006_field_adequacy_assessment"
    lookup_item(preferred, "phase15E_decision")
    lookup_item(claims, "monotonic_field_suppression")
    lookup_item(claims, "static_phase_interference")
    lookup_item(preferred, "preferred_field_variant")
    "limited_low_current_only"
    "fail"
    "fail"
    "fail"
    "retained"
    "weak"
    "overproduced"
    lookup_item(claims, "zero_field_inheritance")
    lookup_item(claims, "R1_R2_shared_phase_state")
    "false"
    "false"
    "false"
    "frozen"
    ];
value = [
    "pass_read_only_AS006_field_adequacy_assessment"
    lookup_item(preferred, "phase15E_decision")
    lookup_item(claims, "monotonic_field_suppression")
    lookup_item(claims, "static_phase_interference")
    lookup_item(preferred, "preferred_field_variant")
    "limited_low_current_only"
    "false"
    "false"
    "false"
    "retained"
    "weak"
    "overproduced"
    lookup_item(claims, "zero_field_inheritance")
    lookup_item(claims, "R1_R2_shared_phase_state")
    "false"
    "false"
    "false"
    "Field suppression is supported; static phase interference is directionally informative but not quantitatively adequate."
    ];
note = [
    "Workflow passes because it freezes a bounded field-model claim."
    "Decision is read-only from frozen Phase 15D artifacts."
    "PB/Pphi improve over P0, especially Ic envelope."
    "Pphi adds small descriptive value but fails morphology adequacy."
    "Preferred field baseline is parsimonious PB."
    "Pphi gain is limited and low-current weighted."
    "Fails because oscillation morphology and bounds fail."
    "No transferable quantitative field predictor is established."
    "AS006-only quantitative adequacy is also not established."
    "Prediction-bound failures remain explicit."
    "High-current region remains weak."
    "Pphi overproduces turning points."
    "Zero-field inheritance is retained."
    "R1/R2 share one phase state."
    "Static phase constraints do not establish Josephson dynamics."
    "No vortex model or claim is introduced."
    "No topology term or claim is introduced."
    "Final Phase 15E scientific statement."
    ];
T = table(item, status, value, note);
end

function G = build_gate_summary(cfg, validity, residuals, currentRegion, ...
    envelope, oscillation, bounds, complexity, claims, provenance)
artifactReachable = lookup_item(provenance, ...
    "frozen_phase15D_artifact_commit_reachable") == "true";
clean = lookup_item(provenance, "source_pre_run_clean") == "true";
frozenInputsPresent = required_15D_tables_exist(cfg);
allAssessed = all(ismember(["P0"; "PB"; "Pphi"], ...
    unique(string(residuals.variant)))) && ...
    all(ismember(["R1"; "R2"], unique(string(residuals.channel))));
zeroField = lookup_item(claims, "zero_field_inheritance") == "true";
lowHighSeparated = height(currentRegion) == 6 && ...
    all(isfinite(currentRegion.low_current_mse)) && ...
    all(isfinite(currentRegion.high_current_mse));
oscOverproduced = any(string(oscillation.morphology_interpretation) == ...
    "overproduced_oscillation_morphology");
boundsRetained = any(string(bounds.bounds_status) ~= "bounded");
complexityUsed = any(string(complexity.identifiability_status) == ...
    "preferred_parsimonious_field_baseline");
noMicroscopic = lookup_item(claims, "Josephson_dynamics_established") == ...
    "false" && lookup_item(claims, "vortex_mechanism_established") == ...
    "false" && lookup_item(claims, ...
    "topological_mechanism_established") == "false";
sharedPredictor = lookup_item(claims, ...
    "shared_quantitative_field_predictor") == "true";

gate = [
    "Frozen Phase 15D artifacts consumed unchanged"
    "Frozen Phase 15D artifact commit reachable"
    "No solver rerun"
    "No parameter retuning"
    "No period fit"
    "No loop count reduction after seeing residuals"
    "No topology/vortex/thermal/screening terms"
    "R1/R2 assessed jointly and separately"
    "Zero-field inheritance retained"
    "Low/high-current performance separated"
    "Ic-envelope assessment retained"
    "Oscillation overproduction retained"
    "Prediction-bound violations retained"
    "Complexity considered in model preference"
    "No microscopic Josephson/vortex/topology claim"
    "Shared quantitative field predictor"
    "Clean provenance"
    ];
outcome = [
    pass_fail(frozenInputsPresent)
    pass_fail(artifactReachable)
    pass_fail(~cfg.phase15E.allowSolverRerun)
    pass_fail(~cfg.phase15E.allowParameterRetuning)
    pass_fail(~cfg.phase15E.allowPeriodFit)
    pass_fail(~cfg.phase15E.allowLoopCountReduction)
    pass_fail(~cfg.phase15E.allowTopologyTerm && ...
    ~cfg.phase15E.allowVortexTerm && ~cfg.phase15E.allowThermalMemory && ...
    ~cfg.phase15E.allowMagneticScreening)
    pass_fail(allAssessed)
    pass_fail(zeroField)
    pass_fail(lowHighSeparated)
    pass_fail(height(envelope) == 6)
    pass_fail(oscOverproduced)
    pass_fail(boundsRetained)
    pass_fail(complexityUsed)
    pass_fail(noMicroscopic)
    pass_fail(sharedPredictor)
    pass_fail(clean)
    ];
note = [
    "All required Phase 15D read-only inputs are present."
    "Commit " + string(cfg.phase15E.frozenPhase15DArtifactCommit) + " is in the current history."
    "Phase 15E reads frozen tables only."
    "No model parameter is retuned."
    "Observed AS006 period is not fit."
    "The 26-versus-1 Pphi morphology mismatch is retained."
    "Excluded physics remains excluded."
    "R1/R2 channels are assessed separately and as one shared-phase result."
    "PB/Pphi zero-field inheritance is preserved."
    "Low/high current behavior is separately reported."
    "Critical-current envelope improvement is reported."
    "Pphi oscillation overproduction is retained as a limitation."
    "Prediction-bound violations remain explicit."
    "PB is preferred over Pphi on parsimony plus morphology."
    "Static phase-aware improvement is not promoted to microscopic mechanism."
    "Scientific adequacy gate fails by design; it is not workflow failure."
    "True only for clean source before Phase 15E writes outputs."
    ];
G = table(gate, outcome, note);
end

function tf = required_15D_tables_exist(cfg)
paths = [
    string(cfg.phase15D.executionManifestFile)
    string(cfg.phase15D.variantResidualsFile)
    string(cfg.phase15D.heldoutFieldWindowFile)
    string(cfg.phase15D.currentRangeTransferFile)
    string(cfg.phase15D.fieldSymmetryFile)
    string(cfg.phase15D.criticalCurrentEnvelopeFile)
    string(cfg.phase15D.oscillatoryStructureFile)
    string(cfg.phase15D.zeroFieldInheritanceFile)
    string(cfg.phase15D.predictionBoundsAuditFile)
    string(cfg.phase15D.sharedPhaseStateFile)
    string(cfg.phase15D.channelTransformAuditFile)
    string(cfg.phase15D.gateSummaryFile)
    string(cfg.phase15D.handoffStatusFile)
    ];
tf = all(arrayfun(@(p) exist(char(p), 'file') == 2, paths));
end

function H = build_handoff_status(cfg, claim, gates, provenance)
workflowPass = all(string(gates.outcome) == "pass" | ...
    string(gates.gate) == "Shared quantitative field predictor");
item = [
    "phase15E_closure"
    "phase15E_decision"
    "execution_integrity"
    "preferred_field_variant"
    "monotonic_field_suppression"
    "static_phase_interference"
    "phase_interference_quantitative_adequacy"
    "shared_quantitative_field_predictor"
    "AS006_quantitative_field_predictor"
    "prediction_bounds_limitation"
    "high_current_transfer"
    "oscillation_morphology"
    "Josephson_dynamics_established"
    "vortex_mechanism_established"
    "topological_mechanism_established"
    "source_phase15D_artifact_commit"
    "source_pre_run_clean"
    "next_phase"
    ];
status = [
    lookup_item(claim, "phase15E_closure")
    lookup_item(claim, "phase15E_decision")
    pass_fail(workflowPass)
    lookup_item(claim, "preferred_field_variant")
    lookup_item(claim, "monotonic_field_suppression")
    lookup_item(claim, "static_phase_interference")
    lookup_item(claim, "phase_interference_quantitative_adequacy")
    "false"
    "false"
    "retained"
    "weak"
    "overproduced"
    "false"
    "false"
    "false"
    string(cfg.phase15E.frozenPhase15DArtifactCommit)
    lookup_item(provenance, "source_pre_run_clean")
    string(cfg.phase15E.nextPhase)
    ];
note = [
    "Read-only assessment closes as a bounded claim freeze."
    "Selected decision from frozen Phase 15D outputs."
    "Workflow integrity permits failing quantitative adequacy."
    "PB is preferred as the parsimonious field baseline."
    "Field-dependent suppression is supported."
    "Static phase interference is informative but inadequate."
    "Quantitative phase-interference adequacy fails."
    "No shared quantitative field predictor is claimed."
    "AS006-only quantitative adequacy is not established."
    "Prediction-bound failures are retained."
    "High-current transfer remains weak."
    "Pphi overproduces oscillatory structure."
    "Static constrained phase does not establish Josephson dynamics."
    "No vortex model or claim is introduced."
    "No topological mechanism is introduced."
    "Canonical Phase 15D artifact input."
    "True only when source was clean before writing Phase 15E artifacts."
    "Next roadmap phase."
    ];
H = table(item, status, note);
end

function value = row_value(T, variant, channel, variableName)
mask = string(T.variant) == string(variant) & ...
    string(T.channel) == string(channel);
if any(mask)
    value = T.(variableName)(find(mask, 1));
else
    value = NaN;
end
end

function q = safe_divide(a, b)
if ~isfinite(a) || ~isfinite(b) || abs(b) < eps
    q = NaN;
else
    q = a ./ b;
end
end

function value = lookup_item(T, itemName)
if any(strcmp(T.Properties.VariableNames, 'item'))
    key = string(T.item);
elseif any(strcmp(T.Properties.VariableNames, 'gate'))
    key = string(T.gate);
elseif any(strcmp(T.Properties.VariableNames, 'claim'))
    key = string(T.claim);
else
    value = "";
    return;
end
idx = strcmpi(strtrim(key), string(itemName));
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
value = strtrim(value);
end

function txt = pass_fail(tf)
if tf
    txt = "pass";
else
    txt = "fail";
end
end
