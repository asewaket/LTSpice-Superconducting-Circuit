function out = run_v800_phase14A_nonlinear_data_objective_lock()
%RUN_V800_PHASE14A_NONLINEAR_DATA_OBJECTIVE_LOCK Lock nonlinear inputs.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14A_nonlinear_data_objective_lock(cfg);

fprintf('v8.0 Phase 14A nonlinear data/objective lock complete.\n');
fprintf('Data manifest: %s\n', cfg.phase14A.nonlinearDataManifestFile);
fprintf('Objective specification: %s\n', cfg.phase14A.objectiveSpecificationFile);
fprintf('Gate summary: %s\n', cfg.phase14A.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14A.handoffStatusFile);
end
