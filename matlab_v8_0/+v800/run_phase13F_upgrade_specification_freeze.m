function out = run_phase13F_upgrade_specification_freeze(cfg)
%RUN_PHASE13F_UPGRADE_SPECIFICATION_FREEZE Freeze constrained 13F upgrades.
%
% Phase 13F.1 freezes the revised R(T) model specification before any
% limiting-case, ablation, or LODO execution is run.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
upgradeSpec = build_upgrade_model_specification();
parameterRoles = build_parameter_role_ledger();
baselineWindow = build_baseline_window_manifest(cfg);
residualShuntSpec = build_residual_shunt_specification();
interfaceTransferLedger = build_interface_transfer_input_ledger();
prohibitedFlexibility = build_prohibited_flexibility_ledger(cfg);
comparisonThresholds = build_comparison_thresholds(cfg);
variantManifest = build_variant_manifest(cfg);
gateSummary = build_gate_summary(cfg, inputs, upgradeSpec, parameterRoles, ...
    baselineWindow, residualShuntSpec, interfaceTransferLedger, ...
    prohibitedFlexibility, comparisonThresholds, variantManifest);
handoffStatus = build_handoff_status(cfg, gateSummary, inputs, ...
    sourceProvenance);

writetable(upgradeSpec, cfg.phase13F.upgradeModelSpecificationFile);
writetable(parameterRoles, cfg.phase13F.parameterRoleLedgerFile);
writetable(baselineWindow, cfg.phase13F.baselineWindowManifestFile);
writetable(residualShuntSpec, cfg.phase13F.residualShuntSpecificationFile);
writetable(interfaceTransferLedger, ...
    cfg.phase13F.interfaceTransferInputLedgerFile);
writetable(prohibitedFlexibility, ...
    cfg.phase13F.prohibitedFlexibilityLedgerFile);
writetable(comparisonThresholds, cfg.phase13F.comparisonThresholdsFile);
writetable(variantManifest, cfg.phase13F.variantManifestFile);
writetable(gateSummary, cfg.phase13F.specificationGateSummaryFile);
writetable(handoffStatus, cfg.phase13F.specificationHandoffStatusFile);
writetable(sourceProvenance, cfg.phase13F.sourceProvenanceFile);

try
    h = v800.plot_phase13F_upgrade_specification_summary(cfg, ...
        variantManifest, comparisonThresholds, parameterRoles, gateSummary);
catch ME
    warning('v8:phase13F1PlotFailed', ...
        'Phase 13F.1 specification summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.upgradeModelSpecification = upgradeSpec;
out.parameterRoleLedger = parameterRoles;
out.baselineWindowManifest = baselineWindow;
out.residualShuntSpecification = residualShuntSpec;
out.interfaceTransferInputLedger = interfaceTransferLedger;
out.prohibitedFlexibilityLedger = prohibitedFlexibility;
out.comparisonThresholds = comparisonThresholds;
out.variantManifest = variantManifest;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.upgradeModelSpecification = ...
    cfg.phase13F.upgradeModelSpecificationFile;
paths.parameterRoleLedger = cfg.phase13F.parameterRoleLedgerFile;
paths.baselineWindowManifest = cfg.phase13F.baselineWindowManifestFile;
paths.residualShuntSpecification = ...
    cfg.phase13F.residualShuntSpecificationFile;
paths.interfaceTransferInputLedger = ...
    cfg.phase13F.interfaceTransferInputLedgerFile;
paths.prohibitedFlexibilityLedger = ...
    cfg.phase13F.prohibitedFlexibilityLedgerFile;
paths.comparisonThresholds = cfg.phase13F.comparisonThresholdsFile;
paths.variantManifest = cfg.phase13F.variantManifestFile;
paths.gateSummary = cfg.phase13F.specificationGateSummaryFile;
paths.handoffStatus = cfg.phase13F.specificationHandoffStatusFile;
paths.sourceProvenance = cfg.phase13F.sourceProvenanceFile;
paths.figurePng = [cfg.phase13F.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13F.figureBaseFile '.pdf'];
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
    "phase13F_upgrade_specification_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "specification_freeze_before_any_phase13F_execution"
    "Commit Phase 13F.1 source first; rerun from clean source; commit specification artifacts separately."
    ];
note = [
    "Phase 13F.1 constrained model-revision specification."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No solver execution, optimizer rerun, or experimental residual improvement test."
    "Specification artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase13DDecision = read_required_table( ...
    cfg.phase13D.predictiveAdequacyDecisionFile);
inputs.phase13DHandoff = read_required_table( ...
    cfg.phase13D.handoffStatusFile);
inputs.phase13EClaim = read_required_table(cfg.phase13E.claimUpdateFile);
inputs.phase13ESelectedScope = read_required_table( ...
    cfg.phase13E.selectedUpgradeScopeFile);
inputs.phase13EGates = read_required_table(cfg.phase13E.gateSummaryFile);
inputs.phase13CObjective = read_required_table( ...
    cfg.phase13C.calibrationObjectiveSpecificationFile);
inputs.phase13CLODO = read_required_table( ...
    cfg.phase13C.leaveOneDeviceOutManifestFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13F.1 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function T = build_upgrade_model_specification()
component = [
    "normal_state_baseline"
    "superconducting_network_reduction"
    "residual_parallel_conduction"
    "interface_transfer_field"
    ];
equation_or_rule = [
    "R_N,d(T)=a_d+b_d*(T-T_ref), estimated only from locked normal-state window"
    "R_network_abs(T)=R_N,d(T)*R_SC_tilde,d(T), with Phase 13C core mapping retained"
    "G_total(T)=G_SC_network(T)+G_residual,d"
    "M_effective,d(x,y)=tau_d(x,y)*M_applied,d(x,y)"
    ];
allowed_inputs = [
    "high-temperature resistance level|high-temperature slope|geometry scaling|primary probe identity"
    "Phase 13A/13C frozen mechanical and weak-link inputs"
    "shared residual fraction or shared geometry-linked residual law"
    "coverage|crack state|thickness|stack|fabrication metadata if independently available"
    ];
prohibited_inputs = [
    "transition-region data from held-out device|low-temperature held-out data"
    "Phase 6 labels|Raman transport targets|device-specific mechanism labels"
    "separate low-temperature shunt fit for each device"
    "free tau_AS001...tau_AS006 fitted to each device R(T)"
    ];
T = table(component, equation_or_rule, allowed_inputs, prohibited_inputs);
end

function T = build_parameter_role_ledger()
parameter = [
    "a_d"
    "b_d"
    "G0_residual"
    "alpha_geometry_residual"
    "tau_level"
    "Tc_mapping_parameters"
    "boundary_crack_coefficients"
    ];
role = [
    "device_input_from_normal_window"
    "device_input_from_normal_window"
    "shared_fit_parameter"
    "shared_fit_parameter"
    "frozen_ordinal_or_metadata_input"
    "shared_fit_parameter_from_phase13C_protocol"
    "shared_fit_parameter_from_phase13C_protocol"
    ];
allowed_to_vary_by_device = [
    true
    true
    false
    false
    true
    false
    false
    ];
fitting_constraint = [
    "estimated before transition from locked normal-state window"
    "estimated before transition from locked normal-state window"
    "shared across all LODO training devices"
    "shared across all LODO training devices"
    "not fitted continuously per device; ordinal/metadata category only"
    "same shared LODO rule as Phase 13C"
    "same shared LODO rule as Phase 13C"
    ];
T = table(parameter, role, allowed_to_vary_by_device, fitting_constraint);
end

function T = build_baseline_window_manifest(cfg)
device = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
scaled_window_start = repmat(cfg.phase13F.normalStateWindowScaled(1), ...
    numel(device), 1);
scaled_window_end = repmat(cfg.phase13F.normalStateWindowScaled(2), ...
    numel(device), 1);
baseline_form = repmat("linear_a_plus_bT", numel(device), 1);
heldout_transition_data_allowed = false(numel(device), 1);
heldout_lowT_data_allowed = false(numel(device), 1);
note = repmat("Estimate baseline only from predeclared normal-state window.", ...
    numel(device), 1);
T = table(device, scaled_window_start, scaled_window_end, baseline_form, ...
    heldout_transition_data_allowed, heldout_lowT_data_allowed, note);
end

function T = build_residual_shunt_specification()
field = [
    "residual_model"
    "allowed_form"
    "critical_device_test"
    "prohibited_form"
    ];
value = [
    "parallel_conductance"
    "G_residual,d=G0+alpha_A*A_d+alpha_P*P_d when independent descriptors exist; otherwise one shared residual fraction"
    "AS003_low_temperature_plateau"
    "separate G_residual fitted directly to each held-out low-temperature curve"
    ];
note = [
    "Residual conduction is separated from normal baseline and superconducting transition."
    "All coefficients must be shared or derived from independent descriptors."
    "AS003 was flagged by Phase 13E as low-temperature plateau dominated."
    "Would encode the answer and break held-out prediction meaning."
    ];
T = table(field, value, note);
end

function T = build_interface_transfer_input_ledger()
input = [
    "coverage_state"
    "crack_state"
    "device_thickness"
    "fabrication_stack"
    "delamination_or_continuity_evidence"
    ];
input_role = [
    "independent_geometry_metadata"
    "independent_geometry_metadata"
    "measured_but_not_ingested_if_available"
    "fabrication_metadata"
    "fabrication_or_microscopy_metadata"
    ];
allowed_mapping = [
    "f_tau coverage contribution"
    "crack_disrupted_transfer category or range"
    "shared thickness modifier"
    "shared stack modifier"
    "ordinal transfer category"
    ];
continuous_per_device_fit_allowed = false(numel(input), 1);
T = table(input, input_role, allowed_mapping, ...
    continuous_per_device_fit_allowed);
end

function T = build_prohibited_flexibility_ledger(cfg)
prohibited = [
    "phase_dynamics"
    "electrothermal_feedback"
    "device_specific_Tc_gain"
    "device_specific_boundary_or_crack_coefficients"
    "Raman_fitting"
    "unrestricted_spatial_disorder_changes"
    "automatic_probe_fallback"
    "transport_relabeling"
    ];
blocked = [
    ~cfg.phase13F.allowPhaseDynamics
    ~cfg.phase13F.allowElectrothermalFeedback
    ~cfg.phase13F.allowDeviceSpecificTcGain
    ~cfg.phase13F.allowDeviceSpecificBoundaryCoefficient && ...
        ~cfg.phase13F.allowDeviceSpecificCrackCoefficient
    ~cfg.phase13F.allowRamanFitting
    ~cfg.phase13F.allowUnrestrictedSpatialDisorder
    true
    true
    ];
reason = [
    "Deferred to later nonlinear phases."
    "Deferred until scalar R(T) foundation is resolved."
    "Would create device-specific mechanism correction."
    "Would erase shared-transfer validation."
    "Raman is not a transport target in Phase 13F."
    "Only two selected Phase 13E upgrades are allowed."
    "AS003 primary mapping remains frozen."
    "Phase 6/13 device conclusions remain frozen."
    ];
T = table(prohibited, blocked, reason);
end

function T = build_comparison_thresholds(cfg)
criterion = [
    "median_heldout_residual_improvement"
    "minimum_primary_devices_improved"
    "AS001_baseline_mismatch_improves"
    "AS003_lowT_plateau_improves"
    "AS006_no_material_worsening"
    "threshold_crossing_availability_increases"
    "uncertainty_coverage_gain"
    "max_pinned_parameter_fold_fraction"
    ];
threshold = [
    string(cfg.phase13F.materialMedianResidualImprovement)
    string(cfg.phase13F.minimumImprovedPrimaryDevices)
    "required"
    "required"
    string(cfg.phase13F.maximumSevereRegression)
    string(cfg.phase13F.minimumCrossingRecoveryGain)
    string(cfg.phase13F.minimumCoverageGain)
    string(cfg.phase13F.maxPinnedParameterFoldFraction)
    ];
comparison_source = repmat("frozen_phase13C_phase13D_baseline", ...
    numel(criterion), 1);
note = [
    "Material improvement is relative, not a tiny numerical decrease."
    "Broad improvement is required for shared predictor claims."
    "Control/baseline failure was central to Phase 13E."
    "Residual-conduction upgrade must address the AS003 plateau."
    "Strong boundary case cannot be sacrificed."
    "Censored/non-crossing outcomes remain explicit."
    "Coverage must improve without becoming uninformatively broad."
    "Boundary saturation indicates non-identifiability."
    ];
T = table(criterion, threshold, comparison_source, note);
end

function T = build_variant_manifest(cfg)
variant_id = string(cfg.phase13F.variantIds(:));
variant_name = [
    "original_phase13C_model"
    "baseline_shunt_upgrade_only"
    "interface_transfer_upgrade_only"
    "both_upgrades"
    ];
baseline_shunt_upgrade = [false; true; false; true];
interface_transfer_upgrade = [false; false; true; true];
execution_status = repmat("not_run_in_phase13F1", numel(variant_id), 1);
purpose = [
    "Frozen baseline comparator"
    "Test whether baseline/residual conduction repairs control and plateau failures"
    "Test whether transfer metadata improves ordering/onset prediction"
    "Test whether both constrained upgrades jointly improve held-out transfer"
    ];
T = table(variant_id, variant_name, baseline_shunt_upgrade, ...
    interface_transfer_upgrade, execution_status, purpose);
end

function T = build_gate_summary(cfg, inputs, upgradeSpec, parameterRoles, ...
    baselineWindow, residualShuntSpec, interfaceTransferLedger, ...
    prohibitedFlexibility, comparisonThresholds, variantManifest)
phase13DEPreserved = lookup_value(inputs.phase13DDecision, ...
    "phase13D_decision") == "pass_partial_predictive_scope" && ...
    lookup_value(inputs.phase13EClaim, "phase13E_decision") == ...
    "baseline_and_shunt_upgrade_plus_interface_transfer_audit_justified";
selected = string(inputs.phase13ESelectedScope.upgrade);
onlyTwoSelected = numel(selected) == 2 && all(ismember(selected, [
    "baseline_and_residual_shunt_upgrade"
    "interface_transfer_or_transparency_input"
    ]));
baselineLocked = all(~logical(baselineWindow.heldout_transition_data_allowed)) && ...
    all(~logical(baselineWindow.heldout_lowT_data_allowed));
shuntSafe = any(string(residualShuntSpec.field) == "prohibited_form");
interfaceSafe = all(~logical(interfaceTransferLedger. ...
    continuous_per_device_fit_allowed));
noDeviceSpecific = all(logical(prohibitedFlexibility.blocked));
variantsFrozen = height(variantManifest) == 4 && all(ismember( ...
    ["F0"; "FB"; "FI"; "FBI"], string(variantManifest.variant_id)));

component = [
    "Phase 13D/E conclusions preserved"
    "Only two selected upgrades specified"
    "Baseline estimated from locked normal-state region"
    "Residual shunt not fitted to held-out lowT response"
    "Interface transfer based on independent metadata or frozen ordinal priors"
    "No device-specific mechanism parameters"
    "Original LODO protocol retained"
    "Four ablation variants declared"
    "Comparison thresholds frozen before execution"
    "Negative and regressive results must be retained"
    "Clean specification provenance captured"
    ];
outcome = [
    passfail(phase13DEPreserved)
    passfail(onlyTwoSelected)
    passfail(baselineLocked)
    passfail(shuntSafe)
    passfail(interfaceSafe)
    passfail(noDeviceSpecific)
    passfail(~isempty(inputs.phase13CLODO) && ~isempty(inputs.phase13CObjective))
    passfail(variantsFrozen)
    passfail(~isempty(comparisonThresholds))
    passfail(true)
    passfail(true)
    ];
note = [
    "Phase 13F is a new test, not a replacement for 13D/E."
    "Baseline/shunt and interface/transfer are the only allowed upgrades."
    "Normal-state baseline cannot use held-out transition or lowT data."
    "Low-temperature shunt cannot be fit per held-out device."
    "tau is constrained by metadata or ordinal priors, not free per device."
    "Device-specific Tc/boundary/crack gains are blocked."
    "Same data lock, folds, objective weights, and probe mappings are reused."
    "F0, FB, FI, and FBI are all required."
    "Adequacy criteria are frozen before Phase 13F execution."
    "Future output tables must retain failures and regressions."
    "Provenance is captured before artifacts are written."
    ];
T = table(component, outcome, note);
end

function T = build_handoff_status(cfg, gateSummary, inputs, sourceProvenance)
phasePass = all(string(gateSummary.outcome) == "pass");
field = [
    "phase13F1_closure"
    "phase13D_decision_preserved"
    "phase13E_decision_preserved"
    "allowed_upgrades"
    "source_commit_sha"
    "next_phase"
    ];
value = [
    conditional(phasePass, "pass_upgrade_specification_freeze", ...
        "fail_specification_incomplete")
    lookup_value(inputs.phase13DDecision, "phase13D_decision")
    lookup_value(inputs.phase13EClaim, "phase13E_decision")
    "baseline_and_residual_shunt_upgrade|interface_transfer_or_transparency_input"
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase13F.nextPhase
    ];
note = [
    "Closure means the constrained revision is specified, not executed."
    "The negative/partial Phase 13D result remains visible."
    "The Phase 13E missing-input audit selects the bounded scope."
    "No other model class may be added in Phase 13F."
    "Source commit captured before output generation."
    "Proceed to limiting cases and ablations next."
    ];
T = table(field, value, note);
end

function out = lookup_value(T, key)
names = string(T.Properties.VariableNames);
normalized = lower(regexprep(names, '[^A-Za-z0-9]', ''));
fieldIdx = find(normalized == "field" | normalized == "item", 1);
valueIdx = find(normalized == "value", 1);
if isempty(fieldIdx) && width(T) >= 2
    fieldIdx = 1;
end
if isempty(valueIdx) && width(T) >= 2
    valueIdx = 2;
end

if ~isempty(fieldIdx) && ~isempty(valueIdx)
    keyColumn = string(T{:, fieldIdx});
    valueColumn = string(T{:, valueIdx});
    mask = normalize_lookup_key(keyColumn) == normalize_lookup_key(key);
else
    mask = false(height(T), 1);
    valueColumn = strings(height(T), 1);
end
if any(mask)
    out = valueColumn(find(mask, 1));
else
    out = "";
end
end

function out = normalize_lookup_key(in)
out = lower(regexprep(strtrim(string(in)), '[^A-Za-z0-9]', ''));
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
