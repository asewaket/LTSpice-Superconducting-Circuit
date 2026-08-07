function out = run_phase16A_identifiability_inventory(cfg)
%RUN_PHASE16A_IDENTIFIABILITY_INVENTORY Freeze global recoverability map.
%
% Phase 16A is a read-only inventory phase. It consumes frozen outputs from
% the six-device R(T), raw nonlinear, and AS006 field campaigns and records
% which latent quantities are constrained by the current data.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
frozenInputs = build_frozen_input_manifest(cfg);
parameterInventory = build_parameter_inventory();
constraintMatrix = build_observable_constraint_matrix();
recoverabilityMap = build_recoverability_map();
degeneracyLedger = build_degeneracy_ledger();
reductionQueue = build_model_reduction_queue();
gateSummary = build_gate_summary(cfg, sourceProvenance, frozenInputs, ...
    parameterInventory, constraintMatrix, recoverabilityMap, ...
    degeneracyLedger, reductionQueue);
handoffStatus = build_handoff_status(cfg, gateSummary);

writetable(parameterInventory, cfg.phase16A.globalParameterInventoryFile);
writetable(constraintMatrix, cfg.phase16A.observableConstraintMatrixFile);
writetable(recoverabilityMap, cfg.phase16A.recoverabilityMapFile);
writetable(degeneracyLedger, cfg.phase16A.degeneracyLedgerFile);
writetable(reductionQueue, cfg.phase16A.modelReductionQueueFile);
writetable(frozenInputs, cfg.phase16A.frozenInputManifestFile);
writetable(gateSummary, cfg.phase16A.gateSummaryFile);
writetable(handoffStatus, cfg.phase16A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase16A.sourceProvenanceFile);

try
    h = v800.plot_phase16A_identifiability_inventory_summary(cfg, ...
        parameterInventory, constraintMatrix, recoverabilityMap, ...
        degeneracyLedger, reductionQueue, gateSummary);
catch ME
    warning('v8:phase16APlotFailed', ...
        'Phase 16A summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.sourceProvenance = sourceProvenance;
out.frozenInputManifest = frozenInputs;
out.parameterInventory = parameterInventory;
out.observableConstraintMatrix = constraintMatrix;
out.recoverabilityMap = recoverabilityMap;
out.degeneracyLedger = degeneracyLedger;
out.modelReductionQueue = reductionQueue;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.globalParameterInventory = cfg.phase16A.globalParameterInventoryFile;
paths.observableConstraintMatrix = ...
    cfg.phase16A.observableConstraintMatrixFile;
paths.recoverabilityMap = cfg.phase16A.recoverabilityMapFile;
paths.degeneracyLedger = cfg.phase16A.degeneracyLedgerFile;
paths.modelReductionQueue = cfg.phase16A.modelReductionQueueFile;
paths.frozenInputManifest = cfg.phase16A.frozenInputManifestFile;
paths.gateSummary = cfg.phase16A.gateSummaryFile;
paths.handoffStatus = cfg.phase16A.handoffStatusFile;
paths.sourceProvenance = cfg.phase16A.sourceProvenanceFile;
paths.figurePng = [cfg.phase16A.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase16A.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
artifactCommit = string(cfg.phase16A.frozenPhase15EArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase15E_artifact_commit"
    "frozen_phase15E_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase16A_identifiability_inventory"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.source_pre_run_clean)
    artifactCommit
    string(git_commit_is_ancestor(cfg.repoRoot, artifactCommit))
    "read_only_global_latent_quantity_inventory"
    ];
note = [
    "Phase 16A inventory and recoverability freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 15E artifact-freeze commit consumed by policy."
    "True when the frozen Phase 15E artifact commit is an ancestor of this run."
    "No fitting, solver rerun, new physics, or device relabeling."
    ];
provenance = table(item, value, note);
end

function frozenInputs = build_frozen_input_manifest(cfg)
artifact = [
    "phase5D2_result_freeze"
    "phase6_hierarchical_evidence_freeze"
    "phase13F4_comparative_adequacy"
    "phase14D_raw_nonlinear_adequacy"
    "phase15E_field_model_adequacy"
    ];
path = [
    string(cfg.phase5D2.handoffStatusFile)
    string(cfg.phase6.handoffStatusFile)
    string(fullfile(cfg.outputDir, 'phase13F4_handoff_status.csv'))
    string(cfg.phase14D.handoffStatusFile)
    string(cfg.phase15E.handoffStatusFile)
    ];
role = [
    "R(T) evidence policy and confidence limiter"
    "six-device model status and evidence tier"
    "reduced R(T) upgrade conclusion"
    "raw dV/dI(I,T) current-only adequacy"
    "AS006 dV/dI(I,B) field adequacy"
    ];
existsFlag = arrayfun(@(p) exist(p, 'file') == 2, path);
frozenInputs = table(artifact, path, role, string(existsFlag), ...
    'VariableNames', {'artifact','path','role','present'});
end

function inventory = build_parameter_inventory()
quantity = [
    "absolute_strain_tensor"
    "relative_mechanical_heterogeneity"
    "coverage_transfer_proxy"
    "boundary_gradient_proxy"
    "crack_relaxation_proxy"
    "local_Tc_distribution"
    "gap_scale_alpha"
    "weak_link_transparency_field_Wij"
    "unique_weak_link_locations"
    "transition_width_deltaT"
    "residual_shunt_contribution"
    "baseline_normal_resistance"
    "critical_current_scale"
    "Ic_temperature_law"
    "field_suppression_scale_B0"
    "static_phase_loop_area"
    "phase_coherence_or_loop_count"
    "R1_R2_shared_phase_state"
    "Josephson_phase_dynamics"
    "vortex_dynamics"
    "order_parameter_symmetry"
    ];
model_layer = [
    "mechanical"
    "mechanical"
    "mechanical"
    "mechanical"
    "mechanical"
    "equilibrium_RT"
    "equilibrium_RT"
    "connectivity"
    "connectivity"
    "equilibrium_RT"
    "equilibrium_RT"
    "equilibrium_RT"
    "nonlinear_current"
    "nonlinear_current"
    "field_response"
    "field_response"
    "field_response"
    "field_response"
    "excluded"
    "excluded"
    "excluded"
    ];
role = [
    "excluded_microscopic_input"
    "latent_proxy"
    "reduced_common_component"
    "reduced_common_component"
    "device_specific_geometry_proxy"
    "latent_distribution"
    "shared_literature_constrained_scale"
    "latent_connectivity_field"
    "spatial_detail"
    "shared_or_class_width"
    "nuisance_and_physical_path"
    "shared_equilibrium_baseline"
    "shared_current_switching_scale"
    "fixed_literature_constrained_shape"
    "shared_field_suppression_scale"
    "synthetic_geometry_prior"
    "candidate_phase_structure"
    "shared_state_constraint"
    "excluded_dynamic_physics"
    "excluded_field_physics"
    "excluded_microscopic_physics"
    ];
classification = [
    "non_identifiable"
    "partially_constrained"
    "partially_constrained"
    "partially_constrained"
    "partially_constrained"
    "partially_constrained"
    "fixed_by_external_input"
    "partially_constrained"
    "non_identifiable"
    "partially_constrained"
    "partially_constrained"
    "partially_constrained"
    "partially_constrained"
    "fixed_by_external_input"
    "partially_constrained"
    "weakly_constrained"
    "weakly_constrained"
    "fixed_by_model_policy"
    "not_tested"
    "not_tested"
    "non_identifiable"
    ];
evidence_basis = [
    "No direct strain tensor measurements."
    "Geometry and Raman proxies support relative heterogeneity only."
    "Phase 12B retained coverage transfer as reduced mechanical proxy."
    "Phase 12B retained boundary gradient as reduced mechanical proxy."
    "Phase 12B retained AS005 crack relaxation proxy."
    "R(T) constrains coarse distribution, not unique map."
    "Gap scale tied to literature prior and local Tc."
    "Weak-link classes supported for selected devices, not unique links."
    "Many spatial maps remain compatible with transport."
    "Broad transitions constrain shared widths only."
    "Phase 5D and 13F show shunt/baseline degeneracy."
    "Phase 13F selected baseline/residual-shunt upgrade."
    "Phase 14 supports current switching directionally."
    "Temperature law is frozen from prior model specification."
    "Phase 15E prefers monotonic PB field suppression."
    "Pphi residual gain is small and morphology overproduced."
    "26-versus-1 turning-point mismatch prevents support."
    "Phase 15B/15D enforce shared R1/R2 phase state."
    "No time-dependent RSJ or sweep-history evidence."
    "No vortex model or raw evidence test."
    "No phase-sensitive pairing measurement."
    ];
next_action = [
    "do_not_fit"
    "carry_as_context"
    "retain_reduced_proxy"
    "retain_reduced_proxy"
    "retain_reduced_proxy"
    "profile_in_phase16B"
    "keep_fixed_or_narrow_prior"
    "profile_class_level_only"
    "do_not_claim"
    "profile_shared_width"
    "profile_with_baseline"
    "profile_with_shunt"
    "profile_current_scale"
    "keep_fixed"
    "profile_field_suppression"
    "reduce_or_defer"
    "sparsify_or_defer"
    "retain_policy_constraint"
    "defer_until_new_data"
    "defer_until_new_data"
    "do_not_claim"
    ];
inventory = table(quantity, model_layer, role, classification, ...
    evidence_basis, next_action);
end

function constraints = build_observable_constraint_matrix()
quantity = [
    "relative_mechanical_heterogeneity"
    "local_Tc_distribution"
    "weak_link_transparency_field_Wij"
    "residual_shunt_contribution"
    "critical_current_scale"
    "field_suppression_scale_B0"
    "static_phase_loop_area"
    "Josephson_phase_dynamics"
    ];
RT_primary = [2; 3; 2; 2; 0; 0; 0; 0];
RT_secondary = [2; 2; 2; 2; 0; 0; 0; 0];
dVdI_IT = [0; 1; 2; 1; 3; 0; 0; 0];
dVdI_IB = [0; 0; 1; 0; 2; 3; 1; 0];
Raman_geometry = [3; 1; 1; 0; 0; 0; 0; 0];
constraint_level = [
    "moderate"
    "moderate"
    "moderate"
    "moderate"
    "moderate"
    "moderate"
    "weak"
    "none"
    ];
constraints = table(quantity, RT_primary, RT_secondary, dVdI_IT, ...
    dVdI_IB, Raman_geometry, constraint_level);
end

function recoverability = build_recoverability_map()
physical_quantity = [
    "Absolute strain tensor"
    "Relative mechanical heterogeneity"
    "Local Tc distribution"
    "Residual shunt contribution"
    "Structured bottleneck requirement"
    "Unique weak-link locations"
    "Current-switching contribution"
    "Field suppression"
    "Static interference"
    "Loop area"
    "Josephson dynamics"
    "Vortex dynamics"
    "Order-parameter symmetry"
    ];
current_recoverability = [
    "not_identifiable"
    "supported"
    "partially_constrained"
    "partially_constrained"
    "supported_for_selected_devices"
    "not_identifiable"
    "supported_directionally"
    "supported_for_AS006"
    "plausible_but_not_quantitatively_supported"
    "weakly_or_non_identifiable"
    "not_tested"
    "not_tested"
    "not_identifiable"
    ];
claim_policy = [
    "excluded"
    "contextual_support"
    "bounded_inference"
    "bounded_inference"
    "device_level_support"
    "do_not_claim"
    "selected_device_support"
    "selected_device_support"
    "directional_only"
    "do_not_fit_to_period"
    "do_not_claim"
    "do_not_claim"
    "do_not_claim"
    ];
recoverability = table(physical_quantity, current_recoverability, ...
    claim_policy);
end

function degeneracy = build_degeneracy_ledger()
degeneracy_id = [
    "Tc_vs_shunt"
    "boundary_vs_disorder"
    "mechanical_proxy_vs_connectivity"
    "field_suppression_vs_static_phase_gain"
    "loop_area_vs_loop_count"
    "current_scale_vs_transition_width"
    ];
description = [
    "Broad R(T) changes can be traded between local Tc distribution and residual conductance floor."
    "Boundary connectivity and correlated disorder can produce similar percolative transfer."
    "Reduced mechanical proxies support classes but do not identify unique weak-link paths."
    "Pphi slightly lowers MSE, but PB explains most field gain with fewer morphology penalties."
    "Many loop areas/counts can generate oscillations; AS006 morphology disfavors dense loops."
    "Switching scale and sigmoid width both influence nonlinear transition sharpness."
    ];
affected_phases = [
    "5D,13F"
    "4,5,7,12"
    "6,12,13"
    "15D,15E"
    "15C,15D,15E"
    "14B,14D"
    ];
current_resolution = [
    "partially_resolved_by_policy"
    "partially_resolved_by_controls"
    "not_unique"
    "resolved_in_favor_of_PB_for_AS006"
    "non_identifiable_from_current_field_map"
    "partially_constrained"
    ];
phase16B_action = [
    "profile_joint_sensitivity"
    "compute_covariance_block"
    "hold_reduced_components_fixed_then_ablate"
    "quantify_delta_MSE_vs_complexity"
    "test_sparse_phase_reduction"
    "profile_current_width_block"
    ];
degeneracy = table(degeneracy_id, description, affected_phases, ...
    current_resolution, phase16B_action);
end

function queue = build_model_reduction_queue()
priority = [1; 2; 3; 4; 5; 6];
candidate_reduction = [
    "retain_PB_as_AS006_field_baseline"
    "replace_dense_Pphi_with_sparse_optional_loop_family"
    "collapse_unique_Wij_locations_to_class_level_support"
    "profile_baseline_and_residual_shunt_jointly"
    "report_local_Tc_as_distribution_not_map"
    "defer_dynamic_phase_or_vortex_models"
    ];
reason = [
    "Phase 15E prefers PB by parsimony and oscillation morphology."
    "Dense static phase model overproduces turning points."
    "Transport does not identify unique spatial links."
    "Phase 13F/5D show baseline-shunt degeneracy."
    "Current observables constrain coarse Tc heterogeneity only."
    "No sweep-history or field-dynamics data identify dynamics."
    ];
status = [
    "recommended"
    "recommended_for_phase16D"
    "recommended"
    "recommended_for_phase16B"
    "recommended"
    "deferred_until_new_data"
    ];
queue = table(priority, candidate_reduction, reason, status);
end

function gates = build_gate_summary(cfg, provenance, frozenInputs, ...
    inventory, constraints, recoverability, degeneracy, reductionQueue)
gate = [
    "Frozen Phase 15E artifacts consumed"
    "All required frozen inputs present"
    "Global parameter inventory emitted"
    "Recoverability classes assigned"
    "Observable constraint matrix emitted"
    "Degeneracy ledger emitted"
    "Model-reduction queue emitted"
    "No new mechanism introduced"
    "No parameter retuning"
    "No solver rerun"
    "Phase 16B handoff declared"
    "Clean provenance"
    ];
pass = [
    git_commit_is_ancestor(cfg.repoRoot, cfg.phase16A.frozenPhase15EArtifactCommit)
    all(string(frozenInputs.present) == "true")
    height(inventory) >= 15
    all(strlength(string(inventory.classification)) > 0)
    height(constraints) >= 6
    height(degeneracy) >= 4
    height(reductionQueue) >= 4
    cfg.phase16A.noNewMechanism
    cfg.phase16A.noParameterRetuning
    cfg.phase16A.noSolverRerun
    string(cfg.phase16A.nextPhase) == "phase16B_sensitivity_and_covariance"
    lookup_value(provenance, "source_pre_run_clean") == "true"
    ];
outcome = strings(numel(gate), 1);
outcome(pass) = "pass";
outcome(~pass) = "fail";
note = [
    "Canonical Phase 15E artifact commit is reachable."
    "Read-only phase inputs exist."
    "Latent quantities across mechanical, R(T), nonlinear, and field layers are listed."
    "Each latent quantity has a recoverability label."
    "Observables are mapped to constraint strength."
    "Known degeneracies are recorded for Phase 16B."
    "Reduction priorities are explicit."
    "Phase 16A is inventory only."
    "No fit or threshold is changed."
    "Frozen artifacts are read, not regenerated."
    "Next phase is sensitivity/covariance."
    "True only for clean source before this run writes outputs."
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gateSummary)
allWorkflowPass = all(string(gateSummary.outcome) == "pass");
item = [
    "phase16A_closure"
    "phase16A_decision"
    "inventory_scope"
    "new_mechanisms_introduced"
    "parameter_retuning_performed"
    "solver_rerun_performed"
    "primary_reduction_result"
    "field_model_reduction"
    "phase16B_ready"
    "next_phase"
    ];
status = [
    ternary(allWorkflowPass, ...
        "pass_global_identifiability_inventory", ...
        "fail_global_identifiability_inventory")
    "proceed_to_sensitivity_and_covariance"
    "mechanical_RT_current_field_layers"
    "false"
    "false"
    "false"
    "use_smallest_spatial_model_supported_by_heldout_data"
    "PB_retained_sparse_phase_optional"
    string(allWorkflowPass)
    string(cfg.phase16A.nextPhase)
    ];
note = [
    "Phase 16A closes only when the inventory and provenance gates pass."
    "Phase 16B should compute sensitivity/covariance, not add physics."
    "The inventory spans frozen Phase 5D2 through Phase 15E."
    "No additional physical mechanism is introduced in Phase 16A."
    "No parameter is fitted or retuned."
    "No previous solver output is regenerated."
    "Dense spatial/phase maps are not claimable from the current data."
    "Phase 15E prefers monotonic PB; static phase remains directional only."
    "True when Phase 16A produced complete read-only ledgers."
    "Next roadmap phase."
    ];
handoff = table(item, status, note);
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, string(commitish));
[status, ~] = system(cmd);
tf = status == 0;
end

function value = lookup_value(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function out = ternary(condition, a, b)
if condition
    out = string(a);
else
    out = string(b);
end
end
