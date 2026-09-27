function out = run_phase19B_quantitative_mechanical_model_specification(cfg)
%RUN_PHASE19B_QUANTITATIVE_MECHANICAL_MODEL_SPECIFICATION
% Freeze the future quantitative mechanics contract without executing FEM.
%
% Phase 19B consumes the Phase 19A readiness gate. It specifies the future
% elasticity/Raman-forward architecture, input classes, uncertainty terms,
% and unlock criteria. It does not mesh, solve, invert Raman, or generate
% device strain fields.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19B_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

architectureSpecification = build_architecture_specification();
domainSpecification = build_domain_specification();
constitutiveSpecification = build_constitutive_specification();
inputClassification = build_input_classification(inputs);
interfaceAndBoundarySpecification = build_interface_boundary_specification();
ramanForwardModel = build_raman_forward_model();
uncertaintySpecification = build_uncertainty_specification();
executionUnlockCriteria = build_execution_unlock_criteria(inputs);
mechanicalOutputSpecification = build_mechanical_output_specification( ...
    executionUnlockCriteria);
gateSummary = build_gate_summary(inputs, executionUnlockCriteria, ...
    sourceProvenance);
handoffStatus = build_handoff_status(gateSummary, executionUnlockCriteria);

writetable(architectureSpecification, paths.architectureSpecification);
writetable(domainSpecification, paths.domainSpecification);
writetable(constitutiveSpecification, paths.constitutiveSpecification);
writetable(inputClassification, paths.inputClassification);
writetable(interfaceAndBoundarySpecification, ...
    paths.interfaceAndBoundarySpecification);
writetable(ramanForwardModel, paths.ramanForwardModel);
writetable(uncertaintySpecification, paths.uncertaintySpecification);
writetable(executionUnlockCriteria, paths.executionUnlockCriteria);
writetable(mechanicalOutputSpecification, ...
    paths.mechanicalOutputSpecification);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, inputClassification, ...
        executionUnlockCriteria, gateSummary);
catch ME
    warning('v8:phase19BPlotFailed', ...
        'Phase 19B specification summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.architectureSpecification = architectureSpecification;
out.domainSpecification = domainSpecification;
out.constitutiveSpecification = constitutiveSpecification;
out.inputClassification = inputClassification;
out.interfaceAndBoundarySpecification = interfaceAndBoundarySpecification;
out.ramanForwardModel = ramanForwardModel;
out.uncertaintySpecification = uncertaintySpecification;
out.executionUnlockCriteria = executionUnlockCriteria;
out.mechanicalOutputSpecification = mechanicalOutputSpecification;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19B_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19AHandoff = fullfile(outputDir, ...
    'phase19A_handoff_status.csv');
paths.phase19AMechanicalReadinessDecision = fullfile(outputDir, ...
    'phase19A_mechanical_readiness_decision.csv');
paths.phase19ARegistrationReadiness = fullfile(outputDir, ...
    'phase19A_registration_readiness.csv');
paths.phase19AMaterialsInventory = fullfile(outputDir, ...
    'phase19A_materials_parameter_inventory.csv');
paths.phase19ASpatialInputInventory = fullfile(outputDir, ...
    'phase19A_spatial_input_inventory.csv');
paths.architectureSpecification = fullfile(outputDir, ...
    'phase19B_architecture_specification.csv');
paths.domainSpecification = fullfile(outputDir, ...
    'phase19B_domain_specification.csv');
paths.constitutiveSpecification = fullfile(outputDir, ...
    'phase19B_constitutive_specification.csv');
paths.inputClassification = fullfile(outputDir, ...
    'phase19B_input_classification.csv');
paths.interfaceAndBoundarySpecification = fullfile(outputDir, ...
    'phase19B_interface_boundary_specification.csv');
paths.ramanForwardModel = fullfile(outputDir, ...
    'phase19B_raman_forward_model.csv');
paths.uncertaintySpecification = fullfile(outputDir, ...
    'phase19B_uncertainty_specification.csv');
paths.executionUnlockCriteria = fullfile(outputDir, ...
    'phase19B_execution_unlock_criteria.csv');
paths.mechanicalOutputSpecification = fullfile(outputDir, ...
    'phase19B_mechanical_output_specification.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19B_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19B_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19B_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19B_quantitative_mechanical_specification_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19AHandoff = read_required_table(paths.phase19AHandoff);
inputs.phase19AReadinessDecision = read_required_table( ...
    paths.phase19AMechanicalReadinessDecision);
inputs.phase19ARegistrationReadiness = read_required_table( ...
    paths.phase19ARegistrationReadiness);
inputs.phase19AMaterialsInventory = read_required_table( ...
    paths.phase19AMaterialsInventory);
inputs.phase19ASpatialInputInventory = read_required_table( ...
    paths.phase19ASpatialInputInventory);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19B input is missing:\n%s', pathValue);
end
T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
    'ReadVariableNames', true, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
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
    "phase19B_quantitative_mechanical_model_specification"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "specification_only_no_FEM_no_strain_field_no_raman_inversion"
    "Commit Phase 19B source first; rerun from clean source; commit specification artifacts separately."
    ];
note = [
    "Phase 19B freezes the future quantitative mechanics model contract."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No mesh, no numerical mechanics solve, no strain tensor, no Raman-to-transport coupling."
    "Specification artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function spec = build_architecture_specification()
stage = [
    "device_stack_and_geometry"
    "residual_stressor_load"
    "interface_transfer"
    "elastic_displacement_solution"
    "strain_tensor_definition"
    "in_plane_output_subset"
    "raman_forward_observable"
    ];
mathematical_form = [
    "substrate+oxide+MoTe2+encapsulation_or_stressor+crack/boundary geometry"
    "film_force_or_residual_stress_boundary_condition"
    "traction_continuity_or_bounded_slip_transfer_law"
    "solve div(sigma)+f=0 for u(x,y,z)"
    "epsilon_ij=0.5*(du_i/dx_j+du_j/dx_i)"
    "epsilon_xx, epsilon_yy, epsilon_xy"
    "Delta_omega_m(r)=sum_ij K_ij_m epsilon_ij(r)+Delta_omega_m_nonstrain(r)"
    ];
execution_status = repmat("specified_not_executed", numel(stage), 1);
numerical_output_allowed_now = false(numel(stage), 1);
note = [
    "Future geometry domains are declared before any meshing."
    "Load magnitude remains an input-recovery requirement."
    "Interface transfer must be declared before FEM execution."
    "No displacement field is computed in Phase 19B."
    "Tensor definition is mathematical only in Phase 19B."
    "First executable generation is limited to in-plane tensor components."
    "Raman shifts are observables with nuisance terms, not direct strain measurements."
    ];
spec = table(stage, mathematical_form, execution_status, ...
    numerical_output_allowed_now, note);
end

function domains = build_domain_specification()
domain = [
    "substrate"
    "oxide"
    "MoTe2_flake"
    "encapsulation_or_stressor"
    "MoTe2_stressor_interface"
    "AS005_crack_or_relaxation_zone"
    "AS002_AS006_half_coverage_boundary"
    ];
required_geometry = [
    "substrate_extent_and_thickness_or_halfspace_policy"
    "oxide_thickness_and_lateral_extent"
    "flake_polygon_thickness_hallbar_coordinate_frame"
    "stressor_polygon_thickness_and_overlap"
    "registered_interface_footprint_and_transfer_policy"
    "crack_coordinates_width_orientation_and_tip_location"
    "boundary_line_coordinates_relative_to_hallbar"
    ];
input_class_now = [
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    ];
execution_requirement = repmat("required_before_FEM_execution", ...
    numel(domain), 1);
note = [
    "May use literature/wafer stack only after traceable device association."
    "Oxide stack controls clamping and load transfer."
    "MoTe2 thickness and crystal axes are not optional for quantitative strain."
    "Stressor thickness plus residual stress sets applied load."
    "Interface law prevents hidden conversion from geometry to strain."
    "AS005 crack cannot be treated as a decorative mask in quantitative mechanics."
    "Half-coverage boundary must be a quantitative coordinate, not a qualitative label."
    ];
domains = table(domain, required_geometry, input_class_now, ...
    execution_requirement, note);
end

function constitutive = build_constitutive_specification()
component = [
    "substrate"
    "oxide"
    "MoTe2_in_plane"
    "MoTe2_out_of_plane"
    "stressor_or_encapsulation"
    "interface"
    ];
constitutive_choice = [
    "linear_elastic_isotropic_or_literature_stack"
    "linear_elastic_isotropic_literature_constrained"
    "anisotropic_linear_elastic_preferred_if_crystal_axis_known"
    "bounded_effective_out_of_plane_response"
    "linear_elastic_residual_stress_or_film_force_input"
    "perfect_bond_to_bounded_slip_sensitivity_family"
    ];
current_status = [
    "not_device_bound"
    "not_device_bound"
    "specified_but_not_executable_without_axis_and_constants"
    "specified_but_not_primary_first_generation"
    "load_parameter_missing"
    "declared_not_calibrated"
    ];
transport_input_allowed = false(numel(component), 1);
note = [
    "Substrate assumptions must be archived as model inputs."
    "Oxide constants may be literature constrained but not silent defaults."
    "MoTe2 anisotropy is the default target; isotropic use must be an explicit ablation."
    "First target remains in-plane components, not full six-component tensor."
    "Residual stress cannot be inferred from transport."
    "Interface-transfer uncertainty is a first-class nuisance parameter."
    ];
constitutive = table(component, constitutive_choice, current_status, ...
    transport_input_allowed, note);
end

function classes = build_input_classification(inputs)
spatial = inputs.phase19ASpatialInputInventory;
devices = string(spatial.device);
requiredInput = [
    "raw_raman_coordinates"
    "raman_scan_start_end_and_step_count"
    "same_session_optical_or_SEM_image"
    "hall_bar_mask_dimensions"
    "stressor_boundary_coordinates"
    "AS005_crack_coordinates"
    "MoTe2_thickness"
    "stressor_thickness"
    "film_force_or_residual_stress"
    "crystal_axis_orientation"
    "substrate_oxide_stack"
    "minimum_elastic_parameter_set"
    "interface_transfer_model"
    "raman_mode_assignment"
    "raman_polarization_information"
    ];
why = [
    "establishes measurement positions"
    "enables quantitative 1D line registration"
    "provides landmarks for registration"
    "sets absolute device coordinate scale"
    "sets mechanical boundary coordinates"
    "sets AS005 crack relaxation geometry"
    "sets flake mechanical stiffness"
    "converts stressor geometry into load"
    "sets applied mechanical load"
    "sets anisotropic elasticity and Raman tensor frame"
    "sets clamping and boundary conditions"
    "bounds elastic response"
    "sets strain transfer into the flake"
    "defines Raman observable identity"
    "separates tensor response from orientation/polarization ambiguity"
    ];

rows = table();
for d = 1:numel(devices)
    device = devices(d);
    for k = 1:numel(requiredInput)
        classification = classify_input(device, requiredInput(k), spatial);
        rows = [rows; table(device, requiredInput(k), classification, ...
            why(k), missing_action(requiredInput(k), classification), ...
            'VariableNames', {'device', 'required_input', ...
            'input_class', 'why_it_matters', ...
            'required_recovery_action'})]; %#ok<AGROW>
    end
end
classes = rows;
end

function cls = classify_input(device, requiredInput, spatial)
row = spatial(string(spatial.device) == string(device), :);
if isempty(row)
    cls = "unknown_to_be_inferred";
    return;
end
switch string(requiredInput)
    case "stressor_boundary_coordinates"
        value = string(row.stressor_boundary_coordinates(1));
    case "AS005_crack_coordinates"
        value = string(row.crack_coordinates(1));
    case "hall_bar_mask_dimensions"
        value = string(row.hall_bar_coordinates(1));
    case "MoTe2_thickness"
        value = string(row.mote2_thickness(1));
    case "film_force_or_residual_stress"
        value = string(row.film_force_or_residual_stress(1));
    case "crystal_axis_orientation"
        value = string(row.crystal_axis_orientation(1));
    case "substrate_oxide_stack"
        value = string(row.substrate_oxide_stack(1));
    case "raman_mode_assignment"
        value = string(row.raman_mode_assignment(1));
    case "raman_polarization_information"
        value = string(row.polarization_information(1));
    otherwise
        value = "not_archived";
end

if contains(value, "geometry_context") || contains(value, "geometry_proxy")
    cls = "measured_but_not_quantitatively_registered";
elseif contains(value, "literature")
    cls = "literature_constrained_not_device_bound";
elseif contains(value, "known") || contains(value, "available")
    cls = "measured";
else
    cls = "unknown_to_be_inferred";
end
end

function action = missing_action(requiredInput, classification)
if classification == "measured"
    action = "preserve_traceable_source_and_uncertainty";
elseif classification == "measured_but_not_quantitatively_registered"
    action = "recover_coordinate_transform_and_absolute_scale";
elseif classification == "literature_constrained_not_device_bound"
    action = "bind_literature_value_to_device_stack_or_mark_ablation";
else
    switch string(requiredInput)
        case "raw_raman_coordinates"
            action = "recover_raw_scan_coordinate_table";
        case "raman_scan_start_end_and_step_count"
            action = "recover_scan_axis_metadata";
        case "same_session_optical_or_SEM_image"
            action = "recover_registration_image_with_landmarks";
        case "interface_transfer_model"
            action = "declare_perfect_bond_or_bounded_slip_family";
        otherwise
            action = "recover_or_keep_FEM_execution_blocked";
    end
end
end

function spec = build_interface_boundary_specification()
feature = [
    "stressor_residual_stress"
    "film_force_boundary_condition"
    "perfect_bond_interface"
    "bounded_slip_interface"
    "AS005_crack"
    "AS002_AS006_half_coverage_boundary"
    "mesh_convergence"
    ];
specification = [
    "sigma_res or force-per-width input with uncertainty interval"
    "traction boundary applied through stressor footprint"
    "upper-bound transfer assumption"
    "sensitivity family with transfer length or slip compliance"
    "traction-free or relaxed-zone representation with bounded geometry"
    "registered material-boundary line with finite transition-width sensitivity"
    "refine until target fields change below declared tolerance"
    ];
allowed_now = false(numel(feature), 1);
required_before_execution = true(numel(feature), 1);
note = [
    "Load magnitude is missing in Phase 19A."
    "Boundary condition cannot be tuned to transport."
    "Must be an explicit model branch, not a hidden default."
    "Required to bound interface uncertainty."
    "Crack representation is central for AS005."
    "Half-coverage boundary is central for AS002/AS006."
    "Convergence is part of the future executable standard."
    ];
spec = table(feature, specification, allowed_now, ...
    required_before_execution, note);
end

function raman = build_raman_forward_model()
term = [
    "strain_coupling"
    "doping_nuisance"
    "thickness_nuisance"
    "interface_nuisance"
    "optical_interference_nuisance"
    "temperature_nuisance"
    "calibration_offset"
    ];
mathematical_role = [
    "sum_ij K_ij_m epsilon_ij(r)"
    "Delta_omega_doping_m(r)"
    "Delta_omega_thickness_m(r)"
    "Delta_omega_interface_m(r)"
    "Delta_omega_optical_m(r)"
    "Delta_omega_temperature_m(r)"
    "mode_specific_additive_offset"
    ];
input_class_now = [
    "literature_constrained_not_device_bound"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    "unknown_to_be_inferred"
    ];
execution_status = repmat("specified_not_fit", numel(term), 1);
note = [
    "Raman tensor coefficients require mode identity, crystal axes, and polarization context."
    "Raman shifts must not automatically become strain."
    "Thickness shifts can mimic strain response."
    "Interface effects remain nuisance terms."
    "Optical stack effects remain nuisance terms."
    "Temperature and laser heating must be bounded."
    "Offsets must be calibrated, not absorbed as strain."
    ];
raman = table(term, mathematical_role, input_class_now, ...
    execution_status, note);
end

function uncertainty = build_uncertainty_specification()
parameter = [
    "registration_transform_uncertainty"
    "film_force_or_residual_stress_interval"
    "MoTe2_elastic_constants"
    "crystal_axis_orientation"
    "interface_transfer_parameter"
    "layer_thicknesses"
    "crack_geometry"
    "raman_tensor_coefficients"
    "nonstrain_raman_terms"
    ];
status = repmat("required_before_execution", numel(parameter), 1);
propagation_target = [
    "epsilon_xx_epsilon_yy_epsilon_xy"
    "strain_magnitude_and_gradient"
    "anisotropic_strain_response"
    "tensor_frame_and_Raman_response"
    "strain_transfer_amplitude"
    "mechanical_stiffness_and_load_transfer"
    "AS005_relaxation_profile"
    "Raman_forward_observable"
    "Raman_recoverability_bounds"
    ];
note = [
    "At least one registered device line/map is needed before FEM."
    "Load interval is not recoverable from transport."
    "Literature values must remain uncertainty intervals unless measured."
    "Unknown axis blocks anisotropic tensor interpretation."
    "Interface transfer is a leading uncertainty, not a footnote."
    "Thickness uncertainty propagates directly into stiffness."
    "Crack localization requires quantitative coordinates."
    "Raman coefficients require mode and polarization handling."
    "Nuisance terms prevent overclaiming Raman strain."
    ];
uncertainty = table(parameter, status, propagation_target, note);
end

function criteria = build_execution_unlock_criteria(inputs)
readiness = inputs.phase19AReadinessDecision;
phase19BPolicy = lookup_item(readiness, ...
    "phase19B_mechanical_forward_model_allowed");
registration = inputs.phase19ARegistrationReadiness;
materials = inputs.phase19AMaterialsInventory;

atLeastOneRegistered = any(registration.quantitative_2D_mechanics_allowed) || ...
    any(registration.quantitative_1D_mechanics_allowed);
materialsComplete = any(materials.quantitative_mechanics_materials_complete);

criterion = [
    "phase19A_readiness_consumed"
    "at_least_one_device_quantitative_registration"
    "mechanical_geometry_complete"
    "film_force_input_available"
    "layer_thicknesses_available"
    "minimum_elastic_parameter_set_available"
    "interface_model_declared"
    "uncertain_parameters_bounded"
    "FEM_execution_allowed"
    ];
current_value = [
    string(phase19BPolicy == "specification_only_no_FEM_execution")
    string(atLeastOneRegistered)
    "false"
    "false"
    string(any(materials.mote2_thickness_available) && ...
        any(materials.stressor_thickness_available))
    string(any(materials.elastic_constants_available))
    "true"
    "false"
    "false"
    ];
required_value = [
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    ];
pass = current_value == required_value;
pass(end) = all(pass(1:end-1));
current_value(end) = string(pass(end));
status = pass_fail(pass);
note = [
    "19B is specification-only because 19A blocks FEM execution."
    "1D registration is sufficient for first executable line-scan mechanics."
    "Device, stressor, crack, and half-coverage coordinates must close."
    "Applied load must be measured or independently bounded."
    "MoTe2 and stressor thicknesses are required."
    "Elastic constants must be bound as measured or literature-constrained."
    "Phase 19B declares the interface family but does not calibrate it."
    "All leading uncertainty parameters must have intervals before execution."
    "FEM execution remains false until every prerequisite passes."
    ];
criteria = table(criterion, current_value, required_value, status, pass, note);
end

function outputs = build_mechanical_output_specification(criteria)
femAllowed = lookup_criterion_pass(criteria, "FEM_execution_allowed");
output = [
    "displacement_field_u_xyz"
    "epsilon_xx"
    "epsilon_yy"
    "epsilon_xy"
    "strain_gradient_along_registered_line"
    "boundary_response_location"
    "crack_relaxation_profile"
    "raman_forward_prediction"
    "full_3D_six_component_tensor"
    ];
first_generation_allowed = [
    femAllowed
    femAllowed
    femAllowed
    femAllowed
    femAllowed
    femAllowed
    femAllowed
    false
    false
    ];
phase19B_status = repmat("specified_not_generated", numel(output), 1);
note = [
    "Future FEM displacement field; not produced now."
    "Primary in-plane target when FEM unlocks."
    "Primary in-plane target when FEM unlocks."
    "Primary in-plane shear target when FEM unlocks."
    "Attainable once quantitative 1D Raman registration exists."
    "Attainable once boundary coordinates exist."
    "Attainable for AS005 once crack coordinates exist."
    "Requires Raman nuisance model and registered measurements."
    "Explicitly outside first executable generation."
    ];
outputs = table(output, first_generation_allowed, phase19B_status, note);
end

function gates = build_gate_summary(inputs, criteria, sourceProvenance)
sourceClean = lookup_item(sourceProvenance, "source_pre_run_clean") == "true";
phase19AClosed = lookup_item(inputs.phase19AHandoff, ...
    "phase19A_closure") == ...
    "pass_readiness_gap_freeze_no_quantitative_strain_tensor";
femBlocked = ~lookup_criterion_pass(criteria, "FEM_execution_allowed");

component = [
    "Clean provenance"
    "Phase 19A readiness consumed"
    "Specification-only scope preserved"
    "No FEM execution"
    "No strain field generated"
    "Input classes frozen"
    "Raman nuisance terms preserved"
    "Execution unlock criteria written"
    ];
pass = [
    sourceClean
    phase19AClosed
    true
    femBlocked
    true
    true
    true
    height(criteria) > 0
    ];
status = pass_fail(pass);
note = [
    "Canonical specification freeze requires clean pre-run source state."
    "Phase 19B starts from the Phase 19A readiness gate."
    "The phase writes a contract, not numerical mechanics."
    "FEM remains blocked by missing registration/materials inputs."
    "No displacement or strain tensor map is produced."
    "Measured, literature-constrained, and unknown inputs are separated."
    "Raman shifts retain doping, thickness, interface, optical, temperature, and offset nuisances."
    "Phase 19C must recover inputs before execution can unlock."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(gateSummary, criteria)
allPass = all(gateSummary.pass);
femAllowed = lookup_criterion_pass(criteria, "FEM_execution_allowed");
item = [
    "phase19B_closure"
    "phase19B_status"
    "FEM_execution_allowed"
    "strain_tensor_generated"
    "first_executable_tensor_scope"
    "raman_forward_model_status"
    "transport_model_changed"
    "next_phase"
    ];
value = [
    ternary(allPass, "pass_specification_only_no_FEM_execution", ...
        "fail_mechanical_specification_freeze")
    "quantitative_mechanical_model_specification_frozen"
    string(femAllowed)
    "false"
    "epsilon_xx_epsilon_yy_epsilon_xy_after_unlock"
    "specified_with_nonstrain_nuisance_terms"
    "false"
    "phase19C_mechanical_input_and_registration_recovery"
    ];
note = [
    "Closure confirms model architecture is frozen without execution."
    "The future mechanics contract is written."
    "Execution remains false until all unlock criteria pass."
    "No strain tensor or device strain field is generated in Phase 19B."
    "First executable generation targets in-plane strain components only."
    "Raman shifts are not automatically interpreted as strain."
    "Mred_PB_geometry_basis remains unchanged."
    "Next phase should recover quantitative registration and missing mechanical inputs."
    ];
handoff = table(item, value, note);
end

function h = plot_summary(paths, inputClassification, criteria, gateSummary)
h = figure('Name', 'v8 Phase 19B quantitative mechanics spec', ...
    'Color', 'w', 'Position', [100 100 1450 850]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
classes = categorical(inputClassification.input_class);
bar(categorical(categories(classes)), countcats(classes));
title('input classes');
xtickangle(35);
grid on;

nexttile;
bar(categorical(criteria.criterion), double(criteria.pass));
title('execution unlock criteria');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
bar(categorical(gateSummary.component), double(gateSummary.pass));
title('phase gates');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
axis off;
text(0, 0.86, 'Future mechanics map', 'FontWeight', 'bold', ...
    'FontSize', 13);
text(0, 0.68, 'geometry + stack + stress + interface', 'FontSize', 11);
text(0, 0.52, 'u(x,y,z) -> epsilon(x,y,z)', 'FontSize', 11);
text(0, 0.36, 'first scope: eps_xx, eps_yy, eps_xy', 'FontSize', 11);

nexttile;
axis off;
text(0, 0.86, 'Raman observable', 'FontWeight', 'bold', ...
    'FontSize', 13);
text(0, 0.68, 'Delta omega = K:epsilon + nuisance', ...
    'FontSize', 11);
text(0, 0.50, 'doping, thickness, interface, optical', ...
    'FontSize', 11);
text(0, 0.34, 'temperature, calibration offsets', ...
    'FontSize', 11);

nexttile;
axis off;
text(0, 0.86, 'Phase 19B status', 'FontWeight', 'bold', ...
    'FontSize', 13);
text(0, 0.68, 'specification only', 'FontSize', 11);
text(0, 0.52, 'FEM execution allowed: false', 'FontSize', 11);
text(0, 0.36, 'next: Phase 19C input recovery', 'FontSize', 11);

exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end

function value = lookup_item(T, key)
value = "";
if isempty(T)
    return;
end
names = string(T.Properties.VariableNames);
if ismember("item", names)
    idx = find(string(T.item) == string(key), 1);
elseif ismember("component", names)
    idx = find(string(T.component) == string(key), 1);
else
    return;
end
if isempty(idx)
    return;
end
if ismember("value", names)
    value = string(T.value(idx));
elseif ismember("status", names)
    value = string(T.status(idx));
end
end

function tf = lookup_criterion_pass(criteria, key)
idx = find(string(criteria.criterion) == string(key), 1);
tf = ~isempty(idx) && logical(criteria.pass(idx));
end

function status = pass_fail(pass)
status = strings(size(pass));
status(pass) = "pass";
status(~pass) = "fail";
end

function value = ternary(condition, ifTrue, ifFalse)
if condition
    value = string(ifTrue);
else
    value = string(ifFalse);
end
end
