function out = run_v800_phase15B_phase_aware_model_specification()
%RUN_V800_PHASE15B_PHASE_AWARE_MODEL_SPECIFICATION Run Phase 15B.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase15B_phase_aware_model_specification(cfg);
fprintf('v8.0 Phase 15B minimal phase-aware model specification complete.\n');
end
