function out = run_v800_phase19A_raman_geometry_mechanical_input_audit()
%RUN_V800_PHASE19A_RAMAN_GEOMETRY_MECHANICAL_INPUT_AUDIT
% Quantitative mechanical/strain-inference readiness gate.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19A_raman_geometry_mechanical_input_audit(cfg);

fprintf('v8.0 Phase 19A Raman/geometry mechanical-input audit complete.\n');
fprintf('Spatial input inventory: %s\n', out.paths.spatialInputInventory);
fprintf('Registration readiness: %s\n', out.paths.registrationReadiness);
fprintf('Materials inventory: %s\n', out.paths.materialsInventory);
fprintf('Mechanical readiness decision: %s\n', ...
    out.paths.mechanicalReadinessDecision);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
