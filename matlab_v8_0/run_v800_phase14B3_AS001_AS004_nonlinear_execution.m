function out = run_v800_phase14B3_AS001_AS004_nonlinear_execution()
%RUN_V800_PHASE14B3_AS001_AS004_NONLINEAR_EXECUTION Execute 14B.3.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B3_AS001_AS004_nonlinear_execution(cfg);

fprintf('v8.0 Phase 14B.3 AS001/AS004 nonlinear execution complete.\n');
fprintf('Device metrics: %s\n', cfg.phase14B3.devicePredictionMetricsFile);
fprintf('N0/NI comparison: %s\n', cfg.phase14B3.N0NIComparisonFile);
fprintf('Gate summary: %s\n', cfg.phase14B3.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B3.handoffStatusFile);
end
