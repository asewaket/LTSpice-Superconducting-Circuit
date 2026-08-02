function out = run_v800_phase14B5_raw_nonlinear_execution()
%RUN_V800_PHASE14B5_RAW_NONLINEAR_EXECUTION Run Phase 14B.5.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase14B5_raw_nonlinear_execution(cfg);
fprintf('v8.0 Phase 14B.5 raw current-only nonlinear execution complete.\n');
end
