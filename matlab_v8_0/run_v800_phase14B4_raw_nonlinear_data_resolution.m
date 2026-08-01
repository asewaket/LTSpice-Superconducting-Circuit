function out = run_v800_phase14B4_raw_nonlinear_data_resolution()
%RUN_V800_PHASE14B4_RAW_NONLINEAR_DATA_RESOLUTION Resolve raw nonlinear grids.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B4_raw_nonlinear_data_resolution(cfg);

fprintf('v8.0 Phase 14B.4 raw nonlinear data resolution complete.\n');
fprintf('Raw data ledger: %s\n', cfg.phase14B4.rawDataLedgerFile);
fprintf('Axis integrity checks: %s\n', cfg.phase14B4.axisIntegrityFile);
fprintf('Resolution decision: %s\n', cfg.phase14B4.resolutionDecisionFile);
fprintf('Gate summary: %s\n', cfg.phase14B4.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B4.handoffStatusFile);
end
