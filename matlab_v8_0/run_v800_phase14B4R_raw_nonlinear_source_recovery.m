function out = run_v800_phase14B4R_raw_nonlinear_source_recovery()
%RUN_V800_PHASE14B4R_RAW_NONLINEAR_SOURCE_RECOVERY Recover raw source files.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B4R_raw_nonlinear_source_recovery(cfg);

fprintf('v8.0 Phase 14B.4R raw nonlinear source recovery complete.\n');
fprintf('Candidate source ledger: %s\n', ...
    cfg.phase14B4R.candidateSourceLedgerFile);
fprintf('Recovery validation: %s\n', ...
    cfg.phase14B4R.recoveryValidationFile);
fprintf('Device recovery decision: %s\n', ...
    cfg.phase14B4R.deviceRecoveryDecisionFile);
fprintf('Gate summary: %s\n', cfg.phase14B4R.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B4R.handoffStatusFile);
end
