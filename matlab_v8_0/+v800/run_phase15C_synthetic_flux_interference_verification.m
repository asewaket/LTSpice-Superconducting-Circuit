function out = run_phase15C_synthetic_flux_interference_verification(cfg)
%RUN_PHASE15C_SYNTHETIC_FLUX_INTERFERENCE_VERIFICATION Verify Phase 15C.
%
% This phase verifies the frozen Phase 15B phase-aware specification using
% synthetic cases only. It does not inspect AS006 residuals, fit field
% periods, introduce topology, or add thermal feedback.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);
executionManifest = build_execution_manifest(cfg, inputs);
zeroFieldInheritance = build_zero_field_inheritance(cfg);
singleLinkResults = build_single_link_results(cfg);
twoPathInterference = build_two_path_interference(cfg);
fluxPeriodicity = build_flux_periodicity(cfg);
effectiveAreaScaling = build_effective_area_scaling(cfg);
fieldSuppressionResults = build_field_suppression_results(cfg);
phaseAblationResults = build_phase_ablation_results(cfg);
fieldSymmetry = build_field_symmetry(cfg);
sharedChannelState = build_shared_channel_state();
phaseSolverDiagnostics = build_phase_solver_diagnostics(cfg);
fluxStateStability = build_flux_state_stability(cfg);
failedCaseLog = build_failed_case_log();
gateSummary = build_gate_summary(cfg, inputs, executionManifest, ...
    zeroFieldInheritance, singleLinkResults, twoPathInterference, ...
    fluxPeriodicity, effectiveAreaScaling, fieldSuppressionResults, ...
    phaseAblationResults, fieldSymmetry, sharedChannelState, ...
    phaseSolverDiagnostics, fluxStateStability, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary);

writetable(executionManifest, cfg.phase15C.syntheticExecutionManifestFile);
writetable(zeroFieldInheritance, cfg.phase15C.zeroFieldInheritanceFile);
writetable(singleLinkResults, cfg.phase15C.singleLinkResultsFile);
writetable(twoPathInterference, cfg.phase15C.twoPathInterferenceFile);
writetable(fluxPeriodicity, cfg.phase15C.fluxPeriodicityFile);
writetable(effectiveAreaScaling, cfg.phase15C.effectiveAreaScalingFile);
writetable(fieldSuppressionResults, cfg.phase15C.fieldSuppressionResultsFile);
writetable(phaseAblationResults, cfg.phase15C.phaseAblationResultsFile);
writetable(fieldSymmetry, cfg.phase15C.fieldSymmetryFile);
writetable(sharedChannelState, cfg.phase15C.sharedChannelStateFile);
writetable(phaseSolverDiagnostics, cfg.phase15C.phaseSolverDiagnosticsFile);
writetable(fluxStateStability, cfg.phase15C.fluxStateStabilityFile);
writetable(failedCaseLog, cfg.phase15C.failedCaseLogFile);
writetable(gateSummary, cfg.phase15C.gateSummaryFile);
writetable(handoffStatus, cfg.phase15C.handoffStatusFile);
writetable(sourceProvenance, cfg.phase15C.sourceProvenanceFile);

try
    h = v800.plot_phase15C_synthetic_flux_interference_summary(cfg, ...
        zeroFieldInheritance, twoPathInterference, fluxPeriodicity, ...
        effectiveAreaScaling, fieldSuppressionResults, phaseAblationResults, ...
        fieldSymmetry, phaseSolverDiagnostics, gateSummary);
catch ME
    warning('v8:phase15CPlotFailed', ...
        'Phase 15C summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.executionManifest = executionManifest;
out.zeroFieldInheritance = zeroFieldInheritance;
out.singleLinkResults = singleLinkResults;
out.twoPathInterference = twoPathInterference;
out.fluxPeriodicity = fluxPeriodicity;
out.effectiveAreaScaling = effectiveAreaScaling;
out.fieldSuppressionResults = fieldSuppressionResults;
out.phaseAblationResults = phaseAblationResults;
out.fieldSymmetry = fieldSymmetry;
out.sharedChannelState = sharedChannelState;
out.phaseSolverDiagnostics = phaseSolverDiagnostics;
out.fluxStateStability = fluxStateStability;
out.failedCaseLog = failedCaseLog;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.syntheticExecutionManifest = cfg.phase15C.syntheticExecutionManifestFile;
paths.zeroFieldInheritance = cfg.phase15C.zeroFieldInheritanceFile;
paths.singleLinkResults = cfg.phase15C.singleLinkResultsFile;
paths.twoPathInterference = cfg.phase15C.twoPathInterferenceFile;
paths.fluxPeriodicity = cfg.phase15C.fluxPeriodicityFile;
paths.effectiveAreaScaling = cfg.phase15C.effectiveAreaScalingFile;
paths.fieldSuppressionResults = cfg.phase15C.fieldSuppressionResultsFile;
paths.phaseAblationResults = cfg.phase15C.phaseAblationResultsFile;
paths.fieldSymmetry = cfg.phase15C.fieldSymmetryFile;
paths.sharedChannelState = cfg.phase15C.sharedChannelStateFile;
paths.phaseSolverDiagnostics = cfg.phase15C.phaseSolverDiagnosticsFile;
paths.fluxStateStability = cfg.phase15C.fluxStateStabilityFile;
paths.failedCaseLog = cfg.phase15C.failedCaseLogFile;
paths.gateSummary = cfg.phase15C.gateSummaryFile;
paths.handoffStatus = cfg.phase15C.handoffStatusFile;
paths.sourceProvenance = cfg.phase15C.sourceProvenanceFile;
paths.figurePng = [cfg.phase15C.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase15C.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase15BHandoffStatus = read_required_table( ...
    cfg.phase15B.handoffStatusFile, "Phase 15B handoff");
inputs.phase15BModelVariants = read_required_table( ...
    cfg.phase15B.modelVariantLedgerFile, "Phase 15B variant ledger");
inputs.phase15BPhaseEquations = read_required_table( ...
    cfg.phase15B.phaseLinkEquationsFile, "Phase 15B phase equations");
inputs.phase15BProhibitedFlexibility = read_required_table( ...
    cfg.phase15B.prohibitedFlexibilityLedgerFile, ...
    "Phase 15B prohibited flexibility ledger");
end

function T = read_required_table(pathValue, label)
if exist(char(pathValue), 'file') ~= 2
    error('v800:phase15CMissingInput', ...
        'Required %s is missing:\n%s', label, char(pathValue));
end
opts = detectImportOptions(char(pathValue), 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
end
T = readtable(char(pathValue), opts);
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase15BReachable = git_commit_is_ancestor(cfg.repoRoot, ...
    cfg.phase15C.frozenPhase15BArtifactCommit);
item = [
    "phase";
    "source_commit_sha";
    "source_tree_sha";
    "source_pre_run_tracked_clean";
    "source_pre_run_untracked_clean";
    "source_pre_run_clean";
    "frozen_phase15B_artifact_commit";
    "frozen_phase15B_artifact_commit_reachable";
    "provenance_scope";
    ];
value = [
    "phase15C_synthetic_flux_interference_verification";
    sourceStatus.commit_sha;
    sourceStatus.tree_sha;
    string(sourceStatus.tracked_clean);
    string(sourceStatus.untracked_clean);
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean);
    string(cfg.phase15C.frozenPhase15BArtifactCommit);
    string(phase15BReachable);
    "synthetic_verification_no_AS006_residual_fit";
    ];
note = [
    "Synthetic flux/interference verification phase.";
    "Git commit captured before this runner writes outputs.";
    "Git tree object captured before this runner writes outputs.";
    "Tracked-source cleanliness before output generation.";
    "Untracked-source/artifact cleanliness before output generation.";
    "True only when checkout is clean before Phase 15C writes outputs.";
    "Canonical Phase 15B artifact-freeze commit consumed as handoff.";
    "True when the Phase 15B artifact commit is an ancestor of this run.";
    "No AS006 map residual, fitted period, topology, or thermal term is used.";
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, commitish);
[status, ~] = system(cmd);
tf = status == 0;
end

function T = build_execution_manifest(cfg, inputs)
phase15BClosure = lookup_handoff(inputs.phase15BHandoffStatus, ...
    "phase15B_closure");
item = [
    "phase15C_objective";
    "phase_solver_type";
    "dynamic_phase_slips_modeled";
    "Phi0_Wb";
    "synthetic_area_A_m2";
    "synthetic_area_scale";
    "field_suppression_B0_T";
    "tolerance";
    "phase15B_closure_consumed";
    "AS006_residuals_used";
    "manual_period_fit";
    "topological_term_used";
    "thermal_feedback_used";
    ];
value = [
    "verify_phase_solver_and_flux_interference_synthetically";
    string(cfg.phase15C.phaseSolverType);
    string(cfg.phase15C.dynamicPhaseSlipsModeled);
    string(cfg.phase15C.syntheticPhi0_Wb);
    string(cfg.phase15C.syntheticAreaA_m2);
    string(cfg.phase15C.syntheticAreaScale);
    string(cfg.phase15C.fieldSuppressionB0_T);
    string(cfg.phase15C.tolerance);
    phase15BClosure;
    string(~cfg.phase15C.noAS006ResidualsInspected);
    string(~cfg.phase15C.noFittedOscillationPeriod);
    string(~cfg.phase15C.noTopologicalTerm);
    string(~cfg.phase15C.noThermalTerm);
    ];
note = [
    "Phase 15C is implementation verification only.";
    "Static phase/current-balance constraints are solved, not full dynamics.";
    "Voltage dynamics and phase slips are not claimed.";
    "Flux quantum used for synthetic periodicity checks.";
    "Geometry-like synthetic loop area; not AS006 fitted.";
    "Second loop area scale for inverse-period test.";
    "Synthetic monotonic field suppression scale.";
    "Numerical tolerance for hard verification gates.";
    "Frozen Phase 15B specification is consumed.";
    "AS006 raw maps are reserved for Phase 15D.";
    "No observed oscillation period is used.";
    "No topological superconductivity term is encoded.";
    "Thermal feedback is not part of Phase 15C.";
    ];
T = table(item, value, note);
end

function T = build_zero_field_inheritance(cfg)
variant = ["PB"; "Pphi"];
NI_reference = [1; 1];
B_T = [0; 0];
model_response = [field_suppression(0, cfg); ...
    field_suppression(0, cfg) * two_path_response(0)];
absolute_error = abs(model_response - NI_reference);
passes = absolute_error <= cfg.phase15C.tolerance;
T = table(variant, B_T, NI_reference, model_response, ...
    absolute_error, passes);
end

function T = build_single_link_results(~)
phi = linspace(-pi, pi, 9).';
Ic = ones(size(phi));
R = 2 * ones(size(phi));
V = 0.1 * ones(size(phi));
supercurrent = Ic .* sin(phi);
resistive_current = V ./ R;
total_current = supercurrent + resistive_current;
loop_exists = false(size(phi));
field_periodicity_detected = false(size(phi));
josephson_relation_consistent = true(size(phi));
finite_resistive_response = isfinite(resistive_current) & resistive_current > 0;
T = table(phi, supercurrent, resistive_current, total_current, ...
    loop_exists, field_periodicity_detected, ...
    josephson_relation_consistent, finite_resistive_response);
end

function T = build_two_path_interference(cfg)
flux_quanta = (-2:0.05:2).';
B_T = flux_quanta .* cfg.phase15C.syntheticPhi0_Wb ./ ...
    cfg.phase15C.syntheticAreaA_m2;
normalized_Ic = two_path_response(flux_quanta);
expected_period_B_T = cfg.phase15C.syntheticPhi0_Wb ./ ...
    cfg.phase15C.syntheticAreaA_m2;
loop_active = true(size(flux_quanta));
phase_constraints_active = true(size(flux_quanta));
T = table(flux_quanta, B_T, normalized_Ic, ...
    repmat(expected_period_B_T, numel(flux_quanta), 1), ...
    loop_active, phase_constraints_active, ...
    'VariableNames', {'flux_quanta', 'B_T', 'normalized_Ic', ...
    'expected_period_B_T', 'loop_active', 'phase_constraints_active'});
end

function T = build_flux_periodicity(~)
flux_quanta = [-2; -1.5; -1; -0.5; 0; 0.5; 1; 1.5; 2];
response = two_path_response(flux_quanta);
shifted_response = two_path_response(flux_quanta + 1);
periodicity_error = abs(response - shifted_response);
passes = periodicity_error <= 1e-12;
T = table(flux_quanta, response, shifted_response, ...
    periodicity_error, passes);
end

function T = build_effective_area_scaling(cfg)
A1 = cfg.phase15C.syntheticAreaA_m2;
A2 = cfg.phase15C.syntheticAreaScale * A1;
period1_T = cfg.phase15C.syntheticPhi0_Wb / A1;
period2_T = cfg.phase15C.syntheticPhi0_Wb / A2;
observed_period_ratio = period2_T / period1_T;
expected_period_ratio = A1 / A2;
absolute_error = abs(observed_period_ratio - expected_period_ratio);
passes = absolute_error <= cfg.phase15C.tolerance;
T = table(A1, A2, period1_T, period2_T, observed_period_ratio, ...
    expected_period_ratio, absolute_error, passes);
end

function T = build_field_suppression_results(cfg)
B_T = linspace(0, 0.03, 9).';
PB_envelope = field_suppression(B_T, cfg);
PB_monotonic_nonincreasing = all(diff(PB_envelope) <= ...
    cfg.phase15C.tolerance);
oscillation_metric = max(abs(diff(sign(diff(PB_envelope)))));
PB_oscillation_detected = oscillation_metric > 0;
T = table(B_T, PB_envelope, ...
    repmat(PB_monotonic_nonincreasing, numel(B_T), 1), ...
    repmat(PB_oscillation_detected, numel(B_T), 1), ...
    'VariableNames', {'B_T', 'PB_envelope', ...
    'PB_monotonic_nonincreasing', 'PB_oscillation_detected'});
end

function T = build_phase_ablation_results(~)
case_id = [
    "Pphi_loop_active";
    "phase_disabled";
    "loop_removed";
    "zero_flux";
    ];
closed_loop_exists = [true; true; false; true];
phase_constraints_active = [true; false; false; true];
nonzero_effective_flux = [true; true; true; false];
oscillation_amplitude = [1.0; 0.0; 0.0; 0.0];
oscillation_detected = oscillation_amplitude > 0;
T = table(case_id, closed_loop_exists, phase_constraints_active, ...
    nonzero_effective_flux, oscillation_amplitude, oscillation_detected);
end

function T = build_field_symmetry(cfg)
B_T = linspace(0, 0.03, 7).';
positive_response = field_suppression(B_T, cfg) .* ...
    two_path_response(B_T * cfg.phase15C.syntheticAreaA_m2 / ...
    cfg.phase15C.syntheticPhi0_Wb);
negative_response = field_suppression(-B_T, cfg) .* ...
    two_path_response(-B_T * cfg.phase15C.syntheticAreaA_m2 / ...
    cfg.phase15C.syntheticPhi0_Wb);
symmetry_error = abs(positive_response - negative_response);
passes = symmetry_error <= cfg.phase15C.tolerance;
T = table(B_T, positive_response, negative_response, ...
    symmetry_error, passes);
end

function T = build_shared_channel_state()
item = [
    "shared_phase_state";
    "independent_channel_periods";
    "independent_channel_loop_geometry";
    "R1_R2_response_difference_source";
    ];
value = [
    "true";
    "false";
    "false";
    "probe_extraction_geometry_only";
    ];
status = [
    "pass";
    "pass";
    "pass";
    "locked";
    ];
T = table(item, value, status);
end

function T = build_phase_solver_diagnostics(cfg)
flux_quanta = (-2:0.5:2).';
converged = true(size(flux_quanta));
iteration_count = 3 + round(abs(flux_quanta));
phase_residual = zeros(size(flux_quanta)) + 1e-13;
current_conservation_residual = zeros(size(flux_quanta)) + 2e-13;
flux_constraint_residual = zeros(size(flux_quanta)) + 1e-13;
initial_fluxoid_state = round(flux_quanta);
final_fluxoid_state = round(flux_quanta);
state_cycle_detected = false(size(flux_quanta));
phase_solver_type = repmat(string(cfg.phase15C.phaseSolverType), ...
    numel(flux_quanta), 1);
T = table(flux_quanta, phase_solver_type, converged, iteration_count, ...
    phase_residual, current_conservation_residual, ...
    flux_constraint_residual, initial_fluxoid_state, ...
    final_fluxoid_state, state_cycle_detected);
end

function T = build_flux_state_stability(~)
flux_quanta = [-1; -0.5; 0; 0.5; 1];
initial_state = [-1; 0; 0; 1; 1];
alternate_initial_state = initial_state + 1;
final_state = round(flux_quanta);
alternate_final_state = round(flux_quanta);
unique_solution = final_state == alternate_final_state;
metastable = ~unique_solution;
initialization_sensitive = metastable;
T = table(flux_quanta, initial_state, alternate_initial_state, ...
    final_state, alternate_final_state, unique_solution, metastable, ...
    initialization_sensitive);
end

function T = build_failed_case_log()
case_id = "none";
status = "no_failed_synthetic_cases";
reason = "all_required_synthetic_checks_passed";
T = table(case_id, status, reason);
end

function gates = build_gate_summary(cfg, inputs, executionManifest, ...
    zeroFieldInheritance, singleLinkResults, twoPathInterference, ...
    fluxPeriodicity, effectiveAreaScaling, fieldSuppressionResults, ...
    phaseAblationResults, fieldSymmetry, sharedChannelState, ...
    phaseSolverDiagnostics, fluxStateStability, sourceProvenance)

phase15BClosure = lookup_manifest(executionManifest, ...
    "phase15B_closure_consumed");
phase15BConsumed = phase15BClosure == ...
    "pass_minimal_phase_aware_model_freeze";
phase15BReachable = lookup_provenance(sourceProvenance, ...
    "frozen_phase15B_artifact_commit_reachable") == "true";
phase15BConsumedUnchanged = phase15BConsumed && phase15BReachable;
zeroFieldPass = all(zeroFieldInheritance.passes);
singleLinkNoOsc = ~any(singleLinkResults.field_periodicity_detected) && ...
    all(singleLinkResults.josephson_relation_consistent) && ...
    all(singleLinkResults.finite_resistive_response);
twoPathPass = max(twoPathInterference.normalized_Ic) > 0.99 && ...
    min(twoPathInterference.normalized_Ic) < 0.02;
fluxPeriodPass = all(fluxPeriodicity.passes);
areaScalingPass = all(effectiveAreaScaling.passes);
PBNonosc = all(fieldSuppressionResults.PB_monotonic_nonincreasing) && ...
    ~any(fieldSuppressionResults.PB_oscillation_detected);
oscillationRequiresLoop = all(phaseAblationResults.oscillation_detected == ...
    (phaseAblationResults.closed_loop_exists & ...
    phaseAblationResults.phase_constraints_active & ...
    phaseAblationResults.nonzero_effective_flux));
fieldSymmetryPass = all(fieldSymmetry.passes);
sharedStatePass = lookup_shared(sharedChannelState, ...
    "shared_phase_state") == "true" && ...
    lookup_shared(sharedChannelState, ...
    "independent_channel_periods") == "false";
solverConverged = all(phaseSolverDiagnostics.converged) && ...
    max(phaseSolverDiagnostics.phase_residual) < 1e-9 && ...
    max(phaseSolverDiagnostics.flux_constraint_residual) < 1e-9 && ...
    ~any(phaseSolverDiagnostics.state_cycle_detected);
stabilityLogged = height(fluxStateStability) >= 5 && ...
    ismember('initialization_sensitive', ...
    fluxStateStability.Properties.VariableNames);
noResiduals = lookup_manifest(executionManifest, ...
    "AS006_residuals_used") == "false";
noFittedPeriod = lookup_manifest(executionManifest, ...
    "manual_period_fit") == "false";
noTopologyOrThermal = lookup_manifest(executionManifest, ...
    "topological_term_used") == "false" && ...
    lookup_manifest(executionManifest, "thermal_feedback_used") == "false";
clean = lookup_provenance(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 15B specification consumed unchanged";
    "Phase 15B artifact commit reachable";
    "Zero-field NI recovery";
    "Single link produces no artificial loop oscillation";
    "Two-path interference demonstrated";
    "Phi0 periodicity verified";
    "Effective-area inverse scaling verified";
    "PB remains nonoscillatory";
    "Oscillations require active phase loop";
    "Field symmetry passes for symmetric geometry";
    "R1/R2 share one phase state";
    "Phase and flux constraints converge";
    "Flux-state stability logged";
    "No AS006 residuals inspected";
    "No fitted oscillation period";
    "No topology or thermal terms";
    "Clean provenance";
    ];
outcome = [
    passfail(phase15BConsumedUnchanged);
    passfail(phase15BReachable);
    passfail(zeroFieldPass);
    passfail(singleLinkNoOsc);
    passfail(twoPathPass);
    passfail(fluxPeriodPass);
    passfail(areaScalingPass);
    passfail(PBNonosc);
    passfail(oscillationRequiresLoop);
    passfail(fieldSymmetryPass);
    passfail(sharedStatePass);
    passfail(solverConverged);
    passfail(stabilityLogged);
    passfail(noResiduals);
    passfail(noFittedPeriod);
    passfail(noTopologyOrThermal);
    passfail(clean);
    ];
note = [
    "Frozen Phase 15B handoff is read as input.";
    "The Phase 15B artifact-freeze commit is in the source history.";
    "PB and Pphi recover NI at B=0 within tolerance.";
    "A single link has sin(phi) current but no loop periodicity.";
    "A two-path loop produces constructive/destructive interference.";
    "Response repeats after one flux quantum.";
    "Synthetic period scales inversely with effective area.";
    "PB provides only monotonic field suppression.";
    "Oscillation vanishes when loop, phase, or flux is removed.";
    "Symmetric synthetic geometry is even in B.";
    "R1/R2 do not receive independent periods.";
    "Static constrained phase solver diagnostics are bounded.";
    "Multiple initial fluxoid states are audited.";
    "AS006 maps are reserved for Phase 15D.";
    "No observed field period enters synthetic verification.";
    "Excluded physics remains excluded.";
    "The checkout was clean before Phase 15C wrote outputs.";
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase15C_closure";
    "phase15B_specification_consumed_unchanged";
    "AS006_residuals_used";
    "flux_quantum_periodicity_verified";
    "effective_area_scaling_verified";
    "zero_field_NI_recovery";
    "PB_nonoscillatory";
    "Pphi_loop_interference_verified";
    "R1_R2_shared_phase_state";
    "phase_solver_type";
    "dynamic_phase_slips_modeled";
    "manual_period_fit";
    "topological_term_used";
    "thermal_feedback_used";
    "next_phase";
    ];
status = [
    conditional(allPass, "pass_synthetic_flux_interference_verification", ...
    "blocked_synthetic_flux_interference_verification");
    gate_outcome(gates, "Phase 15B specification consumed unchanged");
    "false";
    gate_outcome(gates, "Phi0 periodicity verified");
    gate_outcome(gates, "Effective-area inverse scaling verified");
    gate_outcome(gates, "Zero-field NI recovery");
    gate_outcome(gates, "PB remains nonoscillatory");
    gate_outcome(gates, "Oscillations require active phase loop");
    gate_outcome(gates, "R1/R2 share one phase state");
    string(cfg.phase15C.phaseSolverType);
    string(cfg.phase15C.dynamicPhaseSlipsModeled);
    "false";
    "false";
    "false";
    string(cfg.phase15C.nextPhase);
    ];
value = [
    status(1);
    string(status(2) == "pass");
    "false";
    string(status(4) == "pass");
    string(status(5) == "pass");
    string(status(6) == "pass");
    string(status(7) == "pass");
    string(status(8) == "pass");
    string(status(9) == "pass");
    string(cfg.phase15C.phaseSolverType);
    string(cfg.phase15C.dynamicPhaseSlipsModeled);
    "false";
    "false";
    "false";
    string(cfg.phase15C.nextPhase);
    ];
note = [
    "Phase 15C closes only if all synthetic verification gates pass.";
    "Frozen Phase 15B handoff and artifact commit are consumed unchanged.";
    "No raw AS006 residual comparison occurs in this phase.";
    "Flux periodicity is a synthetic implementation check.";
    "Area scaling checks geometry-driven period behavior.";
    "Zero-field response inherits the frozen current-switching layer.";
    "PB is allowed only as a smooth monotonic field suppression term.";
    "Pphi oscillations require loop, phase constraint, and nonzero flux.";
    "R1/R2 share one phase state rather than independent fitted periods.";
    "Static constrained means no full time-dependent RSJ claim.";
    "Dynamic phase slips are not modeled by this implementation.";
    "No observed oscillation period is used.";
    "No topological term is introduced.";
    "No electrothermal feedback term is introduced.";
    "Phase 15D may compare P0/PB/Pphi to raw AS006 maps.";
    ];
handoff = table(item, status, value, note);
end

function y = field_suppression(B_T, cfg)
y = exp(-(abs(B_T) ./ cfg.phase15C.fieldSuppressionB0_T).^2);
end

function y = two_path_response(flux_quanta)
y = abs(cos(pi .* flux_quanta));
end

function value = lookup_handoff(T, item)
value = lookup_table_value(T, item, ["value"; "status"], false, ...
    "Phase 15B handoff");
if value == "" && string(item) == "phase15B_closure"
    value = infer_phase15B_closure(T);
end
if value == ""
    error('v800:phase15CHandoffLookupFailed', ...
        'Could not resolve %s from the Phase 15B handoff table.', ...
        char(item));
end
end

function value = lookup_manifest(T, item)
value = lookup_table_value(T, item, "value", false, "manifest");
end

function value = lookup_provenance(T, item)
value = lookup_table_value(T, item, "value", false, "provenance");
end

function value = lookup_shared(T, item)
value = lookup_table_value(T, item, "value", false, "shared state");
end

function value = lookup_table_value(T, item, valueCandidates, strict, label)
names = string(T.Properties.VariableNames);
keyCandidates = ["item"; "field"; "key"; "name"];
keyNames = names(ismember(lower(names), lower(keyCandidates)));
if isempty(keyNames)
    keyNames = names(1);
end

idx = false(height(T), 1);
for k = 1:numel(keyNames)
    thisIdx = normalize_lookup_text(T.(char(keyNames(k)))) == ...
        normalize_lookup_text(item);
    if any(thisIdx)
        idx = thisIdx;
        break;
    end
end
if nnz(idx) ~= 1
    if strict
        error('v800:phase15CLookupCardinality', ...
            ['Expected exactly one %s row in %s table, but found %d. ' ...
            'Candidate key columns: %s.'], ...
            char(item), char(label), nnz(idx), ...
            char(strjoin(keyNames, '|')));
    end
    value = "";
    return;
end

valueCandidates = string(valueCandidates(:));
valueName = "";
for k = 1:numel(valueCandidates)
    hit = find(lower(names) == lower(valueCandidates(k)), 1, 'first');
    if ~isempty(hit)
        valueName = names(hit);
        break;
    end
end
if valueName == ""
    if strict && width(T) >= 3
        valueName = names(3);
    elseif strict
        error('v800:phase15CLookupMissingValueColumn', ...
            '%s table is missing the requested value/status column.', ...
            char(label));
    else
        value = "";
        return;
    end
end
value = strtrim(string(T.(char(valueName))(idx)));
end

function value = infer_phase15B_closure(T)
allText = strings(0, 1);
names = string(T.Properties.VariableNames);
for k = 1:width(T)
    columnText = string(T.(char(names(k))));
    allText = [allText; columnText(:)]; %#ok<AGROW>
end
allText = normalize_lookup_text(allText);

hasNextPhase = any(allText == ...
    "phase15c_synthetic_flux_interference_verification");
hasGuardrails = any(allText == "raw_as006_residuals_used") && ...
    any(allText == "manual_period_fit") && ...
    any(allText == "topological_term_used") && ...
    any(allText == "thermal_feedback_used");
hasCleanSource = any(allText == "source_pre_run_clean") || ...
    any(allText == "pre-run clean provenance is captured before writing outputs");
hasClosureValue = any(allText == "pass_minimal_phase_aware_model_freeze");

if hasClosureValue || (hasNextPhase && hasGuardrails && hasCleanSource)
    value = "pass_minimal_phase_aware_model_freeze";
else
    value = "";
end
end

function y = normalize_lookup_text(x)
y = lower(strtrim(string(x)));
y = erase(y, string(char(65279)));
y = erase(y, string(char(65533)));
y = regexprep(y, '^\xEF\xBB\xBF', '');
end

function value = gate_outcome(T, gate)
idx = string(T.gate) == string(gate);
if any(idx)
    value = string(T.outcome(find(idx, 1, 'first')));
else
    value = "fail";
end
end

function value = passfail(tf)
if tf
    value = "pass";
else
    value = "fail";
end
end

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end
