function out = run_phase18_experimental_design_optimization(cfg)
%RUN_PHASE18_EXPERIMENTAL_DESIGN_OPTIMIZATION Rank next measurements.
%
% Phase 18 is a post-release planning phase. It consumes the closed Phase 17
% release boundary and turns the preserved limitations into experimental
% discrimination targets. It does not rerun transport solvers, retune model
% parameters, or introduce a new mechanism into the frozen model family.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

unresolvedTargets = build_unresolved_targets();
candidateLibrary = build_candidate_experiment_library();
informationGain = build_information_gain_scores(candidateLibrary);
experimentRanking = build_experiment_ranking(candidateLibrary, informationGain);
recommendationFreeze = build_recommendation_freeze(experimentRanking);
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    unresolvedTargets, candidateLibrary, informationGain, ...
    experimentRanking, recommendationFreeze);
handoffStatus = build_handoff_status(gateSummary, recommendationFreeze);

writetable(unresolvedTargets, cfg.phase18.unresolvedTargetsFile);
writetable(candidateLibrary, cfg.phase18.candidateLibraryFile);
writetable(informationGain, cfg.phase18.informationGainFile);
writetable(experimentRanking, cfg.phase18.experimentRankingFile);
writetable(recommendationFreeze, cfg.phase18.recommendationFreezeFile);
writetable(gateSummary, cfg.phase18.gateSummaryFile);
writetable(handoffStatus, cfg.phase18.handoffStatusFile);
writetable(sourceProvenance, cfg.phase18.sourceProvenanceFile);

try
    h = v800.plot_phase18_experimental_design_optimization_summary( ...
        cfg, unresolvedTargets, candidateLibrary, informationGain, ...
        experimentRanking, recommendationFreeze, gateSummary);
catch ME
    warning('v8:phase18PlotFailed', ...
        'Phase 18 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.sourceProvenance = sourceProvenance;
out.unresolvedTargets = unresolvedTargets;
out.candidateLibrary = candidateLibrary;
out.informationGain = informationGain;
out.experimentRanking = experimentRanking;
out.recommendationFreeze = recommendationFreeze;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.unresolvedTargets = cfg.phase18.unresolvedTargetsFile;
paths.candidateLibrary = cfg.phase18.candidateLibraryFile;
paths.informationGain = cfg.phase18.informationGainFile;
paths.experimentRanking = cfg.phase18.experimentRankingFile;
paths.recommendationFreeze = cfg.phase18.recommendationFreezeFile;
paths.gateSummary = cfg.phase18.gateSummaryFile;
paths.handoffStatus = cfg.phase18.handoffStatusFile;
paths.sourceProvenance = cfg.phase18.sourceProvenanceFile;
paths.figurePng = [cfg.phase18.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase18.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase17Handoff = read_required_table(cfg.phase17.handoffStatusFile);
inputs.phase17ReleaseBoundary = read_required_table( ...
    cfg.phase17.releaseBoundaryManifestFile);
inputs.phase17FinalClaims = read_required_table( ...
    cfg.phase17.finalClaimTableFile);
inputs.phase17FutureQueue = read_required_table( ...
    cfg.phase17.futureWorkQueueFile);
inputs.phase16ELimitations = read_required_table( ...
    cfg.phase16E.limitationLedgerFile);
end

function T = read_required_table(pathValue)
if exist(pathValue, 'file') ~= 2
    error('Required Phase 18 input is missing: %s', pathValue);
end
T = readtable(pathValue, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase17Commit = string(cfg.phase18.frozenPhase17ArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase17_artifact_commit"
    "frozen_phase17_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase18_experimental_design_optimization"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    phase17Commit
    string(git_commit_is_ancestor(cfg.repoRoot, phase17Commit))
    "read_only_design_optimization_no_solver_rerun"
    ];
note = [
    "Experimental-design phase after the closed Phase 17 release boundary."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before output generation."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when source tree is fully clean before output generation."
    "Clean Phase 17 artifact-freeze commit."
    "True when Phase 17 artifact commit is in history."
    "No new mechanism, parameter retuning, solver rerun, or claim reopening."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commit)
[status, ~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repoRoot, commit));
tf = status == 0;
end

function targets = build_unresolved_targets()
target_id = [
    "T01_boundary_vs_coverage"
    "T02_boundary_vs_crack"
    "T03_boundary_vs_Ic0"
    "T04_Tc_vs_coverage"
    "T05_absolute_strain_tensor"
    "T06_microscopic_weak_link_location"
    "T07_field_suppression_vs_interference"
    "T08_Josephson_vs_vortex_dynamics"
    "T09_order_parameter_symmetry"
    "T10_thermal_or_retrapping_dynamics"
    ];
ambiguity = [
    "W_boundary versus W_coverage"
    "W_boundary versus W_crack"
    "W_boundary versus global Ic0"
    "Tc heterogeneity versus W_coverage"
    "Absolute/local strain tensor"
    "Microscopic weak-link locations"
    "Conventional field suppression versus limited coherent interference"
    "Josephson switching versus vortex-mediated dynamics"
    "Order-parameter symmetry"
    "Electrothermal or retrapping dynamics"
    ];
target_class = [
    "connectivity"
    "connectivity"
    "connectivity_current"
    "local_Tc_connectivity"
    "mechanical"
    "spatial_localization"
    "field_response"
    "dynamic_nonlinear"
    "microscopic"
    "dynamic_nonlinear"
    ];
current_status = repmat("unresolved_after_phase17", numel(target_id), 1);
needed_observable = [
    "additional voltage probes or orthogonal current injection"
    "crack-aware probes, imaging, or deliberate notch geometry"
    "multi-current geometry and nonlinear Ic constraints"
    "registered Raman plus transport and designed controls"
    "registered polarization Raman and elasticity model"
    "local magnetic/current imaging or dense probe array"
    "field-angle sweeps and held-out AS006 field maps"
    "up/down sweeps, sweep-rate dependence, or microwave response"
    "phase-sensitive spectroscopy beyond transport-only maps"
    "up/down sweeps with retrapping and sweep-rate metadata"
    ];
targets = table(target_id, ambiguity, target_class, current_status, ...
    needed_observable);
end

function library = build_candidate_experiment_library()
experiment_id = [
    "E01_extra_voltage_probes"
    "E02_orthogonal_current_injection"
    "E03_designed_stressor_geometries"
    "E04_registered_Raman_transport"
    "E05_bidirectional_sweep_rate"
    "E06_field_angle_sweep"
    "E07_microwave_response"
    "E08_local_magnetic_current_imaging"
    "E09_polarization_resolved_Raman"
    ];
candidate_measurement = [
    "Additional voltage-probe configurations"
    "Parallel and perpendicular current injection"
    "Purpose-designed stressor/control geometries"
    "Registered Raman plus transport"
    "Bidirectional current sweeps with sweep-rate series"
    "Field sweep direction and angle dependence"
    "Microwave response"
    "Local magnetic or current imaging"
    "Polarization-resolved registered Raman"
    ];
measurement_family = [
    "transport_geometry"
    "transport_geometry"
    "device_design"
    "multimodal_registration"
    "nonlinear_dynamics"
    "field_response"
    "phase_dynamics"
    "spatial_imaging"
    "mechanical_Raman"
    ];
primary_target = [
    "W_boundary_vs_W_coverage"
    "W_boundary_vs_W_coverage"
    "boundary_coverage_crack_controls"
    "strain_connectivity_coupling"
    "thermal_retrapping_identifiability"
    "field_suppression_vs_interference"
    "Josephson_dynamics"
    "weak_link_or_vortex_localization"
    "strain_tensor"
    ];
experimental_difficulty = [2; 2; 3; 3; 2; 3; 5; 5; 4];
near_term_feasible = [true; true; true; true; true; true; false; false; true];
uses_released_model_only = true(numel(experiment_id), 1);
requires_new_physics = false(numel(experiment_id), 1);
notes = [
    "Most direct low-complexity path to spatial connectivity sensitivity."
    "Tests boundary bottlenecks by changing current direction."
    "Creates clean mechanism-discrimination devices rather than patching fits."
    "Turns Raman from contextual evidence into a registered mechanical constraint."
    "Makes thermal, retrapping, and hysteretic switching identifiable."
    "Separates monotonic suppression, angular anisotropy, and interference."
    "Direct Josephson test; high value but not near-term low difficulty."
    "Powerful localization test; high experimental burden."
    "Best route toward strain tensor rather than scalar Raman proxy."
    ];
library = table(experiment_id, candidate_measurement, measurement_family, ...
    primary_target, experimental_difficulty, near_term_feasible, ...
    uses_released_model_only, requires_new_physics, notes);
end

function scores = build_information_gain_scores(library)
parameter_id = [
    "W_boundary"
    "W_coverage"
    "W_crack"
    "Ic0"
    "Tc_heterogeneity"
    "field_suppression"
    "phase_interference"
    "thermal_dynamic"
    "strain_tensor"
    "microscopic_order"
    ];

J = [
    0.85 0.80 0.45 0.10 0.30 0.00 0.00 0.00 0.00 0.00
    0.95 0.70 0.40 0.20 0.25 0.00 0.00 0.00 0.00 0.00
    0.85 0.95 0.75 0.25 0.40 0.00 0.00 0.00 0.00 0.00
    0.65 0.55 0.35 0.10 0.85 0.10 0.00 0.00 0.95 0.15
    0.00 0.00 0.00 0.65 0.00 0.00 0.20 1.00 0.00 0.00
    0.10 0.10 0.00 0.20 0.00 0.85 0.70 0.10 0.00 0.00
    0.00 0.00 0.00 0.20 0.00 0.20 0.95 0.70 0.00 0.40
    0.75 0.55 0.85 0.15 0.10 0.25 0.45 0.25 0.00 0.10
    0.10 0.20 0.05 0.00 0.55 0.00 0.00 0.00 1.00 0.25
    ];

Fcurrent = diag([0.25 0.22 0.20 0.25 0.28 0.22 0.18 0.16 0.12 0.08]);
Fcurrent = set_pair(Fcurrent, parameter_id, ...
    "W_boundary", "W_coverage", 0.10);
Fcurrent = set_pair(Fcurrent, parameter_id, ...
    "W_boundary", "W_crack", 0.08);
Fcurrent = set_pair(Fcurrent, parameter_id, ...
    "W_boundary", "Ic0", 0.07);
Fcurrent = set_pair(Fcurrent, parameter_id, ...
    "Tc_heterogeneity", "W_coverage", 0.07);
Fcurrent = ensure_spd(Fcurrent, 1e-8);

n = height(library);
current_condition_number = zeros(n, 1);
new_condition_number = zeros(n, 1);
sigma_min_current = zeros(n, 1);
sigma_min_new = zeros(n, 1);
posterior_volume_ratio = zeros(n, 1);
boundary_coverage_corr_before = zeros(n, 1);
boundary_coverage_corr_after = zeros(n, 1);
targeted_degeneracy_reduction = zeros(n, 1);
information_gain_score = zeros(n, 1);

eigCurrent = eig((Fcurrent + Fcurrent.') ./ 2);
currentCondition = max(eigCurrent) ./ min(eigCurrent);
currentSigmaMin = min(eigCurrent);
currentCov = inv(Fcurrent);
rhoBefore = corr_from_cov(currentCov, parameter_id, ...
    "W_boundary", "W_coverage");
logDetCurrent = logdet_spd(Fcurrent);

for k = 1:n
    j = J(k, :).';
    strength = 1.0 ./ sqrt(double(library.experimental_difficulty(k)));
    Fnew = ensure_spd(Fcurrent + strength .* (j * j.'), 1e-8);
    eigNew = eig((Fnew + Fnew.') ./ 2);
    newCov = inv(Fnew);

    current_condition_number(k) = currentCondition;
    new_condition_number(k) = max(eigNew) ./ min(eigNew);
    sigma_min_current(k) = currentSigmaMin;
    sigma_min_new(k) = min(eigNew);
    posterior_volume_ratio(k) = exp(logDetCurrent - logdet_spd(Fnew));
    boundary_coverage_corr_before(k) = rhoBefore;
    boundary_coverage_corr_after(k) = corr_from_cov(newCov, parameter_id, ...
        "W_boundary", "W_coverage");
    targeted_degeneracy_reduction(k) = abs(rhoBefore) - ...
        abs(boundary_coverage_corr_after(k));
    information_gain_score(k) = 0.35 .* (1 - posterior_volume_ratio(k)) + ...
        0.30 .* (sigma_min_new(k) ./ currentSigmaMin - 1) + ...
        0.25 .* targeted_degeneracy_reduction(k) + ...
        0.10 .* double(library.near_term_feasible(k));
end

scores = table(library.experiment_id, current_condition_number, ...
    new_condition_number, sigma_min_current, sigma_min_new, ...
    posterior_volume_ratio, boundary_coverage_corr_before, ...
    boundary_coverage_corr_after, targeted_degeneracy_reduction, ...
    information_gain_score, 'VariableNames', ...
    ["experiment_id", "condition_number_current", ...
    "condition_number_new", "sigma_min_current", "sigma_min_new", ...
    "posterior_volume_ratio", "rho_boundary_coverage_current", ...
    "rho_boundary_coverage_new", "targeted_degeneracy_reduction", ...
    "information_gain_score"]);
end

function F = set_pair(F, parameterId, a, b, value)
ia = find(parameterId == a, 1);
ib = find(parameterId == b, 1);
F(ia, ib) = value;
F(ib, ia) = value;
end

function rho = corr_from_cov(C, parameterId, a, b)
ia = find(parameterId == a, 1);
ib = find(parameterId == b, 1);
rho = C(ia, ib) ./ sqrt(C(ia, ia) .* C(ib, ib));
end

function y = logdet_spd(A)
A = ensure_spd(A, 1e-9);
R = chol(A);
y = 2 .* sum(log(diag(R)));
end

function A = ensure_spd(A, minEigenvalue)
A = (A + A.') ./ 2;
e = eig(A);
if min(e) < minEigenvalue
    A = A + (minEigenvalue - min(e)) .* eye(size(A));
end
end

function ranking = build_experiment_ranking(library, informationGain)
score = informationGain.information_gain_score ./ ...
    double(library.experimental_difficulty);
[~, order] = sort(score, 'descend');
rank = (1:height(library)).';
ranking = table(rank, library.experiment_id(order), ...
    library.candidate_measurement(order), library.primary_target(order), ...
    informationGain.information_gain_score(order), ...
    library.experimental_difficulty(order), score(order), ...
    library.near_term_feasible(order), ...
    'VariableNames', ["rank", "experiment_id", ...
    "candidate_measurement", "primary_target", ...
    "information_gain_score", "experimental_difficulty", ...
    "value_per_difficulty", "near_term_feasible"]);
end

function freeze = build_recommendation_freeze(ranking)
item = [
    "phase18_closure"
    "highest_value_near_term"
    "highest_value_transport_only"
    "highest_value_dynamic_test"
    "highest_value_phase_test"
    "highest_value_strain_tensor_test"
    "released_model_status"
    "next_phase"
    ];
value = [
    "pass_experimental_design_optimization"
    first_match(ranking, "near_term_feasible", true)
    "additional_voltage_probes_or_orthogonal_current_injection"
    "bidirectional_current_sweeps_with_sweep_rate"
    "field_angle_sweep_then_microwave_if_needed"
    "registered_polarization_Raman_plus_elasticity_model"
    "closed_not_reopened"
    "phase19_quantitative_mechanical_strain_model_if_new_data_available"
    ];
note = [
    "Phase 18 ranks experiments without changing the closed model."
    "Best near-term option by value-per-difficulty planning score."
    "Transport-only path for spatial-connectivity discrimination."
    "Dynamic path if sweep-history metadata can be collected."
    "Field-response path before any stronger phase claim."
    "Route toward a strain tensor rather than a scalar proxy."
    "Phase 17 release boundary remains historical input."
    "Future phase is conditional on new data, not a patch to v9."
    ];
freeze = table(item, value, note);
end

function value = first_match(T, fieldName, expectedValue)
mask = T.(fieldName) == expectedValue;
idx = find(mask, 1);
if isempty(idx)
    value = "";
else
    value = T.candidate_measurement(idx);
end
end

function gates = build_gate_summary(cfg, inputs, sourceProvenance, ...
    unresolvedTargets, candidateLibrary, informationGain, ...
    experimentRanking, recommendationFreeze)
gate = strings(0, 1);
outcome = strings(0, 1);
condition = false(0, 1);
note = strings(0, 1);

[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Phase 17 closure consumed", ...
    lookup_value(inputs.phase17Handoff, "phase17_closure") == ...
    "pass_final_release_future_work_handoff", ...
    "Phase 18 consumes the clean Phase 17 release boundary.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Phase 17 artifact commit reachable", ...
    lookup_value(sourceProvenance, ...
    "frozen_phase17_artifact_commit_reachable") == "true", ...
    "The Phase 17 artifact freeze is reachable from this run.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Released model not reopened", ...
    lookup_value(inputs.phase17Handoff, "release_boundary") == ...
    "closed_after_phase16E", ...
    "The closed model remains historical input.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Unresolved targets emitted", height(unresolvedTargets) >= 8, ...
    "The preserved degeneracies are converted into explicit targets.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Candidate experiment library emitted", ...
    height(candidateLibrary) >= 8, ...
    "The candidate measurement library is available.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Information gain scores emitted", ...
    height(informationGain) == height(candidateLibrary), ...
    "Each candidate experiment receives an information-gain proxy.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Experiment ranking emitted", ...
    height(experimentRanking) == height(candidateLibrary), ...
    "Candidates are ranked by value per difficulty.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Recommendations frozen", ...
    lookup_value(recommendationFreeze, "phase18_closure") == ...
    "pass_experimental_design_optimization", ...
    "The recommendation handoff is machine-readable.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No new mechanism", cfg.phase18.noNewMechanism, ...
    "Phase 18 does not add model physics.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No parameter retuning", cfg.phase18.noParameterRetuning, ...
    "Phase 18 does not retune model parameters.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No solver rerun", cfg.phase18.noSolverRerun, ...
    "Phase 18 does not rerun transport solvers.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Future work separated from release", ...
    lookup_value(inputs.phase17Handoff, "future_work_status") == ...
    "optional_targeted_work_only", ...
    "Future work remains outside the closed release.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Clean provenance", ...
    lookup_value(sourceProvenance, "source_pre_run_clean") == "true", ...
    "Source tree was clean before output generation.");

gates = table(gate, outcome, condition, note);
end

function [gate, outcome, condition, note] = add_gate(gate, outcome, ...
    condition, note, name, tf, gateNote)
gate(end + 1, 1) = string(name);
condition(end + 1, 1) = logical(tf);
if tf
    outcome(end + 1, 1) = "pass";
else
    outcome(end + 1, 1) = "fail";
end
note(end + 1, 1) = string(gateNote);
end

function handoff = build_handoff_status(gateSummary, recommendationFreeze)
allPass = all(string(gateSummary.outcome) == "pass");
item = [
    "phase18_closure"
    "workflow_integrity"
    "released_model_status"
    "highest_value_near_term"
    "highest_value_transport_only"
    "highest_value_dynamic_test"
    "next_phase"
    ];
if allPass
    closure = "pass_experimental_design_optimization";
    integrity = "pass";
else
    closure = "fail_experimental_design_optimization";
    integrity = "fail";
end
value = [
    closure
    integrity
    "closed_not_reopened"
    lookup_value(recommendationFreeze, "highest_value_near_term")
    lookup_value(recommendationFreeze, "highest_value_transport_only")
    lookup_value(recommendationFreeze, "highest_value_dynamic_test")
    lookup_value(recommendationFreeze, "next_phase")
    ];
handoff = table(item, value);
end

function value = lookup_value(T, key)
vars = string(T.Properties.VariableNames);
keyCols = ["item", "gate", "policy_item", "claim_text", "work_item"];
valueCols = ["value", "outcome", "policy_value", "allowed_in_closed_model", ...
    "status"];
keyCol = "";
for c = keyCols
    if any(vars == c)
        keyCol = c;
        break;
    end
end
if keyCol == ""
    value = "";
    return;
end
idx = strcmpi(strtrim(string(T.(keyCol))), string(key));
if nnz(idx) ~= 1
    value = "";
    return;
end
for c = valueCols
    if any(vars == c)
        value = strtrim(string(T.(c)(idx)));
        return;
    end
end
value = "";
end
