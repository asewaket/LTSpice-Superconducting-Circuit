function out = run_v800_phase14B2_synthetic_switching_solver_verification()
%RUN_V800_PHASE14B2_SYNTHETIC_SWITCHING_SOLVER_VERIFICATION Verify synthetic solver behavior.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B2_synthetic_switching_solver_verification(cfg);

fprintf('v8.0 Phase 14B.2 synthetic switching/solver verification complete.\n');
fprintf('Limiting-case summary: %s\n', ...
    cfg.phase14B2.limitingCaseSummaryFile);
fprintf('Gate summary: %s\n', cfg.phase14B2.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B2.handoffStatusFile);
end
