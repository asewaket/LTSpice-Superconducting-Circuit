function out = run_phase13A_constitutive_mapping_freeze(cfg)
%RUN_PHASE13A_CONSTITUTIVE_MAPPING_FREEZE Freeze Phase 13A transport mapping.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase13A_inputs(cfg);
constitutiveModelSpecification = build_constitutive_model_specification();
parameterRoleLedger = build_parameter_role_ledger(cfg);
globalParameterPriors = build_global_parameter_priors();
mechanicalToTcMapping = build_mechanical_to_Tc_mapping();
mechanicalToConnectivityMapping = build_mechanical_to_connectivity_mapping();
normalStateModelSpecification = build_normal_state_model_specification();
disorderModelSpecification = build_disorder_model_specification();
prohibitedFlexibilityLedger = build_prohibited_flexibility_ledger();
calibrationHoldoutPlan = build_calibration_holdout_plan(cfg);
gateSummary = build_gate_summary(cfg, inputs, constitutiveModelSpecification, ...
    parameterRoleLedger, globalParameterPriors, mechanicalToTcMapping, ...
    mechanicalToConnectivityMapping, normalStateModelSpecification, ...
    disorderModelSpecification, prohibitedFlexibilityLedger, ...
    calibrationHoldoutPlan, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(constitutiveModelSpecification, ...
    cfg.phase13A.constitutiveModelSpecificationFile);
writetable(parameterRoleLedger, cfg.phase13A.parameterRoleLedgerFile);
writetable(globalParameterPriors, cfg.phase13A.globalParameterPriorsFile);
writetable(mechanicalToTcMapping, cfg.phase13A.mechanicalToTcMappingFile);
writetable(mechanicalToConnectivityMapping, ...
    cfg.phase13A.mechanicalToConnectivityMappingFile);
writetable(normalStateModelSpecification, ...
    cfg.phase13A.normalStateModelSpecificationFile);
writetable(disorderModelSpecification, ...
    cfg.phase13A.disorderModelSpecificationFile);
writetable(prohibitedFlexibilityLedger, ...
    cfg.phase13A.prohibitedFlexibilityLedgerFile);
writetable(calibrationHoldoutPlan, cfg.phase13A.calibrationHoldoutPlanFile);
writetable(gateSummary, cfg.phase13A.gateSummaryFile);
writetable(handoffStatus, cfg.phase13A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13A.sourceProvenanceFile);

try
    h = v800.plot_phase13A_constitutive_mapping_summary(cfg, ...
        parameterRoleLedger, mechanicalToTcMapping, ...
        mechanicalToConnectivityMapping, calibrationHoldoutPlan, ...
        prohibitedFlexibilityLedger, gateSummary);
catch ME
    warning('v8:phase13APlotFailed', ...
        'Phase 13A constitutive mapping summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.constitutiveModelSpecification = constitutiveModelSpecification;
out.parameterRoleLedger = parameterRoleLedger;
out.globalParameterPriors = globalParameterPriors;
out.mechanicalToTcMapping = mechanicalToTcMapping;
out.mechanicalToConnectivityMapping = mechanicalToConnectivityMapping;
out.normalStateModelSpecification = normalStateModelSpecification;
out.disorderModelSpecification = disorderModelSpecification;
out.prohibitedFlexibilityLedger = prohibitedFlexibilityLedger;
out.calibrationHoldoutPlan = calibrationHoldoutPlan;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.constitutiveModelSpecification = ...
    cfg.phase13A.constitutiveModelSpecificationFile;
out.paths.parameterRoleLedger = cfg.phase13A.parameterRoleLedgerFile;
out.paths.globalParameterPriors = cfg.phase13A.globalParameterPriorsFile;
out.paths.mechanicalToTcMapping = cfg.phase13A.mechanicalToTcMappingFile;
out.paths.mechanicalToConnectivityMapping = ...
    cfg.phase13A.mechanicalToConnectivityMappingFile;
out.paths.normalStateModelSpecification = ...
    cfg.phase13A.normalStateModelSpecificationFile;
out.paths.disorderModelSpecification = ...
    cfg.phase13A.disorderModelSpecificationFile;
out.paths.prohibitedFlexibilityLedger = ...
    cfg.phase13A.prohibitedFlexibilityLedgerFile;
out.paths.calibrationHoldoutPlan = ...
    cfg.phase13A.calibrationHoldoutPlanFile;
out.paths.gateSummary = cfg.phase13A.gateSummaryFile;
out.paths.handoffStatus = cfg.phase13A.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase13A.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase13A.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase13A.figureBaseFile '.pdf'];
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
    "phase13A_constitutive_mapping_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "freeze_mechanical_to_transport_laws_before_RT_prediction"
    "Commit Phase 13A source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 13A constitutive transport mapping freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No R(T) prediction, no calibration, no device relabeling in this phase."
    "Phase 13A artifacts are downstream of frozen Phase 12B/12C outputs."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase13A_inputs(cfg)
inputs = struct();
inputs.phase12BHandoff = read_optional_table(cfg.phase12B.handoffStatusFile);
inputs.phase12BGates = read_optional_table(cfg.phase12B.gateSummaryFile);
inputs.phase12BMechanicalSummary = read_optional_table( ...
    cfg.phase12B.deviceMechanicalSummaryFile);
inputs.phase12BFieldManifest = read_optional_table( ...
    cfg.phase12B.mechanicalFieldManifestFile);
inputs.phase12CHandoff = read_optional_table(cfg.phase12C.handoffStatusFile);
inputs.phase12CGates = read_optional_table(cfg.phase12C.gateSummaryFile);
inputs.phase11DeviceManifest = read_optional_table( ...
    cfg.phase11.deviceObservableManifestFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    try
        T = readtable(pathValue, 'TextType', 'string', ...
            'VariableNamingRule', 'preserve', 'Delimiter', ',');
    catch
        T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
    end
else
    T = table();
end
end

function spec = build_constitutive_model_specification()
mapping_id = [
    "local_superconducting_scale"
    "link_connectivity"
    "normal_state_background"
    "residual_conduction"
    "shared_disorder"
    "heldout_prediction"
    ];
equation_or_policy = [
    "Tc_i=Tc_base+DeltaTc_max*sigmoid(beta0+beta_cov*M_cov_i+beta_z*M_z_i+weak_optional_terms)+deltaTc_i"
    "W_ij=sigmoid(gamma0+gamma_b*M_boundary_ij+gamma_c*M_crack_ij+gamma_cov*M_cov_ij)"
    "R_n or G_n fixed from measured normal-state/geometry/probe inputs"
    "G_measured=G_network+G_shunt with shared bounded shunt rule"
    "deltaTc_i drawn from one shared disorder law and common seed plan"
    "Leave-one-device-out prediction required before adequacy claim"
    ];
status = repmat("frozen_before_RT_prediction", numel(mapping_id), 1);
transport_residuals_used = false(numel(mapping_id), 1);
device_specific_mechanism_allowed = false(numel(mapping_id), 1);
note = [
    "Coverage and thickness primarily control local superconducting support."
    "Boundary and crack primarily control structured connectivity."
    "Normal-state scaling remains separate from superconducting mechanism."
    "Residual background is a shared nuisance rule, not a device mechanism."
    "Seed cherry-picking by device is prohibited."
    "Phase 13A freezes the plan only; Phase 13C performs prediction."
    ];
spec = table(mapping_id, equation_or_policy, status, ...
    transport_residuals_used, device_specific_mechanism_allowed, note);
end

function ledger = build_parameter_role_ledger(cfg)
parameter = [
    "geometry"
    "probe_configuration"
    "measured_RN"
    "beta0"
    "beta_cov"
    "beta_z"
    "beta_boundary_Tc_optional"
    "beta_crack_Tc_optional"
    "Tc_base"
    "DeltaTc_max"
    "gamma0"
    "gamma_boundary"
    "gamma_crack"
    "gamma_coverage"
    "sigma_Tc_disorder"
    "disorder_seed_set"
    "G_shunt_global"
    "device_specific_Tc_gain"
    "device_specific_weak_link_strength"
    "phase6_status_label"
    "phase12C_raman_prediction"
    ];
parameter_role = [
    "measured_input"
    "measured_input"
    "measured_input"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive_optional_weak"
    "shared_constitutive_optional_weak"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive"
    "shared_constitutive"
    "shared_nuisance"
    "shared_nuisance"
    "shared_nuisance"
    "prohibited_device_specific"
    "prohibited_device_specific"
    "prohibited_training_target"
    "qualitative_independent_check_only"
    ];
device_specific_allowed = [
    true; true; true; false; false; false; false; false; false; false; ...
    false; false; false; false; false; false; false; false; false; ...
    false; false ...
    ];
used_for_calibration = [
    true; true; true; true; true; true; true; true; true; true; true; ...
    true; true; true; true; true; true; false; false; false; false ...
    ];
rule = repmat("predeclared_before_RT_residuals", numel(parameter), 1);
rule(parameter_role == "prohibited_device_specific") = ...
    "not_allowed";
rule(parameter_role == "prohibited_training_target") = ...
    "interpretation_only_not_training";
rule(parameter_role == "qualitative_independent_check_only") = ...
    "not_used_to_fit_transport";
ledger = table(parameter, parameter_role, device_specific_allowed, ...
    used_for_calibration, rule);
end

function priors = build_global_parameter_priors()
parameter = [
    "beta0"
    "beta_cov"
    "beta_z"
    "beta_boundary_Tc_optional"
    "beta_crack_Tc_optional"
    "Tc_base_K"
    "DeltaTc_max_K"
    "gamma0"
    "gamma_boundary"
    "gamma_crack"
    "gamma_coverage"
    "sigma_Tc_disorder_K"
    "G_shunt_global_fraction"
    ];
lower_bound = [
    -4; -2; -2; -0.5; -0.5; 0.5; 0; -4; -4; -4; -2; 0; 0 ...
    ];
nominal_value = [
    0; 1; 0.5; 0; 0; 2.5; 2.0; 0; 1; 1; 0.25; 0.15; 0.02 ...
    ];
upper_bound = [
    4; 4; 4; 0.5; 0.5; 8; 6; 4; 4; 4; 2; 1.0; 0.20 ...
    ];
units = [
    "dimensionless"; "dimensionless"; "dimensionless"; ...
    "dimensionless"; "dimensionless"; "K"; "K"; "dimensionless"; ...
    "dimensionless"; "dimensionless"; "dimensionless"; "K"; ...
    "fraction_of_normal_conductance" ...
    ];
fit_scope = repmat("shared_global_only", numel(parameter), 1);
source_class = [
    "bounded_constitutive_prior"
    "mechanical_to_Tc_prior"
    "through_thickness_Tc_prior"
    "weak_optional_Tc_prior"
    "weak_optional_Tc_prior"
    "transport_temperature_scale_prior"
    "transport_temperature_scale_prior"
    "connectivity_prior"
    "boundary_connectivity_prior"
    "crack_connectivity_prior"
    "coverage_connectivity_prior"
    "shared_disorder_prior"
    "shared_residual_conduction_prior"
    ];
priors = table(parameter, lower_bound, nominal_value, upper_bound, ...
    units, fit_scope, source_class);
end

function mapping = build_mechanical_to_Tc_mapping()
mechanical_component = [
    "coverage_transfer"
    "through_thickness_attenuation"
    "boundary_gradient"
    "crack_relaxation"
    ];
Tc_role = [
    "primary_positive_or_negative_shared_effect"
    "primary_vertical_heterogeneity_effect"
    "optional_weak_effect"
    "optional_weak_effect"
    ];
equation_term = [
    "beta_cov*M_cov_i"
    "beta_z*M_z_i"
    "beta_boundary_Tc_optional*M_boundary_i"
    "beta_crack_Tc_optional*M_crack_i"
    ];
default_strength_policy = [
    "active_shared"
    "active_shared"
    "weak_optional_predeclared"
    "weak_optional_predeclared"
    ];
connectivity_role_separated = true(4, 1);
note = [
    "Broad coverage support is allowed to shift local transition scale."
    "Vertical attenuation may broaden or weaken local superconducting scale."
    "Boundary primarily belongs to connectivity; Tc term is weak if used."
    "Crack primarily belongs to connectivity; Tc term is weak if used."
    ];
mapping = table(mechanical_component, Tc_role, equation_term, ...
    default_strength_policy, connectivity_role_separated, note);
end

function mapping = build_mechanical_to_connectivity_mapping()
mechanical_component = [
    "boundary_gradient"
    "crack_relaxation"
    "coverage_transfer"
    "through_thickness_attenuation"
    ];
connectivity_role = [
    "primary_structured_link_effect"
    "primary_crack_link_effect"
    "broad_support_secondary_link_effect"
    "not_direct_link_break"
    ];
equation_term = [
    "gamma_boundary*M_boundary_ij"
    "gamma_crack*M_crack_ij"
    "gamma_coverage*M_cov_ij"
    "not_in_Wij_first_version"
    ];
local_Tc_role_separated = true(4, 1);
note = [
    "Boundary gradients encode bottleneck or weak-link topology."
    "Crack proxy encodes local current redistribution/connectivity change."
    "Coverage may weakly support connectivity but is not a free link map."
    "Through-thickness enters local superconducting scale first."
    ];
mapping = table(mechanical_component, connectivity_role, equation_term, ...
    local_Tc_role_separated, note);
end

function spec = build_normal_state_model_specification()
item = [
    "normal_state_scaling"
    "probe_geometry"
    "residual_conduction"
    "device_specific_normalization"
    "superconducting_mechanism_parameters"
    ];
policy = [
    "Use measured RN or geometry/probe-derived conductance before superconducting mapping"
    "Probe configuration may alter measured four-terminal response as measured input"
    "Use one shared bounded G_shunt_global rule"
    "Allowed only when derived from RN, geometry, or probe metadata"
    "No device-specific mechanism parameters allowed"
    ];
device_specific_allowed = [true; true; false; true; false];
fitting_role = [
    "measured_input"
    "measured_input"
    "shared_nuisance"
    "measured_input"
    "prohibited"
    ];
spec = table(item, policy, device_specific_allowed, fitting_role);
end

function spec = build_disorder_model_specification()
item = [
    "Tc_disorder_distribution"
    "common_seed_policy"
    "seed_selection"
    "mesh_resolution_policy"
    ];
policy = [
    "deltaTc_i sampled from one shared zero-mean law with sigma_Tc_disorder"
    "Use predeclared common seed ensemble for limiting tests and heldout predictions"
    "No favorable seed may be selected separately per device"
    "Mesh changes evaluated in Phase 13B/13C without changing constitutive form"
    ];
status = repmat("frozen_before_RT_prediction", numel(item), 1);
device_specific_allowed = false(numel(item), 1);
spec = table(item, policy, status, device_specific_allowed);
end

function ledger = build_prohibited_flexibility_ledger()
prohibited_item = [
    "device_specific_Tc_gain"
    "device_specific_gamma_boundary"
    "device_specific_gamma_crack"
    "phase6_status_training_label"
    "raman_prediction_transport_target"
    "post_residual_equation_edit"
    "independent_shunt_per_device_without_measured_basis"
    ];
reason = [
    "Would collapse forward model into per-device fitting."
    "Would hard-code expected structured devices."
    "Would hard-code crack-supported AS005 response."
    "Frozen interpretive status must not become a target label."
    "Raman is qualitative until registration exists."
    "Would invalidate constitutive freeze."
    "Would hide missing normal-state/interface physics."
    ];
allowed_alternative = [
    "shared_beta_parameters_only"
    "shared_gamma_boundary_only"
    "shared_gamma_crack_only"
    "use_after_prediction_for_interpretation"
    "qualitative_independent_compatibility_check"
    "record_failure_or_missing_input_audit"
    "shared_G_shunt_or_measured_RN_geometry_input"
    ];
ledger = table(prohibited_item, reason, allowed_alternative);
end

function plan = build_calibration_holdout_plan(cfg)
devices = string(cfg.devices(:));
rows = repmat(empty_holdout_row(), numel(devices), 1);
for k = 1:numel(devices)
    heldout = devices(k);
    train = devices(devices ~= heldout);
    rows(k).heldout_device = heldout;
    rows(k).training_devices = strjoin(train, "|");
    rows(k).calibration_mode = cfg.phase13A.calibrationMode;
    rows(k).shared_parameters_only = true;
    rows(k).phase6_labels_used_as_targets = false;
    rows(k).raman_used_to_fit_transport = false;
    rows(k).predicted_quantities = ...
        "Rtilde_T|T90|T50|T10|width_90_10|Rlow_over_RN|onset|probe_asymmetry";
    rows(k).status = "predeclared_not_run_in_13A";
end
plan = struct2table(rows);
end

function gates = build_gate_summary(cfg, inputs, constitutiveSpec, roles, ...
    priors, TcMap, WMap, normalSpec, disorderSpec, prohibited, ...
    holdoutPlan, sourceProvenance)
phase12BPass = lookup_status(inputs.phase12BHandoff, ...
    "phase12B_closure", "") == "pass_reduced_mechanical_proxy";
if ~isempty(inputs.phase12BGates)
    phase12BPass = phase12BPass && all(string(inputs.phase12BGates.outcome) ...
        == "pass");
end
phase12CQualitative = lookup_status(inputs.phase12CHandoff, ...
    "raman_predictions", "") == "qualitative_device_level_only" && ...
    lookup_status(inputs.phase12CHandoff, ...
    "transport_coupling_performed", "true") == "false";
equationsFrozen = all(string(constitutiveSpec.status) == ...
    "frozen_before_RT_prediction");
rolesSeparated = any(string(TcMap.mechanical_component) == ...
    "coverage_transfer") && any(string(WMap.mechanical_component) == ...
    "boundary_gradient");
sharedCoefficients = all(~roles.device_specific_allowed( ...
    startsWith(string(roles.parameter_role), "shared")));
noDeviceMechanism = ~cfg.phase13A.allowDeviceSpecificMechanismParameters && ...
    all(string(roles.parameter_role) ~= "prohibited_device_specific" | ...
    ~roles.used_for_calibration);
normalSeparated = any(string(normalSpec.fitting_role) == "measured_input") && ...
    any(string(normalSpec.fitting_role) == "shared_nuisance");
disorderFrozen = all(string(disorderSpec.status) == ...
    "frozen_before_RT_prediction");
labelsNotTargets = ~cfg.phase13A.allowPhase6LabelsAsTargets && ...
    all(~holdoutPlan.phase6_labels_used_as_targets);
holdoutPredeclared = all(string(holdoutPlan.calibration_mode) == ...
    cfg.phase13A.calibrationMode);
noRamanFit = ~cfg.phase13A.allowRamanTransportFit && ...
    all(~holdoutPlan.raman_used_to_fit_transport);
noRetuning = ~cfg.phase13A.allowTransportRetuningDuringFreeze && ...
    all(string(prohibited.allowed_alternative) ~= "");
priorsBounded = all(priors.upper_bound > priors.lower_bound);
cleanProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_clean", "false") == "true";

gate = [
    "Phase 12B fields consumed unchanged"
    "Phase 12C remains qualitative only"
    "Constitutive equations frozen"
    "Local Tc and connectivity roles separated"
    "Shared coefficients across devices"
    "No device-specific mechanism parameters"
    "Normal-state scaling separated"
    "Disorder law frozen"
    "Phase 6/v8 labels not used as fitting targets"
    "Calibration and holdout plan predeclared"
    "Raman not used to fit transport"
    "Parameter priors bounded"
    "No post-freeze retuning in Phase 13A"
    "Clean provenance"
    ];
condition = [
    phase12BPass
    phase12CQualitative
    equationsFrozen
    rolesSeparated
    sharedCoefficients
    noDeviceMechanism
    normalSeparated
    disorderFrozen
    labelsNotTargets
    holdoutPredeclared
    noRamanFit
    priorsBounded
    noRetuning
    cleanProvenance
    ];
note = [
    "Phase 13A consumes frozen Phase 12B mechanical components."
    "Phase 12C is retained only as independent qualitative compatibility."
    "No R(T) residuals are inspected before equation freeze."
    "Coverage/thickness map mostly to Tc; boundary/crack map mostly to Wij."
    "Beta/gamma parameters are global, not per device."
    "Per-device mechanism knobs are prohibited."
    "Measured RN/geometry/probe effects remain separate from mechanism."
    "One shared disorder law and seed policy are declared."
    "Frozen interpretive conclusions are not calibration labels."
    "Leave-one-device-out shared-parameter plan is emitted."
    "Raman forward predictions do not determine beta/gamma."
    "Every global prior has lower and upper bounds."
    "If prediction fails, record failure or missing-input audit."
    "True only when the runner starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase13A_constitutive_mapping_freeze"
    "phase13A_closure"
    "raman_used_to_fit_transport"
    "device_specific_mechanism_parameters"
    "phase6_labels_used_as_targets"
    "full_transport_recomputation_required"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(allPass, "pass", "needs_clean_rerun_or_gate_review")
    ternary_status(allPass, "pass_constitutive_mapping_freeze", ...
        "pending_clean_artifact_freeze")
    string(cfg.phase13A.allowRamanTransportFit)
    string(cfg.phase13A.allowDeviceSpecificMechanismParameters)
    string(cfg.phase13A.allowPhase6LabelsAsTargets)
    string(cfg.phase13A.fullTransportRecomputationRequired)
    lookup_status(sourceProvenance, "source_commit_sha", "")
    cfg.phase13A.nextPhase
    ];
note = [
    "Mechanical-to-transport constitutive mapping artifacts generated."
    "Phase 13A closes only after clean provenance and all gates pass."
    "Raman remains an independent qualitative compatibility layer."
    "No per-device superconducting mechanism knobs are allowed."
    "Frozen v8/Phase 6 labels are interpretation only."
    "Phase 13B/13C must run actual forward R(T) calculations."
    "Source commit used to generate Phase 13A artifacts."
    "Run limiting cases and ablations before experimental calibration."
    ];
handoff = table(item, status, note);
end

function row = empty_holdout_row()
row = struct('heldout_device', "", 'training_devices', "", ...
    'calibration_mode', "", 'shared_parameters_only', false, ...
    'phase6_labels_used_as_targets', false, ...
    'raman_used_to_fit_transport', false, 'predicted_quantities', "", ...
    'status', "");
end

function value = lookup_status(T, itemName, fallback)
value = string(fallback);
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'item'))
    return;
end
valueCol = "status";
if any(strcmp(T.Properties.VariableNames, 'value'))
    valueCol = "value";
end
idx = find(string(T.item) == string(itemName), 1, 'first');
if ~isempty(idx) && any(strcmp(T.Properties.VariableNames, valueCol))
    value = string(T.(valueCol)(idx));
end
end

function status = ternary_status(condition, trueValue, falseValue)
if condition
    status = string(trueValue);
else
    status = string(falseValue);
end
end
