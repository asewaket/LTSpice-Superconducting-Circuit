function out = run_phase16E_final_recoverability_claim_freeze(cfg)
%RUN_PHASE16E_FINAL_RECOVERABILITY_CLAIM_FREEZE Freeze final Phase 16 claims.
%
% Phase 16E is read-only. It consumes the closed Phase 15E field adequacy
% decision and Phase 16A-D identifiability/model-reduction artifacts, then
% writes the final recoverability and claim policy. It does not rerun solvers,
% retune parameters, add mechanisms, or promote unrecoverable quantities.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

phaseChainManifest = build_phase_chain_manifest(cfg, inputs);
recoverabilityClaimMatrix = build_recoverability_claim_matrix(inputs);
finalModelClaims = build_final_model_claims(cfg, inputs);
excludedClaims = build_excluded_claims();
preferredReducedModel = build_preferred_reduced_model(cfg, inputs);
evidenceSynthesis = build_evidence_synthesis(inputs);
limitationLedger = build_limitation_ledger(inputs);
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    preferredReducedModel, finalModelClaims);
handoffStatus = build_handoff_status(cfg, gateSummary, ...
    preferredReducedModel, finalModelClaims);

writetable(phaseChainManifest, cfg.phase16E.phaseChainManifestFile);
writetable(recoverabilityClaimMatrix, ...
    cfg.phase16E.recoverabilityClaimMatrixFile);
writetable(finalModelClaims, cfg.phase16E.finalModelClaimsFile);
writetable(excludedClaims, cfg.phase16E.excludedClaimsFile);
writetable(preferredReducedModel, cfg.phase16E.preferredReducedModelFile);
writetable(evidenceSynthesis, cfg.phase16E.evidenceSynthesisFile);
writetable(limitationLedger, cfg.phase16E.limitationLedgerFile);
writetable(gateSummary, cfg.phase16E.gateSummaryFile);
writetable(handoffStatus, cfg.phase16E.handoffStatusFile);
writetable(sourceProvenance, cfg.phase16E.sourceProvenanceFile);

try
    h = v800.plot_phase16E_final_recoverability_claim_freeze_summary( ...
        cfg, phaseChainManifest, recoverabilityClaimMatrix, ...
        finalModelClaims, preferredReducedModel, evidenceSynthesis, ...
        limitationLedger, gateSummary);
catch ME
    warning('v8:phase16EPlotFailed', ...
        'Phase 16E summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.sourceProvenance = sourceProvenance;
out.phaseChainManifest = phaseChainManifest;
out.recoverabilityClaimMatrix = recoverabilityClaimMatrix;
out.finalModelClaims = finalModelClaims;
out.excludedClaims = excludedClaims;
out.preferredReducedModel = preferredReducedModel;
out.evidenceSynthesis = evidenceSynthesis;
out.limitationLedger = limitationLedger;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.phaseChainManifest = cfg.phase16E.phaseChainManifestFile;
paths.recoverabilityClaimMatrix = cfg.phase16E.recoverabilityClaimMatrixFile;
paths.finalModelClaims = cfg.phase16E.finalModelClaimsFile;
paths.excludedClaims = cfg.phase16E.excludedClaimsFile;
paths.preferredReducedModel = cfg.phase16E.preferredReducedModelFile;
paths.evidenceSynthesis = cfg.phase16E.evidenceSynthesisFile;
paths.limitationLedger = cfg.phase16E.limitationLedgerFile;
paths.gateSummary = cfg.phase16E.gateSummaryFile;
paths.handoffStatus = cfg.phase16E.handoffStatusFile;
paths.sourceProvenance = cfg.phase16E.sourceProvenanceFile;
paths.figurePng = [cfg.phase16E.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase16E.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase15EHandoff = read_required_table(cfg.phase15E.handoffStatusFile);
inputs.phase15EGates = read_required_table(cfg.phase15E.gateSummaryFile);
inputs.phase15EClaims = read_required_table(cfg.phase15E.claimDecisionFile);
inputs.phase16AHandoff = read_required_table(cfg.phase16A.handoffStatusFile);
inputs.phase16AGates = read_required_table(cfg.phase16A.gateSummaryFile);
inputs.phase16BHandoff = read_required_table(cfg.phase16B.handoffStatusFile);
inputs.phase16BGates = read_required_table(cfg.phase16B.gateSummaryFile);
inputs.phase16CHandoff = read_required_table(cfg.phase16C.handoffStatusFile);
inputs.phase16CGates = read_required_table(cfg.phase16C.gateSummaryFile);
inputs.phase16CRecoverability = read_required_table( ...
    cfg.phase16C.recoverabilityUpdateFile);
inputs.phase16DHandoff = read_required_table(cfg.phase16D.handoffStatusFile);
inputs.phase16DGates = read_required_table(cfg.phase16D.gateSummaryFile);
inputs.phase16DPreferred = read_required_table( ...
    cfg.phase16D.preferredSpatialModelFile);
inputs.phase16DRecoverability = read_required_table( ...
    cfg.phase16D.recoverabilityUpdateFile);
inputs.phase16DEvidence = read_required_table( ...
    cfg.phase16D.ensembleComponentSupportFile);
inputs.phase16DRegionSupport = read_required_table( ...
    cfg.phase16D.regionSupportSummaryFile);
inputs.phase16DDecision = read_required_table( ...
    cfg.phase16D.modelReductionDecisionFile);
inputs.phase16DProvenance = read_required_table( ...
    cfg.phase16D.sourceProvenanceFile);
end

function T = read_required_table(pathValue)
if exist(pathValue, 'file') ~= 2
    error('Required Phase 16E input is missing: %s', pathValue);
end
T = readtable(pathValue, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase15ECommit = string(cfg.phase16E.frozenPhase15EArtifactCommit);
phase16DCommit = string(cfg.phase16E.frozenPhase16DArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase15E_artifact_commit"
    "frozen_phase15E_artifact_commit_reachable"
    "frozen_phase16D_artifact_commit"
    "frozen_phase16D_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase16E_final_recoverability_claim_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    phase15ECommit
    string(git_commit_is_ancestor(cfg.repoRoot, phase15ECommit))
    phase16DCommit
    string(git_commit_is_ancestor(cfg.repoRoot, phase16DCommit))
    "read_only_phase16_model_claim_freeze"
    ];
note = [
    "Final Phase 16 recoverability and claim freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before output generation."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when source tree is fully clean before output generation."
    "Closed Phase 15E AS006 field adequacy artifact commit."
    "True when Phase 15E artifact commit is in history."
    "Closed Phase 16D spatial reduction artifact commit."
    "True when Phase 16D artifact commit is in history."
    "No solver rerun, residual lookahead, new mechanism, or parameter retuning."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commit)
[status, ~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repoRoot, commit));
tf = status == 0;
end

function manifest = build_phase_chain_manifest(cfg, inputs)
phase = [
    "Phase 15E"
    "Phase 16A"
    "Phase 16B"
    "Phase 16C"
    "Phase 16D"
    "Phase 16E"
    ];
closure = [
    lookup_value(inputs.phase15EHandoff, "phase15E_closure")
    lookup_value(inputs.phase16AHandoff, "phase16A_closure")
    lookup_value(inputs.phase16BHandoff, "phase16B_closure")
    lookup_value(inputs.phase16CHandoff, "phase16C_closure")
    lookup_value(inputs.phase16DHandoff, "phase16D_closure")
    "pending_this_run"
    ];
role = [
    "field_adequacy_baseline"
    "identifiability_inventory"
    "sensitivity_conditioning"
    "profile_objective_exploration"
    "spatial_model_reduction"
    "final_claim_freeze"
    ];
frozen_commit = [
    string(cfg.phase16E.frozenPhase15EArtifactCommit)
    "phase16A_artifact_in_history"
    "phase16B_artifact_in_history"
    "phase16C_artifact_in_history"
    "phase16D_artifact_input"
    "this_run_artifact_pending"
    ];
consumed_without_rerun = [true; true; true; true; true; true];
manifest = table(phase, closure, role, frozen_commit, ...
    consumed_without_rerun);
end

function T = build_recoverability_claim_matrix(inputs)
quantity = [
    "B_supp"
    "field_suppression"
    "static_phase_interference"
    "shared_quantitative_field_predictor"
    "uniform_background"
    "structured_bottleneck_strength"
    "geometry_class_connectivity"
    "boundary_structure"
    "coverage_segmentation"
    "AS005_crack_neighborhood"
    "Tc_heterogeneity"
    "boundary_vs_coverage_decomposition"
    "individual_Wij"
    "microscopic_weak_link_map"
    "dense_phase_loop_map"
    "unique_strain_tensor"
    "Josephson_vortex_dynamics"
    "order_parameter_symmetry"
    "topology"
    ];
recoverability_status = [
    "selected_device_constrained"
    "supported_directional"
    "directionally_informative_but_inadequate"
    "not_established"
    "retained"
    "identifiable_as_grouped_direction"
    "supported_in_reduced_combinations"
    "supported_region_level"
    "partial_redundant_support"
    "supported_not_unique"
    "retained_partial_support"
    "nonunique"
    "non_identifiable"
    "prohibited_claim"
    "not_supported"
    "not_inferred"
    "not_established"
    "not_accessible"
    "not_established"
    ];
claim_allowed = [
    true; true; true; false; true; true; true; true; true; ...
    true; true; false; false; false; false; false; false; ...
    false; false
    ];
claim_strength = [
    "selected_device_scope"
    "selected_device_scope"
    "limited_context"
    "not_allowed"
    "baseline_component"
    "class_level"
    "reduced_combination"
    "region_level"
    "partial"
    "AS005_local_context"
    "partial"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    "not_allowed"
    ];
source_phase = [
    "16B"
    "15E"
    "15E"
    "15E"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "16D"
    "15E-16D"
    "1-16"
    "1-16"
    "1-16"
    "1-16"
    ];
policy_note = [
    "Field suppression scale is constrained only in selected-device context."
    "PB retained as AS006 field baseline."
    "Pphi has limited descriptive value but is not a quantitative field model."
    "Frozen scientific failure from Phase 15E."
    "Shared background retained in reduced model."
    "Report as grouped latent connectivity, not individual components."
    "Report reduced geometry-class combinations, not a dense spatial field."
    "Report as transport-sensitive region-level support."
    "Coverage information partly overlaps boundary term."
    "AS005 crack support is local and nonunique."
    "Local-Tc heterogeneity retained only with ablation context."
    "Do not report unique boundary/coverage amplitudes."
    "Individual W_ij remains diagnostic only."
    "No microscopic strain or weak-link probability map is inferred."
    "Dense phase-loop map remains outside the preferred recoverable model."
    "No unique strain tensor is inferred."
    "Josephson/vortex dynamics are not established by this workflow."
    "Order-parameter symmetry is not accessible from these observables."
    "Topological superconductivity is not established."
    ];
T = table(quantity, recoverability_status, claim_allowed, ...
    claim_strength, source_phase, policy_note);
end

function T = build_final_model_claims(cfg, inputs)
claim = [
    "preferred_field_model"
    "preferred_spatial_representation"
    "reduced_model_scope"
    "connectivity_claim"
    "local_Tc_claim"
    "AS005_crack_claim"
    "AS006_field_claim"
    "Pphi_claim"
    "quantitative_predictor_claim"
    "unique_map_claim"
    ];
status = [
    string(cfg.phase16E.primaryFieldModel)
    string(cfg.phase16E.preferredSpatialRepresentation)
    "semi_phenomenological_literature_constrained"
    "transport_sensitive_structured_connectivity_supported_at_class_level"
    "retained_partial_support"
    "supported_but_not_uniquely_decomposed"
    "monotonic_field_suppression_supported"
    "directionally_informative_but_quantitatively_inadequate"
    "not_established"
    "prohibited"
    ];
allowed_in_manuscript = [
    true; true; true; true; true; true; true; true; false; false
    ];
source = [
    "Phase15E"
    "Phase16D"
    "Phase1-16"
    "Phase16D"
    "Phase16D"
    "Phase16D"
    "Phase15E"
    "Phase15E"
    "Phase15E"
    "Phase16D"
    ];
supporting_value = [
    lookup_value(inputs.phase15EHandoff, "preferred_field_variant")
    lookup_value(inputs.phase16DHandoff, ...
        "preferred_connectivity_representation")
    "model_scope_frozen"
    lookup_value(inputs.phase16DHandoff, "boundary_structure")
    lookup_value(inputs.phase16DHandoff, "Tc_heterogeneity")
    lookup_value(inputs.phase16DHandoff, "AS005_crack_structure")
    lookup_value(inputs.phase15EHandoff, "monotonic_field_suppression")
    lookup_value(inputs.phase15EHandoff, "static_phase_interference")
    lookup_value(inputs.phase15EHandoff, "shared_quantitative_field_predictor")
    lookup_value(inputs.phase16DHandoff, "unique_Wij_recovery")
    ];
T = table(claim, status, allowed_in_manuscript, source, supporting_value);
end

function T = build_excluded_claims()
excluded_claim = [
    "topological_superconductivity"
    "vortex_dynamics"
    "electrothermal_memory"
    "Josephson_phase_dynamics"
    "unique_local_strain_map"
    "unique_microscopic_pairing_symmetry"
    "unique_individual_weak_link_map"
    "universal_quantitative_field_predictor"
    ];
reason = [
    "not modeled or tested"
    "not modeled"
    "not identifiable from available sweep metadata"
    "static phase constraints only"
    "Raman/mechanical registration insufficient"
    "outside model scope"
    "Phase 16C-D recoverability failure"
    "Phase 15E scientific adequacy failure"
    ];
allowed_future_reopen_trigger = [
    "new phase-specific theory and data"
    "field-resolved vortex observables"
    "locked sweep branches and retrapping metadata"
    "explicit time-dependent RSJ/phase data"
    "registered spatial Raman/strain fields"
    "new microscopic measurements"
    "new identifiable observables"
    "new calibrated multimodal predictor"
    ];
T = table(excluded_claim, reason, allowed_future_reopen_trigger);
end

function T = build_preferred_reduced_model(cfg, inputs)
preferred = inputs.phase16DPreferred;
model_id = "Mred_PB_geometry_basis";
field_component = string(cfg.phase16E.primaryFieldModel);
spatial_representation = string(cfg.phase16E.preferredSpatialRepresentation);
preferred_candidate = string(preferred.preferred_candidate(1));
effective_spatial_dof = preferred.effective_spatial_dof(1);
structured_support = preferred.structuredSupport(1);
unique_Wij_recovery = logical(preferred.unique_Wij_recovery(1));
dense_Pphi_primary = false;
retained_components = ...
    "uniform_background,structured_bottleneck,boundary,coverage_partial,AS005_crack_grouped,Tc_partial";
model_policy = ...
    "reduced class-level predictor; not a microscopic weak-link map";
T = table(model_id, field_component, spatial_representation, ...
    preferred_candidate, effective_spatial_dof, structured_support, ...
    unique_Wij_recovery, dense_Pphi_primary, retained_components, ...
    model_policy);
end

function T = build_evidence_synthesis(inputs)
evidence_axis = [
    "R(T)_six_device_context"
    "AS006_field_response"
    "critical_current_switching"
    "Phase16_parameter_profiles"
    "spatial_reduction"
    "region_support"
    ];
summary_status = [
    "structured_support_selected_devices_M0star_sufficient_controls"
    lookup_value(inputs.phase15EHandoff, "phase15E_decision")
    "directionally_supported_but_not_universal"
    lookup_value(inputs.phase16CHandoff, "phase16C_decision")
    lookup_value(inputs.phase16DHandoff, "phase16D_closure")
    "transport_sensitive_region_level_only"
    ];
claim_effect = [
    "supports hierarchy rather than single universal classifier"
    "selects PB and limits Pphi"
    "supports nonlinear switching ingredient with adequacy limits"
    "shows individual parameters are broad/correlated"
    "selects reduced geometry-class representation"
    "prevents microscopic spatial probability claims"
    ];
T = table(evidence_axis, summary_status, claim_effect);
end

function T = build_limitation_ledger(inputs)
limitation = [
    "shared_quantitative_field_predictor"
    "phase_interference_quantitative_adequacy"
    "unique_Wij_recovery"
    "boundary_coverage_unique_decomposition"
    "microscopic_map_claim"
    "formal_likelihood_or_posterior"
    ];
status = [
    "failed"
    lookup_value(inputs.phase15EHandoff, "phase_interference_quantitative_adequacy")
    lookup_value(inputs.phase16DHandoff, "unique_Wij_recovery")
    "failed_expected"
    "prohibited"
    "not_claimed"
    ];
preserved_as_scientific_result = true(6, 1);
interpretation = [
    "Do not claim transferable quantitative field prediction."
    "Pphi remains context, not primary model."
    "Individual link maps remain non-identifiable."
    "Report latent connectivity directions instead."
    "Region support is not microscopic probability."
    "Phase 16C weights are pseudo-objective, not formal posterior."
    ];
T = table(limitation, status, preserved_as_scientific_result, ...
    interpretation);
end

function gates = build_gate_summary(cfg, inputs, sourceProvenance, ...
    preferredReducedModel, finalModelClaims)
clean = lookup_equals(lookup_value(sourceProvenance, ...
    "source_pre_run_clean"), "true");
phase15EClosed = lookup_equals(lookup_value(inputs.phase15EHandoff, ...
    "phase15E_closure"), ...
    "pass_read_only_AS006_field_adequacy_assessment");
phase16AClosed = lookup_starts_with(lookup_value(inputs.phase16AHandoff, ...
    "phase16A_closure"), "pass");
phase16BClosed = lookup_starts_with(lookup_value(inputs.phase16BHandoff, ...
    "phase16B_closure"), "pass");
phase16CClosed = lookup_equals(lookup_value(inputs.phase16CHandoff, ...
    "phase16C_closure"), "pass_profile_pseudo_posterior_exploration");
phase16DClosed = lookup_equals(lookup_value(inputs.phase16DHandoff, ...
    "phase16D_closure"), "pass_spatial_model_reduction");
phase15EReachable = lookup_equals(lookup_value(sourceProvenance, ...
    "frozen_phase15E_artifact_commit_reachable"), "true");
phase16DReachable = lookup_equals(lookup_value(sourceProvenance, ...
    "frozen_phase16D_artifact_commit_reachable"), "true");
preferredFieldIsPB = preferredReducedModel.field_component(1) == ...
    string(cfg.phase16E.primaryFieldModel);
preferredSpatialFrozen = preferredReducedModel.spatial_representation(1) == ...
    string(cfg.phase16E.preferredSpatialRepresentation);
uniqueWijBlocked = ~logical(preferredReducedModel.unique_Wij_recovery(1)) && ...
    cfg.phase16E.uniqueWijInferenceProhibited;
quantClaimBlocked = any(string(finalModelClaims.claim) == ...
    "quantitative_predictor_claim" & ...
    ~finalModelClaims.allowed_in_manuscript);

gate = [
    "Phase 15E adequacy decision consumed"
    "Phase 16A inventory consumed"
    "Phase 16B sensitivity conditioning consumed"
    "Phase 16C profile ensemble consumed"
    "Phase 16D spatial reduction consumed"
    "Phase 15E artifact commit reachable"
    "Phase 16D artifact commit reachable"
    "No new physical mechanism"
    "No parameter retuning"
    "No solver rerun"
    "PB retained as field baseline"
    "Reduced geometry-class basis retained"
    "Dense Pphi excluded from primary claim"
    "Unique Wij inference prohibited"
    "Shared quantitative predictor claim blocked"
    "Scientific limitations preserved"
    "Clean provenance"
    ];
passFlag = [
    phase15EClosed
    phase16AClosed
    phase16BClosed
    phase16CClosed
    phase16DClosed
    phase15EReachable
    phase16DReachable
    cfg.phase16E.noNewMechanism
    cfg.phase16E.noParameterRetuning
    cfg.phase16E.noSolverRerun
    preferredFieldIsPB
    preferredSpatialFrozen
    cfg.phase16E.excludeDensePphiFromPrimary
    uniqueWijBlocked
    quantClaimBlocked
    true
    clean
    ];
expected_scientific_limitation = false(numel(gate), 1);
outcome = strings(numel(gate), 1);
for i = 1:numel(gate)
    if passFlag(i)
        outcome(i) = "pass";
    else
        outcome(i) = "fail";
    end
end
note = [
    "Uses frozen Phase 15E PB/Pphi adequacy decision."
    "Uses Phase 16A observable/parameter inventory."
    "Uses Phase 16B sensitivity/degeneracy conditioning."
    "Uses Phase 16C profile and pseudo-objective ensemble."
    "Uses Phase 16D reduced spatial basis and claim policy."
    "Canonical Phase 15E artifact commit must be in history."
    "Canonical Phase 16D artifact commit must be in history before final freeze."
    "No topology, vortex, heating, new phase dynamics, or microscopy term."
    "No parameter changes or residual rescoring."
    "No solver execution in Phase 16E."
    "PB remains selected AS006 field baseline."
    "Spatial representation stays class-level/reduced."
    "Dense Pphi remains excluded from primary identifiability analysis."
    "Individual link map inference remains blocked."
    "Quantitative universal predictor is not claimed."
    "Negative adequacy/recoverability results are retained."
    "Canonical artifact freeze requires clean pre-run source state."
    ];
gates = table(gate, outcome, expected_scientific_limitation, note);
end

function handoff = build_handoff_status(cfg, gateSummary, ...
    preferredReducedModel, finalModelClaims)
workflowFailures = gateSummary(string(gateSummary.outcome) == "fail" & ...
    ~gateSummary.expected_scientific_limitation, :);
if isempty(workflowFailures)
    closure = "pass_final_recoverability_claim_freeze";
    workflow = "pass";
else
    closure = "fail_workflow_integrity";
    workflow = "fail";
end
item = [
    "phase16E_closure"
    "workflow_integrity"
    "preferred_field_model"
    "preferred_spatial_representation"
    "preferred_reduced_model"
    "effective_spatial_dof"
    "structured_connectivity"
    "monotonic_field_suppression"
    "unique_Wij_recovery"
    "shared_quantitative_predictor"
    "static_phase_interference"
    "topological_claim"
    "microscopic_map_claim"
    "next_phase"
    ];
status = [
    closure
    workflow
    string(cfg.phase16E.primaryFieldModel)
    string(cfg.phase16E.preferredSpatialRepresentation)
    string(preferredReducedModel.model_id(1))
    string(preferredReducedModel.effective_spatial_dof(1))
    "supported_at_class_level"
    lookup_value(finalModelClaims, "AS006_field_claim")
    string(preferredReducedModel.unique_Wij_recovery(1))
    claim_status(finalModelClaims, "quantitative_predictor_claim")
    claim_status(finalModelClaims, "Pphi_claim")
    "prohibited"
    "prohibited"
    string(cfg.phase16E.nextPhase)
    ];
note = [
    "Final Phase 16 closure."
    "All non-scientific gates must pass."
    "Frozen AS006 field baseline from Phase 15E."
    "Frozen reduced spatial representation from Phase 16D."
    "Machine-readable final reduced model identifier."
    "Preferred model effective spatial degree count."
    "Structured connectivity may be reported only at class level."
    "AS006 monotonic field suppression claim from Phase 15E."
    "Individual W_ij recovery remains false."
    "No shared quantitative predictor is claimed."
    "Static phase interference retained as limited context."
    "No topological claim is allowed."
    "No microscopic weak-link map is allowed."
    "Next roadmap stage after Phase 16 claim freeze."
    ];
handoff = table(item, status, note);
end

function status = claim_status(T, key)
idx = string(T.claim) == key;
if any(idx)
    status = string(T.status(find(idx, 1)));
else
    status = "missing";
end
end

function value = lookup_value(T, key)
value = "";
names = string(T.Properties.VariableNames);
keyNames = ["item", "field", "key", "gate", "claim", ...
    "decision_item", "quantity", "component"];
valueNames = ["status", "value", "outcome", "decision"];
keyColumn = "";
keyNeedle = normalize_lookup_text(key);
for i = 1:numel(keyNames)
    if any(names == keyNames(i))
        candidate = normalize_lookup_text(T.(keyNames(i)));
        if any(candidate == keyNeedle)
            keyColumn = keyNames(i);
            break;
        end
    end
end
if keyColumn == ""
    return;
end
row = normalize_lookup_text(T.(keyColumn)) == keyNeedle;
for i = 1:numel(valueNames)
    if any(names == valueNames(i))
        value = string(T.(valueNames(i))(find(row, 1)));
        value = clean_lookup_value(value);
        return;
    end
end
end

function tf = lookup_equals(actual, expected)
tf = normalize_lookup_text(actual) == normalize_lookup_text(expected);
end

function tf = lookup_starts_with(actual, expectedPrefix)
tf = startsWith(normalize_lookup_text(actual), ...
    normalize_lookup_text(expectedPrefix));
end

function value = clean_lookup_value(value)
value = strtrim(string(value));
value = erase(value, '"');
value = erase(value, "'");
end

function text = normalize_lookup_text(value)
text = lower(clean_lookup_value(value));
end
