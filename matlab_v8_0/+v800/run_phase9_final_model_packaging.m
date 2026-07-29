function out = run_phase9_final_model_packaging(cfg)
%RUN_PHASE9_FINAL_MODEL_PACKAGING Package final v8 model claims without retuning.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase9_inputs(cfg);
frozenInputManifest = build_frozen_input_manifest(cfg);
modelSpecification = build_final_model_specification();
deviceConclusionLedger = build_device_conclusion_ledger(inputs);
evidenceHierarchy = build_evidence_hierarchy();
claimHierarchy = build_claim_hierarchy();
modelLimitations = build_model_limitations();
figureManifest = build_figure_manifest(cfg);
tableManifest = build_table_manifest(cfg);
deferredWork = build_deferred_work();
gateSummary = build_gate_summary(cfg, frozenInputManifest, inputs, ...
    modelSpecification, deviceConclusionLedger, claimHierarchy, ...
    modelLimitations, figureManifest, tableManifest, deferredWork, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance, ...
    inputs);
ramanRegistrationDiagnostic = build_phase7_registration_diagnostic(inputs);

writetable(frozenInputManifest, cfg.phase9.frozenInputManifestFile);
writetable(modelSpecification, cfg.phase9.finalModelSpecificationFile);
writetable(deviceConclusionLedger, cfg.phase9.finalDeviceConclusionLedgerFile);
writetable(evidenceHierarchy, cfg.phase9.evidenceHierarchyFile);
writetable(claimHierarchy, cfg.phase9.claimHierarchyFile);
writetable(modelLimitations, cfg.phase9.modelLimitationsFile);
writetable(figureManifest, cfg.phase9.finalFigureManifestFile);
writetable(tableManifest, cfg.phase9.finalTableManifestFile);
writetable(deferredWork, cfg.phase9.deferredWorkFile);
writetable(gateSummary, cfg.phase9.gateSummaryFile);
writetable(handoffStatus, cfg.phase9.handoffStatusFile);
writetable(sourceProvenance, cfg.phase9.sourceProvenanceFile);
writetable(ramanRegistrationDiagnostic, ...
    cfg.phase9.ramanRegistrationDiagnosticFile);

try
    h = v800.plot_phase9_final_model_package(cfg, deviceConclusionLedger, ...
        evidenceHierarchy, gateSummary);
catch ME
    warning('v8:phase9PlotFailed', ...
        'Phase 9 final model package plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenInputManifest = frozenInputManifest;
out.finalModelSpecification = modelSpecification;
out.finalDeviceConclusionLedger = deviceConclusionLedger;
out.evidenceHierarchy = evidenceHierarchy;
out.claimHierarchy = claimHierarchy;
out.modelLimitations = modelLimitations;
out.finalFigureManifest = figureManifest;
out.finalTableManifest = tableManifest;
out.deferredWork = deferredWork;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.ramanRegistrationDiagnostic = ramanRegistrationDiagnostic;
out.figure = h;
out.paths = struct();
out.paths.frozenInputManifest = cfg.phase9.frozenInputManifestFile;
out.paths.finalModelSpecification = cfg.phase9.finalModelSpecificationFile;
out.paths.finalDeviceConclusionLedger = cfg.phase9.finalDeviceConclusionLedgerFile;
out.paths.evidenceHierarchy = cfg.phase9.evidenceHierarchyFile;
out.paths.claimHierarchy = cfg.phase9.claimHierarchyFile;
out.paths.modelLimitations = cfg.phase9.modelLimitationsFile;
out.paths.finalFigureManifest = cfg.phase9.finalFigureManifestFile;
out.paths.finalTableManifest = cfg.phase9.finalTableManifestFile;
out.paths.deferredWork = cfg.phase9.deferredWorkFile;
out.paths.gateSummary = cfg.phase9.gateSummaryFile;
out.paths.handoffStatus = cfg.phase9.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase9.sourceProvenanceFile;
out.paths.ramanRegistrationDiagnostic = ...
    cfg.phase9.ramanRegistrationDiagnosticFile;
out.paths.figurePng = [cfg.phase9.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase9.figureBaseFile '.pdf'];
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
    "phase9_final_model_packaging"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "final_model_packaging_no_retuning"
    "Commit Phase 9 source/config first; rerun packaging from that source; commit generated artifacts separately."
    ];
note = [
    "Phase 9 final model packaging and claim freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "Read-only packaging of frozen Phase 5D2/6/7B/8 outputs."
    "The artifact commit need not be embedded in files generated before that commit exists."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase9_inputs(cfg)
inputs = struct();
inputs.phase5D2Context = read_optional_table(cfg.phase5D2.realDeviceScoreContextFile);
inputs.phase5D2Synthesis = read_optional_table(cfg.phase5D2.deviceEvidenceSynthesisFile);
inputs.phase5D2Status = read_optional_table(cfg.phase5D2.resultFreezeStatusFile);
inputs.phase5D2Handoff = read_optional_table(cfg.phase5D2.handoffStatusFile);
inputs.phase6Matrix = read_optional_table(cfg.phase6.sixDeviceEvidenceMatrixFile);
inputs.phase6Status = read_optional_table(cfg.phase6.deviceModelStatusFile);
inputs.phase6Gates = read_optional_table(cfg.phase6.gateSummaryFile);
inputs.phase6Handoff = read_optional_table(cfg.phase6.handoffStatusFile);
inputs.phase7BAnnotations = read_optional_table(cfg.phase7B.deviceRobustnessAnnotationFile);
inputs.phase7BGates = read_optional_table(cfg.phase7B.gateSummaryFile);
inputs.phase7BHandoff = read_optional_table(cfg.phase7B.handoffStatusFile);
inputs.phase7BRamanRegistration = read_optional_table( ...
    cfg.phase7B.ramanRegistrationSensitivityFile);
inputs.phase8Gates = read_optional_table(cfg.phase8.gateSummaryFile);
inputs.phase8Handoff = read_optional_table(cfg.phase8.handoffStatusFile);
inputs.phase8BStability = read_optional_table(cfg.phase8B.statusStabilityFile);
inputs.phase8BGates = read_optional_table(cfg.phase8B.gateSummaryFile);
inputs.phase8BHandoff = read_optional_table(cfg.phase8B.handoffStatusFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    try
        T = readtable(pathValue, 'TextType', 'string', ...
            'VariableNamingRule', 'preserve');
    catch
        T = readtable(pathValue, 'TextType', 'string');
    end
else
    T = table();
end
end

function manifest = build_frozen_input_manifest(cfg)
rows = [
    manifest_row("phase5D2_result_freeze_status", ...
    cfg.phase5D2.resultFreezeStatusFile, true, ...
    "Phase 5D2 negative classifier result and evidence policy")
    manifest_row("phase5D2_real_device_score_context", ...
    cfg.phase5D2.realDeviceScoreContextFile, true, ...
    "contextual DeltaS/Z and score context")
    manifest_row("phase5D2_device_evidence_synthesis", ...
    cfg.phase5D2.deviceEvidenceSynthesisFile, true, ...
    "multi-evidence device synthesis before Phase 6")
    manifest_row("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, true, ...
    "frozen six-device hierarchy and evidence matrix")
    manifest_row("phase6_device_model_status", ...
    cfg.phase6.deviceModelStatusFile, true, ...
    "frozen device model statuses")
    manifest_row("phase6_claim_hierarchy", cfg.phase6.claimHierarchyFile, ...
    true, "Phase 6 claim hierarchy")
    manifest_row("phase7B_device_robustness_annotations", ...
    cfg.phase7B.deviceRobustnessAnnotationFile, true, ...
    "geometry and mechanical-mask robustness annotations")
    manifest_row("phase7B_gate_summary", cfg.phase7B.gateSummaryFile, true, ...
    "Phase 7B-G robustness gates")
    manifest_row("phase8_gate_summary", cfg.phase8.gateSummaryFile, true, ...
    "Phase 8A implementation/numerical audit gates")
    manifest_row("phase8B_status_stability_summary", ...
    cfg.phase8B.statusStabilityFile, true, ...
    "frozen-context numerical replay status stability")
    manifest_row("phase8B_gate_summary", cfg.phase8B.gateSummaryFile, true, ...
    "Phase 8B numerical replay gates")
    manifest_row("phase8B_handoff_status", cfg.phase8B.handoffStatusFile, ...
    true, "Phase 8B handoff to final model packaging")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
[manifest.file_size_bytes, manifest.modified_datenum] = ...
    manifest_file_metadata(manifest.path);
manifest.frozen_use = repmat("read_only_final_packaging_no_rescore", ...
    height(manifest), 1);
end

function specification = build_final_model_specification()
rows = [
    spec_row("model_name", ...
    "v8.0 geometry-aware superconducting weak-link network", ...
    "Final frozen framework name.")
    spec_row("model_hierarchy", "M0star, M1, M2", ...
    "Nested phenomenological hierarchy.")
    spec_row("M0star_definition", ...
    "local-Tc heterogeneity plus frozen nuisance envelope", ...
    "Control/local heterogeneity limit; does not prove weak links absent.")
    spec_row("M1_definition", ...
    "local-Tc heterogeneity plus structured boundary/contact/crack connectivity", ...
    "Structured weak-link topology class.")
    spec_row("M2_definition", ...
    "local-Tc heterogeneity plus combined bottleneck structure", ...
    "Strongest combined structured-connectivity class.")
    spec_row("electrical_geometry", ...
    "2D Hall-bar network with longitudinal and transverse links", ...
    "Four-probe network solution rather than 1D current path.")
    spec_row("observables", ...
    "normalized four-probe R(T); paired-probe response where available; selected nonlinear transport evidence; contextual DeltaS and Z", ...
    "Final observable stack.")
    spec_row("mechanical_input", ...
    "geometry-derived boundary/crack masks; Raman used qualitatively unless registered", ...
    "Mechanical field is a proxy, not absolute strain.")
    spec_row("architecture_step_1", "Hall-bar geometry", ...
    "Device geometry and contact/probe layout.")
    spec_row("architecture_step_2", "H(x,y)", ...
    "Local superconducting-strength/mechanical prior field.")
    spec_row("architecture_step_3", "Tc(x,y)", ...
    "Local superconducting transition field generated by geometry and disorder.")
    spec_row("architecture_step_4", "W_ij", ...
    "Weak-link transparency/connectivity field on network links.")
    spec_row("architecture_step_5", "R_4p(T,I,B)", ...
    "Four-probe network transport response in the semi-phenomenological model.")
    spec_row("shunts_and_nuisance", ...
    "normal or incompletely superconducting shunts plus frozen disorder/nuisance envelope", ...
    "Handled as uncertainty and context, not device-specific mechanism fitting.")
    spec_row("retuning_allowed", "false", ...
    "Phase 9 packaging cannot reopen calibration.")
    spec_row("device_specific_mechanism_parameters_allowed", "false", ...
    "Final hierarchy does not use device-specific mechanism parameters.")
    spec_row("universal_classifier_deployable", "false", ...
    "Phase 5D2 established no feasible universal normalized R(T) operating point.")
    ];
specification = struct2table(rows);
end

function ledger = build_device_conclusion_ledger(inputs)
devices = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
rows = repmat(empty_device_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    rows(k).geometry_class = lookup_string(inputs.phase6Matrix, ...
        "device", device, "geometry_class", geometry_class(device));
    rows(k).final_model_status = lookup_string(inputs.phase6Matrix, ...
        "device", device, "final_model_status", final_model_status(device));
    rows(k).evidence_status = lookup_string(inputs.phase6Matrix, ...
        "device", device, "final_evidence_status", final_evidence_status(device));
    rows(k).primary_evidence = lookup_string(inputs.phase6Matrix, ...
        "device", device, "phase5A_primary_result", "not_available");
    rows(k).heldout_evidence = lookup_string(inputs.phase6Matrix, ...
        "device", device, "phase5B1_heldout_result", "not_available");
    rows(k).secondary_probe_evidence = lookup_string(inputs.phase6Matrix, ...
        "device", device, "phase5B_secondary_result", "not_available");
    rows(k).nonlinear_evidence = lookup_string(inputs.phase6Matrix, ...
        "device", device, "nonlinear_evidence", "not_available");
    rows(k).mechanical_geometry_evidence = lookup_string(inputs.phase6Matrix, ...
        "device", device, "geometry_crack_evidence", "not_available");
    rows(k).phase7_prior_annotation = lookup_string(inputs.phase7BAnnotations, ...
        "device", device, "phase7_robustness_annotation", "not_available");
    rows(k).phase8_numerical_annotation = lookup_string(inputs.phase8BStability, ...
        "device", device, "status_stability", "not_available");
    rows(k).contextual_DeltaS = lookup_double(inputs.phase6Matrix, ...
        "device", device, "phase5D2_DeltaS", NaN);
    rows(k).contextual_Z = lookup_double(inputs.phase6Matrix, ...
        "device", device, "phase5D2_Z", NaN);
    rows(k).allowed_device_claim = allowed_device_claim(device);
    rows(k).required_qualification = required_qualification(device);
    rows(k).prohibited_overclaim = prohibited_overclaim(device);
end
ledger = struct2table(rows);
end

function hierarchy = build_evidence_hierarchy()
rows = [
    evidence_row(1, "direct_transport_evidence", ...
    "normalized R(T); paired probe responses; nonlinear I,T,B evidence where available", ...
    "primary physical evidence but not a universal automatic classifier")
    evidence_row(2, "transfer_and_control_evidence", ...
    "Phase 5A primary transfer; Phase 5B secondary evidence; Phase 5B.1 held-out tests; Phase 5B.2 force-law comparisons", ...
    "tests whether shared rules transfer without link-by-link refitting")
    evidence_row(3, "synthetic_identifiability_evidence", ...
    "Phase 5C in-family recovery and misspecification challenge", ...
    "validates scorer structure while preserving out-of-family caveat")
    evidence_row(4, "detection_limit_evidence", ...
    "Phase 5D2 contextual DeltaS/Z and infeasible universal operating point", ...
    "sets confidence limits and prevents automatic categorical labels")
    evidence_row(5, "mechanical_context_evidence", ...
    "stressor geometry; half-coverage boundary; AS005 crack; qualitative Raman context", ...
    "mechanical evidence qualifies, but does not alone override transport")
    evidence_row(6, "robustness_evidence", ...
    "Phase 7 geometry/mask sensitivity and Phase 8 frozen-context numerical replay", ...
    "records status preservation and sensitivity annotations")
    evidence_row(7, "hierarchy_rule", ...
    "no single evidence source overrides the full hierarchy automatically", ...
    "final device status is a multi-evidence synthesis")
    ];
hierarchy = struct2table(rows);
end

function claims = build_claim_hierarchy()
rows = [
    claim_row("framework_level", "permitted", ...
    "A shared geometry-aware 2D superconducting-network framework provides a consistent interpretation of AS001-AS006.", ...
    "Applies to the model family and frozen evidence hierarchy.")
    claim_row("framework_level", "permitted", ...
    "Local superconducting heterogeneity is sufficient for some devices, while structured weak-link connectivity is supported for the strongest cases.", ...
    "Do not turn this into a universal automatic classifier.")
    claim_row("framework_level", "permitted", ...
    "Two-dimensional connectivity and current redistribution are required to interpret stressor boundaries, cracks, and multiple transport paths.", ...
    "This is a network-level claim, not microscopic phase dynamics.")
    claim_row("framework_level", "permitted", ...
    "The device series is governed more strongly by local mechanical boundary conditions than by nominal film force alone.", ...
    "Mechanical field remains geometry-derived and qualitative where Raman is unregistered.")
    claim_row("device_level", "permitted", ...
    "AS002 and AS003 do not require structured connectivity under the frozen evidence framework.", ...
    "Weak links are not proven absent.")
    claim_row("device_level", "permitted", ...
    "AS005 supports a crack-associated structured interpretation.", ...
    "Strong but crack-prior dependent and primary-only qualified.")
    claim_row("device_level", "permitted", ...
    "AS006 provides the strongest structured-connectivity evidence.", ...
    "Comparatively prior/numerically robust within the frozen framework.")
    claim_row("device_level", "permitted", ...
    "AS001 and AS004 remain mechanistically unresolved.", ...
    "No forced assignment.")
    claim_row("limitation", "required", ...
    "Normalized R(T) alone does not provide a deployable universal categorical classifier.", ...
    "Phase 5D2 negative operating-point result.")
    claim_row("limitation", "required", ...
    "Contextual DeltaS and Z are not validated automatic labels.", ...
    "They report directional preference and confidence limits.")
    claim_row("limitation", "required", ...
    "Raman is not a quantitatively registered strain prior in the final model.", ...
    "Registered Raman rescore remains unavailable/deferred.")
    claim_row("limitation", "required", ...
    "The mechanical field is not an absolute local strain reconstruction.", ...
    "Geometry proxy only.")
    claim_row("limitation", "required", ...
    "Phase 8B was a frozen-context score replay, not a full recomputation of every transport observable.", ...
    "Numerical replay scope is limited.")
    claim_row("limitation", "required", ...
    "The model is phenomenological and does not uniquely reconstruct microscopic superconducting domains.", ...
    "No microscopic inversion claim.")
    claim_row("prohibited_claim", "prohibited", ...
    "unique microscopic domain reconstruction", ...
    "Not constrained by measurements.")
    claim_row("prohibited_claim", "prohibited", ...
    "absolute local strain prediction", ...
    "No absolute strain calibration.")
    claim_row("prohibited_claim", "prohibited", ...
    "universal normalized RT mechanism classifier", ...
    "Phase 5D2 shows no feasible universal operating point.")
    claim_row("prohibited_claim", "prohibited", ...
    "proof of Josephson phase dynamics", ...
    "Phase dynamics are outside v8.")
    claim_row("prohibited_claim", "prohibited", ...
    "proof of topological superconductivity", ...
    "Explicitly excluded from model scope.")
    claim_row("prohibited_claim", "prohibited", ...
    "proof of vortex trajectories", ...
    "Vortex dynamics are outside v8.")
    claim_row("prohibited_claim", "prohibited", ...
    "quantitative Raman-constrained transport model", ...
    "Registered Raman transport prior was not run.")
    claim_row("prohibited_claim", "prohibited", ...
    "validated M1 versus M2 classification from RT alone", ...
    "Nested distinction requires multi-evidence qualifications.")
    ];
claims = struct2table(rows);
end

function limitations = build_model_limitations()
rows = [
    limitation_row("mechanical_input", ...
    "Geometry-derived proxy rather than measured absolute strain", ...
    "Qualifies all mechanical-prior language.")
    limitation_row("raman_registration", ...
    "No defensible device-to-model spatial transformation was available; Raman data were not used as a quantitatively registered transport prior", ...
    "Raman remains qualitative independent mechanical context.")
    limitation_row("transport_identifiability", ...
    "Flexible M0star and structured models overlap under misspecification", ...
    "Prevents universal categorical classifier claims.")
    limitation_row("normal_resistance", ...
    "Calibrated rather than independently predicted", ...
    "Normal-state network scale is not a first-principles output.")
    limitation_row("microscopic_physics", ...
    "Scalar resistor network excludes phase, vortex, heating, and microscopic pairing dynamics", ...
    "Do not claim phase-sensitive mechanisms.")
    limitation_row("device_count", ...
    "Six-device series limits broad generalization", ...
    "Claims are series-specific.")
    limitation_row("nonlinear_evidence", ...
    "Uneven availability across devices", ...
    "Nonlinear support is device-qualified.")
    limitation_row("numerical_replay", ...
    "Score-context replay rather than complete solver rerun for every perturbation", ...
    "Phase 8B is a frozen-context robustness check.")
    ];
limitations = struct2table(rows);
end

function manifest = build_figure_manifest(cfg)
rows = [
    figure_row("final_phase9_summary", [cfg.phase9.figureBaseFile '.png'], ...
    "generated_in_phase9", "Final model hierarchy, device conclusions, contextual DeltaS/Z, and gates.")
    figure_row("phase6_hierarchy_summary", [cfg.phase6.figureBaseFile '.png'], ...
    "frozen_input", "Six-device hierarchy and contextual score evidence.")
    figure_row("phase5D2_result_freeze_summary", [cfg.phase5D2.figureBaseFile '.png'], ...
    "frozen_input", "No feasible universal classifier operating point.")
    figure_row("phase7B_geometry_mask_robustness_summary", ...
    [cfg.phase7B.figureBaseFile '.png'], "frozen_input", ...
    "Mechanical-prior and mask robustness annotations.")
    figure_row("phase8B_numerical_replay_summary", ...
    [cfg.phase8B.figureBaseFile '.png'], "frozen_input", ...
    "Frozen-context numerical replay and status stability.")
    ];
manifest = struct2table(rows);
generated = manifest.source_status == "generated_in_phase9";
manifest.exists = generated | ...
    arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
end

function manifest = build_table_manifest(cfg)
rows = [
    table_row("phase9_final_model_specification", ...
    cfg.phase9.finalModelSpecificationFile, "generated_in_phase9", ...
    "Canonical model definition and architecture.")
    table_row("phase9_final_device_conclusion_ledger", ...
    cfg.phase9.finalDeviceConclusionLedgerFile, "generated_in_phase9", ...
    "Thesis-ready six-device conclusion ledger.")
    table_row("phase9_evidence_hierarchy", ...
    cfg.phase9.evidenceHierarchyFile, "generated_in_phase9", ...
    "Final hierarchy of evidence sources.")
    table_row("phase9_claim_hierarchy", ...
    cfg.phase9.claimHierarchyFile, "generated_in_phase9", ...
    "Permitted, required, and prohibited claims.")
    table_row("phase9_model_limitations", ...
    cfg.phase9.modelLimitationsFile, "generated_in_phase9", ...
    "Reusable final limitation ledger.")
    table_row("phase9_deferred_work", ...
    cfg.phase9.deferredWorkFile, "generated_in_phase9", ...
    "Deferred work separated from incomplete requirements.")
    table_row("phase9_raman_registration_disposition", ...
    cfg.phase9.ramanRegistrationDiagnosticFile, "generated_in_phase9", ...
    "Explicit Raman registration disposition used by Phase 9 gates.")
    table_row("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, "frozen_input", ...
    "Frozen hierarchy and contextual scores.")
    table_row("phase7B_device_robustness_annotations", ...
    cfg.phase7B.deviceRobustnessAnnotationFile, "frozen_input", ...
    "Mechanical-prior claim-impact annotations.")
    table_row("phase8B_status_stability_summary", ...
    cfg.phase8B.statusStabilityFile, "frozen_input", ...
    "Numerical replay stability annotations.")
    ];
manifest = struct2table(rows);
generated = manifest.source_status == "generated_in_phase9";
manifest.exists = generated | ...
    arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
end

function deferred = build_deferred_work()
rows = [
    deferred_row("full_shape_RT_classifier", "deferred", ...
    "materially different future classifier study", ...
    "Not needed for v8 final model packaging.")
    deferred_row("registered_raman_transport_prior", "unavailable", ...
    "defensible device-to-model spatial transform", ...
    "Raman remains qualitative until registration is available.")
    deferred_row("full_multiphysics_mechanical_transport_model", ...
    "future_work", "new multiphysics scope and data support", ...
    "Outside semi-phenomenological v8.")
    deferred_row("phase_sensitive_Josephson_model", ...
    "outside_current_scope", "new phase-sensitive measurements", ...
    "Phase dynamics are excluded from v8.")
    deferred_row("full_transport_numerical_recomputation", ...
    "optional_future_validation", "dedicated expensive recomputation campaign", ...
    "Phase 8B used frozen-context replay.")
    ];
deferred = struct2table(rows);
end

function gates = build_gate_summary(cfg, manifest, inputs, modelSpec, ...
    deviceLedger, claimHierarchy, limitations, figureManifest, ...
    tableManifest, deferredWork, sourceProvenance)
phase6Preserved = all_required_present(inputs.phase6Gates, "outcome");
deviceAnnotationsPresent = all_required_present(inputs.phase7BAnnotations, ...
    "device");
registrationDisposition = phase7_registration_disposition(inputs);
phase7Incorporated = deviceAnnotationsPresent && ...
    registrationDisposition.core_gates_passed && ...
    registrationDisposition.registration_accepted;
phase8Incorporated = all_required_present(inputs.phase8BGates, "outcome") && ...
    all_required_present(inputs.phase8BStability, "device");
modelFrozen = height(modelSpec) >= 10 && ...
    has_spec_value(modelSpec, "retuning_allowed", "false") && ...
    has_spec_value(modelSpec, "universal_classifier_deployable", "false");
deviceConclusions = height(deviceLedger) == 6 && ...
    all(strlength(deviceLedger.final_model_status) > 0);
noRetune = ~cfg.phase9.allowModelRetuning;
noExpansion = ~cfg.phase9.allowMechanismExpansion;
claimComplete = any(claimHierarchy.status == "permitted") && ...
    any(claimHierarchy.status == "prohibited") && ...
    any(claimHierarchy.status == "required");
limitationsComplete = height(limitations) >= 8;
figuresTablesSelected = height(figureManifest) >= 4 && ...
    height(tableManifest) >= 8;
deferredSeparated = height(deferredWork) >= 5;
sourceClean = lookup_value(sourceProvenance, "source_pre_run_clean", ...
    "false") == "true";
rows = [
    gate_row("Phase 6 hierarchy preserved", logical_status(phase6Preserved), ...
    "Frozen Phase 6 hierarchy/status files are consumed without relabeling.")
    gate_row("Phase 7 annotations incorporated", logical_status(phase7Incorporated), ...
    "Geometry/mask robustness incorporated; registered Raman rescore explicitly unavailable and retained as qualitative context.")
    gate_row("Phase 8 robustness incorporated", logical_status(phase8Incorporated), ...
    "Phase 8A/8B numerical robustness artifacts are included.")
    gate_row("Model definitions frozen", logical_status(modelFrozen), ...
    "Final model specification includes hierarchy and no-retuning policy.")
    gate_row("Device conclusions frozen", logical_status(deviceConclusions), ...
    "Six-device final status ledger has one row per device.")
    gate_row("No classifier retuning", logical_status(noRetune), ...
    "Phase 9 does not change thresholds, scores, or calibration.")
    gate_row("No mechanism expansion", logical_status(noExpansion), ...
    "Phase 9 does not add a new physics or weak-link class.")
    gate_row("Claim hierarchy complete", logical_status(claimComplete), ...
    "Permitted, required, and prohibited claims are represented.")
    gate_row("Limitations complete", logical_status(limitationsComplete), ...
    "Reusable limitation ledger is complete.")
    gate_row("Final figures/tables selected", logical_status(figuresTablesSelected), ...
    "Final figure and table manifests are written.")
    gate_row("Deferred work separated", logical_status(deferredSeparated), ...
    "Future work is separated from incomplete Phase 9 requirements.")
    gate_row("Clean source provenance", logical_status(sourceClean), ...
    "Passes only when Phase 9 is rerun from a clean source checkout.")
    gate_row("Frozen inputs available", logical_status(all(manifest.exists(manifest.required))), ...
    "All required upstream artifacts exist.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance, inputs)
coreGateNames = [
    "Phase 6 hierarchy preserved"
    "Phase 7 annotations incorporated"
    "Phase 8 robustness incorporated"
    "Model definitions frozen"
    "Device conclusions frozen"
    "No classifier retuning"
    "No mechanism expansion"
    "Claim hierarchy complete"
    "Limitations complete"
    "Final figures/tables selected"
    "Deferred work separated"
    "Frozen inputs available"
    ];
coreRows = ismember(gates.gate, coreGateNames);
ready = all(gates.outcome(coreRows) == "pass");
allGatesReady = all(gates.outcome == "pass");
sourcePreRunClean = lookup_value(sourceProvenance, ...
    "source_pre_run_clean", "unknown");
registrationDisposition = phase7_registration_disposition(inputs);
rows = [
    status_row("phase9_final_model_packaging", logical_status(ready), ...
    "Final v8 model package generated without retuning.")
    status_row("phase9_all_gates", logical_status(allGatesReady), ...
    "Includes the clean-source provenance gate.")
    status_row("phase9_closure", ...
    ternary_status(ready, "pass_final_model_packaging", ...
    "fail_final_model_packaging"), ...
    "Closure ignores no scientific gate; clean provenance may require source commit plus rerun.")
    status_row("model_retuning_performed", "false", ...
    "No model retuning occurred.")
    status_row("device_status_changes", "false", ...
    "Phase 6 device statuses are preserved.")
    status_row("claims_frozen", "true", ...
    "Permitted/prohibited claim hierarchy written.")
    status_row("limitations_frozen", "true", ...
    "Final limitation ledger written.")
    status_row("quantitative_raman_prior_rescore", ...
    registrationDisposition.quantitative_raman_prior_rescore, ...
    "Registered Raman transport prior is not promoted to a quantitative model input.")
    status_row("raman_missingness_handled", ...
    string(registrationDisposition.registration_accepted), ...
    "True only when missing registered Raman evidence has an explicitly accepted disposition.")
    status_row("raman_rescore_reason", ...
    registrationDisposition.raman_rescore_reason, ...
    "Reason registered Raman is quantitative, unavailable, or unresolved.")
    status_row("raman_role", ...
    registrationDisposition.raman_role, ...
    "Final Raman role in the v8 model package.")
    status_row("source_pre_run_clean", sourcePreRunClean, ...
    "Copied from Phase 9 provenance checkpoint.")
    status_row("next_phase", string(cfg.phase9.nextPhase), ...
    "Prepare reproducible v8 release package.")
    ];
handoff = struct2table(rows);
end

function disposition = phase7_registration_disposition(inputs)
registrationStatus = gate_outcome(inputs.phase7BGates, ...
    "Registration robustness", "missing");
missingRegistrationHandled = gate_outcome(inputs.phase7BGates, ...
    "Missing Raman registration handled honestly", "missing");
ramanRowsInsufficient = raman_rows_are_insufficient( ...
    inputs.phase7BRamanRegistration);
coreGateNames = [
    "Phase 6 labels protected"
    "No classifier retuning"
    "Frozen inputs available"
    "Crack sensitivity evaluated"
    "Boundary sensitivity evaluated"
    "Shuffled control evaluated"
    "Prior dependency reported"
    "Missing Raman registration handled honestly"
    ];
corePassed = true;
for k = 1:numel(coreGateNames)
    corePassed = corePassed && ...
        gate_outcome(inputs.phase7BGates, coreGateNames(k), "missing") == "pass";
end

quantitativeRamanRescore = "unknown";
ramanReason = "unknown";
if registrationStatus == "pass"
    quantitativeRamanRescore = "pass";
    ramanReason = "registered_spatial_transform_available";
elseif registrationStatus == "not_run" && ...
        missingRegistrationHandled == "pass"
    quantitativeRamanRescore = "not_run";
    ramanReason = "no_defensible_registered_spatial_transform";
end

registrationAccepted = registrationStatus == "pass" || ...
    (registrationStatus == "not_run" && ...
    missingRegistrationHandled == "pass" && ...
    quantitativeRamanRescore == "not_run" && ...
    ramanReason == "no_defensible_registered_spatial_transform");

disposition = struct();
disposition.registration_status = registrationStatus;
disposition.missing_registration_handled = missingRegistrationHandled;
disposition.quantitative_raman_prior_rescore = quantitativeRamanRescore;
disposition.raman_rescore_reason = ramanReason;
disposition.raman_role = "qualitative_independent_mechanical_context";
disposition.core_gates_passed = corePassed;
disposition.raman_rows_insufficient = ramanRowsInsufficient;
disposition.registration_accepted = registrationAccepted;
end

function diagnostic = build_phase7_registration_diagnostic(inputs)
disposition = phase7_registration_disposition(inputs);
item = [
    "registration_status"
    "missing_registration_handled"
    "raman_rows_insufficient"
    "quantitative_raman_prior_rescore"
    "raman_rescore_reason"
    "raman_role"
    "core_gates_passed"
    "registration_accepted"
    ];
value = [
    disposition.registration_status
    disposition.missing_registration_handled
    string(disposition.raman_rows_insufficient)
    disposition.quantitative_raman_prior_rescore
    disposition.raman_rescore_reason
    disposition.raman_role
    string(disposition.core_gates_passed)
    string(disposition.registration_accepted)
    ];
note = [
    "Phase 7B registration-robustness gate outcome."
    "Phase 7B explicit missing-registration handling gate outcome."
    "True when every Raman-registration row records insufficient registered data."
    "Final Phase 9 disposition for quantitative Raman prior rescore."
    "Reason for Raman prior rescore disposition."
    "Final role of Raman evidence in the v8 model package."
    "True when non-registration Phase 7B core gates pass."
    "True when Phase 9 accepts the Phase 7B Raman disposition."
    ];
diagnostic = table(item, value, note);
end

function tf = raman_rows_are_insufficient(T)
status = table_column(T, "completion_status");
tf = ~isempty(status);
if tf
    tf = all(status == "insufficient_registered_data");
end
end

function outcome = gate_outcome(T, componentName, defaultOutcome)
outcome = string(defaultOutcome);
component = table_column(T, "component");
outcomes = table_column(T, "outcome");
if (isempty(component) || isempty(outcomes)) && width(T) >= 2
    component = table_column_by_index(T, 1);
    outcomes = table_column_by_index(T, 2);
end
if isempty(component) || isempty(outcomes)
    return;
end
idx = component == string(componentName);
if any(idx)
    outcome = outcomes(find(idx, 1, 'first'));
end
end

function tf = all_required_present(T, requiredColumn)
values = table_column(T, requiredColumn);
tf = ~isempty(values);
if tf && string(requiredColumn) == "outcome"
    tf = all(values == "pass");
end
end

function tf = has_spec_value(T, key, expectedValue)
items = table_column(T, "item");
values = table_column(T, "value");
idx = items == string(key);
tf = ~isempty(items) && ~isempty(values) && ...
    any(idx) && any(values(idx) == string(expectedValue));
end

function [bytes, modifiedDatenum] = manifest_file_metadata(paths)
bytes = NaN(numel(paths), 1);
modifiedDatenum = NaN(numel(paths), 1);
for k = 1:numel(paths)
    info = dir(char(paths(k)));
    if ~isempty(info)
        bytes(k) = info(1).bytes;
        modifiedDatenum(k) = info(1).datenum;
    end
end
end

function value = lookup_string(T, keyColumn, keyValue, valueColumn, defaultValue)
value = string(defaultValue);
keys = table_column(T, keyColumn);
values = table_column(T, valueColumn);
if isempty(keys) || isempty(values)
    return;
end
idx = keys == string(keyValue);
if any(idx)
    value = values(find(idx, 1, 'first'));
end
end

function value = lookup_double(T, keyColumn, keyValue, valueColumn, defaultValue)
value = defaultValue;
keys = table_column(T, keyColumn);
values = table_column(T, valueColumn);
if isempty(keys) || isempty(values)
    return;
end
idx = keys == string(keyValue);
if any(idx)
    raw = values(find(idx, 1, 'first'));
    value = double(raw);
end
end

function value = lookup_value(T, itemName, defaultValue)
value = string(defaultValue);
items = table_column(T, "item");
values = table_column(T, "value");
if isempty(items) || isempty(values)
    return;
end
idx = items == string(itemName);
if any(idx)
    value = values(find(idx, 1, 'first'));
end
end

function values = table_column(T, requestedName)
values = strings(0, 1);
if isempty(T)
    return;
end

varNames = string(T.Properties.VariableNames);
requested = normalize_table_name(requestedName);
idx = find(normalize_table_name(varNames) == requested, 1, 'first');

if isempty(idx) && ~isempty(T.Properties.VariableDescriptions)
    descriptions = string(T.Properties.VariableDescriptions);
    idx = find(normalize_table_name(descriptions) == requested, 1, 'first');
end

if isempty(idx)
    return;
end

raw = T.(char(varNames(idx)));
values = string(raw);
end

function values = table_column_by_index(T, columnIndex)
values = strings(0, 1);
if isempty(T) || width(T) < columnIndex
    return;
end

raw = T.(char(T.Properties.VariableNames(columnIndex)));
values = string(raw);
end

function out = normalize_table_name(name)
out = lower(regexprep(string(name), '[^A-Za-z0-9]+', ''));
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function out = ternary_status(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
end

function name = geometry_class(device)
switch string(device)
    case "AS001"
        name = "control_or_weakly_structured";
    case "AS002"
        name = "threshold_half_encapsulated";
    case "AS003"
        name = "fully_encapsulated_control";
    case "AS004"
        name = "intermediate_half_coverage";
    case "AS005"
        name = "cracked_structured_candidate";
    otherwise
        name = "strong_boundary_structured_candidate";
end
end

function status = final_model_status(device)
switch string(device)
    case {"AS002", "AS003"}
        status = "M0star_sufficient";
    case {"AS005", "AS006"}
        status = "structured_supported";
    otherwise
        status = "mechanistically_unresolved";
end
end

function status = final_evidence_status(device)
switch string(device)
    case "AS001"
        status = "mixed/unresolved";
    case "AS002"
        status = "local-like/threshold";
    case "AS003"
        status = "control-limit support";
    case "AS004"
        status = "mechanistically unresolved";
    case "AS005"
        status = "crack-associated structured support";
    otherwise
        status = "strong structured-connectivity support";
end
end

function claim = allowed_device_claim(device)
switch string(device)
    case "AS001"
        claim = "Mechanism remains unresolved; mixed probe evidence can be reported.";
    case "AS002"
        claim = "Local-Tc/threshold behavior is sufficient under the frozen evidence framework.";
    case "AS003"
        claim = "Control-limit behavior does not require structured connectivity.";
    case "AS004"
        claim = "Structured tendency is present but not independently decisive.";
    case "AS005"
        claim = "Crack-associated structured-connectivity interpretation is supported.";
    otherwise
        claim = "Strongest structured-connectivity support in the six-device series.";
end
end

function q = required_qualification(device)
switch string(device)
    case "AS001"
        q = "Near-tie and context-sensitive; no forced mechanism assignment.";
    case "AS002"
        q = "Local-Tc/threshold behavior is sufficient; weak links are not proven absent.";
    case "AS003"
        q = "Control-limit support; continuous coverage does not require structured connectivity.";
    case "AS004"
        q = "Structured tendency is boundary-sensitive and not independently decisive.";
    case "AS005"
        q = "Strong but crack-dependent; primary-only transport qualification.";
    otherwise
        q = "Strong and comparatively prior/numerically robust structured-connectivity support.";
end
end

function claim = prohibited_overclaim(device)
switch string(device)
    case {"AS001", "AS004"}
        claim = "Do not assign a unique M0star/M1/M2 mechanism.";
    case {"AS002", "AS003"}
        claim = "Do not claim proof that weak links are absent.";
    case "AS005"
        claim = "Do not claim crack-independent universal structured classification.";
    otherwise
        claim = "Do not claim microscopic phase dynamics, topology, or unique strain/domain reconstruction.";
end
end

function row = manifest_row(artifactId, pathValue, required, purpose)
row = struct();
row.artifact_id = string(artifactId);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
end

function row = spec_row(item, value, note)
row = struct();
row.item = string(item);
row.value = string(value);
row.note = string(note);
end

function row = evidence_row(rank, evidenceClass, source, interpretationRule)
row = struct();
row.rank = rank;
row.evidence_class = string(evidenceClass);
row.source = string(source);
row.interpretation_rule = string(interpretationRule);
end

function row = claim_row(claimLevel, status, claimText, qualification)
row = struct();
row.claim_level = string(claimLevel);
row.status = string(status);
row.claim_text = string(claimText);
row.qualification = string(qualification);
end

function row = limitation_row(category, finalWording, usePolicy)
row = struct();
row.limitation_category = string(category);
row.final_wording = string(finalWording);
row.use_policy = string(usePolicy);
end

function row = figure_row(figureId, pathValue, sourceStatus, purpose)
row = struct();
row.figure_id = string(figureId);
row.path = string(pathValue);
row.source_status = string(sourceStatus);
row.purpose = string(purpose);
end

function row = table_row(tableId, pathValue, sourceStatus, purpose)
row = struct();
row.table_id = string(tableId);
row.path = string(pathValue);
row.source_status = string(sourceStatus);
row.purpose = string(purpose);
end

function row = deferred_row(item, status, trigger, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.trigger = string(trigger);
row.note = string(note);
end

function row = gate_row(gate, outcome, note)
row = struct();
row.gate = string(gate);
row.outcome = string(outcome);
row.note = string(note);
end

function row = status_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end

function row = empty_device_row()
row = struct();
row.device = "";
row.geometry_class = "";
row.final_model_status = "";
row.evidence_status = "";
row.primary_evidence = "";
row.heldout_evidence = "";
row.secondary_probe_evidence = "";
row.nonlinear_evidence = "";
row.mechanical_geometry_evidence = "";
row.phase7_prior_annotation = "";
row.phase8_numerical_annotation = "";
row.contextual_DeltaS = NaN;
row.contextual_Z = NaN;
row.allowed_device_claim = "";
row.required_qualification = "";
row.prohibited_overclaim = "";
end
