function out = run_phase18A_bidirectional_sweep_protocol(cfg)
%RUN_PHASE18A_BIDIRECTIONAL_SWEEP_PROTOCOL Freeze the top Phase 18 protocol.
%
% Phase 18A turns the top-ranked Phase 18 measurement into a bounded data
% acquisition/import specification. It does not alter the released model,
% retune parameters, rerun solvers, or fit hysteresis/thermal dynamics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

protocol = build_protocol(cfg, inputs);
sweepRateMatrix = build_sweep_rate_matrix();
metadataSchema = build_metadata_schema();
acceptanceCriteria = build_acceptance_criteria();
noFitPolicy = build_no_fit_policy();
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    protocol, sweepRateMatrix, metadataSchema, acceptanceCriteria, ...
    noFitPolicy);
handoffStatus = build_handoff_status(cfg, gateSummary, protocol);

writetable(protocol, cfg.phase18A.protocolFile);
writetable(sweepRateMatrix, cfg.phase18A.sweepRateMatrixFile);
writetable(metadataSchema, cfg.phase18A.metadataSchemaFile);
writetable(acceptanceCriteria, cfg.phase18A.acceptanceCriteriaFile);
writetable(noFitPolicy, cfg.phase18A.noFitPolicyFile);
writetable(gateSummary, cfg.phase18A.gateSummaryFile);
writetable(handoffStatus, cfg.phase18A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase18A.sourceProvenanceFile);

try
    h = v800.plot_phase18A_bidirectional_sweep_protocol_summary( ...
        cfg, protocol, sweepRateMatrix, metadataSchema, ...
        acceptanceCriteria, noFitPolicy, gateSummary);
catch ME
    warning('v8:phase18APlotFailed', ...
        'Phase 18A summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.sourceProvenance = sourceProvenance;
out.protocol = protocol;
out.sweepRateMatrix = sweepRateMatrix;
out.metadataSchema = metadataSchema;
out.acceptanceCriteria = acceptanceCriteria;
out.noFitPolicy = noFitPolicy;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.protocol = cfg.phase18A.protocolFile;
paths.sweepRateMatrix = cfg.phase18A.sweepRateMatrixFile;
paths.metadataSchema = cfg.phase18A.metadataSchemaFile;
paths.acceptanceCriteria = cfg.phase18A.acceptanceCriteriaFile;
paths.noFitPolicy = cfg.phase18A.noFitPolicyFile;
paths.gateSummary = cfg.phase18A.gateSummaryFile;
paths.handoffStatus = cfg.phase18A.handoffStatusFile;
paths.sourceProvenance = cfg.phase18A.sourceProvenanceFile;
paths.figurePng = [cfg.phase18A.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase18A.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase18Handoff = read_required_table(cfg.phase18.handoffStatusFile);
inputs.phase18Ranking = read_required_table(cfg.phase18.experimentRankingFile);
inputs.phase18Recommendation = read_required_table( ...
    cfg.phase18.recommendationFreezeFile);
inputs.phase18Targets = read_required_table(cfg.phase18.unresolvedTargetsFile);
end

function T = read_required_table(pathValue)
if exist(pathValue, 'file') ~= 2
    error('Required Phase 18A input is missing: %s', pathValue);
end
T = readtable(pathValue, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
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
    ];
value = [
    "phase18A_bidirectional_sweep_protocol"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "protocol_freeze_no_solver_rerun"
    ];
note = [
    "Protocol freeze for the top Phase 18 near-term measurement."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before output generation."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when source tree is fully clean before output generation."
    "No model update, fitting, parameter retuning, or solver execution."
    ];
provenance = table(item, value, note);
end

function protocol = build_protocol(cfg, inputs)
selectedId = string(cfg.phase18A.selectedExperimentId);
idx = inputs.phase18Ranking.experiment_id == selectedId;
if nnz(idx) ~= 1
    error('Expected exactly one %s row in Phase 18 ranking, found %d.', ...
        selectedId, nnz(idx));
end

rankRow = inputs.phase18Ranking(idx, :);
phase18Closure = lookup_value(inputs.phase18Handoff, "phase18_closure");

item = [
    "phase18A_closure"
    "phase18_closure_consumed"
    "selected_experiment_id"
    "selected_measurement"
    "phase18_rank"
    "primary_discrimination_target"
    "priority_devices"
    "required_channels"
    "current_sweep_requirement"
    "sweep_rate_requirement"
    "temperature_requirement"
    "field_requirement"
    "raw_grid_requirement"
    "allowed_use"
    "blocked_use"
    "next_phase"
    ];
value = [
    "pass_bidirectional_sweep_protocol_freeze"
    phase18Closure
    selectedId
    string(rankRow.candidate_measurement)
    string(rankRow.rank)
    string(rankRow.primary_target)
    "AS001|AS004|AS006"
    "R1|R2_when_available"
    "positive_and_negative_current_sweeps_with_direction_labels"
    "at_least_three_rates_spanning_slow_nominal_fast"
    "same_temperature_grid_or_declared_interpolation_policy"
    "zero_field_required; optional_field_repeats_recorded_separately"
    "raw_I_T_channel_matrices_plus_axis_vectors_and_checksums"
    "thermal_retrapping_identifiability_and_sweep_history_lock"
    "no_hysteresis_fit_no_new_thermal_model_no_parameter_retuning"
    string(cfg.phase18A.nextPhase)
    ];
note = [
    "Phase 18A freezes the acquisition/import protocol only."
    "Phase 18 must remain closed and consumed."
    "Top near-term experiment from Phase 18 ranking."
    "Measurement family selected by value per difficulty."
    "Rank inherited from Phase 18, not recomputed here."
    "Target remains an unresolved limitation, not a model claim."
    "AS001/AS004 test raw nonlinear switching; AS006 links field context."
    "Channels must not be relabeled or independently fitted."
    "Sweep direction is required for retrapping and hysteresis evidence."
    "Rate series is required to distinguish static switching from dynamics."
    "Temperature handling must be fixed before analysis."
    "This is not a field-model refit."
    "Raw data must be reproducible and machine-readable."
    "Outputs are future-data readiness artifacts."
    "Phase 18A cannot rescue prior model limitations by extra flexibility."
    "Execution/import happens only after the protocol is frozen."
    ];
protocol = table(item, value, note);
end

function matrix = build_sweep_rate_matrix()
device = [
    "AS001"; "AS001"; "AS001"
    "AS004"; "AS004"; "AS004"
    "AS006"; "AS006"; "AS006"
    ];
sweep_rate_tier = repmat(["slow"; "nominal"; "fast"], 3, 1);
current_direction = repmat("up_and_down", numel(device), 1);
required_channels = repmat("R1|R2_when_available", numel(device), 1);
temperature_role = [
    "lowT_and_transition"; "lowT_and_transition"; "lowT_and_transition"
    "lowT_and_transition"; "lowT_and_transition"; "lowT_and_transition"
    "lowT_transition_and_field_reference"; "lowT_transition_and_field_reference"; "lowT_transition_and_field_reference"
    ];
holdout_role = [
    "rate_transfer_holdout"; "training_reference"; "rate_transfer_holdout"
    "rate_transfer_holdout"; "training_reference"; "rate_transfer_holdout"
    "field_context_holdout"; "training_reference"; "field_context_holdout"
    ];
required = true(numel(device), 1);
matrix = table(device, sweep_rate_tier, current_direction, ...
    required_channels, temperature_role, holdout_role, required);
end

function schema = build_metadata_schema()
field = [
    "device_id"
    "raw_file_path"
    "raw_file_sha256"
    "measurement_channel"
    "current_axis_A"
    "temperature_axis_K"
    "sweep_direction"
    "sweep_rate_A_per_s"
    "source_meter_range"
    "voltage_compliance"
    "field_T"
    "zero_current_index"
    "matrix_orientation"
    "units"
    "timestamp_or_run_id"
    ];
required = [
    true; true; true; true; true; true; true; true; ...
    true; true; false; true; true; true; true
    ];
accepted_values = [
    "AS001|AS004|AS006"
    "absolute_or_repository_relative_path"
    "hex_sha256"
    "R1|R2|declared_single_channel"
    "monotonic_or_signed_axis_vector"
    "axis_vector_or_declared_temperature_point"
    "up|down|bidirectional_segment"
    "positive_numeric"
    "declared_instrument_range"
    "declared_voltage_limit_or_nan_if_not_set"
    "numeric; zero_field_for_primary_protocol"
    "positive_integer"
    "current_by_temperature|temperature_by_current"
    "A|K|Ohm_or_dVdI_units"
    "stable_identifier"
    ];
schema = table(field, required, accepted_values);
end

function criteria = build_acceptance_criteria()
criterion = [
    "phase18_recommendation_consumed"
    "bidirectional_sweeps_present"
    "at_least_three_sweep_rates"
    "R1_R2_channel_identity_locked"
    "temperature_axis_locked"
    "raw_checksums_recorded"
    "no_probe_relabeling"
    "no_parameter_fit"
    "thermal_trigger_predeclared"
    "heldout_rate_policy_declared"
    ];
required_result = [
    "pass"; "pass"; "pass"; "pass"; "pass"; ...
    "pass"; "pass"; "pass"; "pass"; "pass"
    ];
note = [
    "Protocol must derive from Phase 18 ranking."
    "Up and down branches are required for hysteresis/retrapping."
    "Rate dependence is the primary new observable."
    "R1/R2 cannot become independent model channels."
    "Temperature coordinates must be stable before analysis."
    "Raw provenance is mandatory."
    "No channel fallback or relabeling is allowed."
    "18A freezes design only; no fitting occurs."
    "Criteria for optional 14C-like thermal extension are declared first."
    "One or more sweep-rate tiers must remain held out."
    ];
criteria = table(criterion, required_result, note);
end

function policy = build_no_fit_policy()
item = [
    "model_family"
    "new_mechanism"
    "parameter_retuning"
    "solver_rerun"
    "thermal_feedback_fit"
    "sweep_rate_fit"
    "probe_relabeling"
    "allowed_analysis"
    "interpretation_limit"
    ];
status = [
    "closed_historical_input"
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "metadata_and_protocol_only"
    "future_data_can_test_limitations_not_rewrite_release"
    ];
policy = table(item, status);
end

function gates = build_gate_summary(cfg, inputs, sourceProvenance, protocol, ...
    sweepRateMatrix, metadataSchema, acceptanceCriteria, noFitPolicy)
phase18Closure = lookup_value(inputs.phase18Handoff, "phase18_closure");
selectedId = string(cfg.phase18A.selectedExperimentId);
selectedRows = inputs.phase18Ranking.experiment_id == selectedId;
selectedRank = NaN;
if nnz(selectedRows) == 1
    selectedRank = str2double(string(inputs.phase18Ranking.rank(selectedRows)));
end

gate = strings(0, 1);
outcome = strings(0, 1);
condition = false(0, 1);
note = strings(0, 1);

[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Phase 18 closure consumed", ...
    phase18Closure == string(cfg.phase18A.requiredClosure), ...
    "Phase 18A consumes the closed experimental-design optimization.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Top-ranked E05 selected", nnz(selectedRows) == 1 && ...
    selectedRank == 1, ...
    "The frozen protocol targets Phase 18 rank-1 near-term experiment.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Protocol emitted", height(protocol) >= 10, ...
    "A machine-readable protocol table is available.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Sweep-rate matrix emitted", height(sweepRateMatrix) == 9, ...
    "Three sweep-rate tiers are declared for AS001, AS004, and AS006.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Required metadata schema emitted", ...
    sum(metadataSchema.required) >= 12, ...
    "The raw-data metadata required for future import is declared.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Acceptance criteria emitted", height(acceptanceCriteria) >= 8, ...
    "Future data lock gates are declared before data inspection.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No-fit policy emitted", height(noFitPolicy) >= 8, ...
    "The phase blocks model rescue by extra flexibility.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No new mechanism", cfg.phase18A.noNewMechanism, ...
    "Phase 18A freezes protocol only.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No parameter retuning", cfg.phase18A.noParameterRetuning, ...
    "No released model parameter is changed.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "No solver rerun", cfg.phase18A.noSolverRerun, ...
    "No transport or field solver is rerun.");
[gate, outcome, condition, note] = add_gate(gate, outcome, condition, ...
    note, "Clean provenance", ...
    lookup_value(sourceProvenance, "source_pre_run_clean") == "true", ...
    "Source tree was clean before output generation.");

gates = table(gate, outcome, condition, note);
end

function [gate, outcome, condition, note] = add_gate(gate, outcome, ...
    condition, note, gateName, tf, gateNote)
gate(end + 1, 1) = string(gateName);
condition(end + 1, 1) = logical(tf);
if tf
    outcome(end + 1, 1) = "pass";
else
    outcome(end + 1, 1) = "fail";
end
note(end + 1, 1) = string(gateNote);
end

function handoff = build_handoff_status(cfg, gateSummary, protocol)
allPass = all(gateSummary.outcome == "pass");
if allPass
    closure = "pass_bidirectional_sweep_protocol_freeze";
else
    closure = "fail_bidirectional_sweep_protocol_freeze";
end

item = [
    "phase18A_closure"
    "workflow_integrity"
    "selected_experiment_id"
    "selected_measurement"
    "model_status"
    "future_data_status"
    "next_phase"
    ];
value = [
    closure
    passfail(allPass)
    string(cfg.phase18A.selectedExperimentId)
    lookup_value(protocol, "selected_measurement")
    "closed_not_reopened"
    "protocol_frozen_data_not_yet_acquired"
    string(cfg.phase18A.nextPhase)
    ];
handoff = table(item, value);
end

function value = lookup_value(T, key)
keyCols = ["item"; "field"; "gate"; "criterion"];
valueCols = ["value"; "status"; "outcome"; "condition"];
keyCol = "";
for k = 1:numel(keyCols)
    if ismember(keyCols(k), string(T.Properties.VariableNames))
        keyCol = keyCols(k);
        break
    end
end
if keyCol == ""
    error('No key column found while looking up %s.', key);
end

idx = string(T.(keyCol)) == string(key);
if ~any(idx)
    idx = strcmpi(strtrim(string(T.(keyCol))), string(key));
end
if nnz(idx) ~= 1
    error('Expected exactly one %s row, found %d.', key, nnz(idx));
end

valueCol = "";
for k = 1:numel(valueCols)
    if ismember(valueCols(k), string(T.Properties.VariableNames))
        valueCol = valueCols(k);
        break
    end
end
if valueCol == ""
    error('No value column found while looking up %s.', key);
end
value = strtrim(string(T.(valueCol)(idx)));
end

function s = passfail(tf)
if tf
    s = "pass";
else
    s = "fail";
end
end
