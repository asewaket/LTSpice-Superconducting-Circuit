function out = run_v800_phase14B_current_model_solver_freeze()
%RUN_V800_PHASE14B_CURRENT_MODEL_SOLVER_FREEZE Freeze current-switching model.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B_current_model_solver_freeze(cfg);

fprintf('v8.0 Phase 14B.1 current-model/solver freeze complete.\n');
fprintf('Current model specification: %s\n', ...
    cfg.phase14B.currentModelSpecificationFile);
fprintf('Solver specification: %s\n', cfg.phase14B.solverSpecificationFile);
fprintf('Gate summary: %s\n', cfg.phase14B.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B.handoffStatusFile);
end
