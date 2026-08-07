function out = run_v800_phase16D_spatial_model_reduction()
%RUN_V800_PHASE16D_SPATIAL_MODEL_REDUCTION Phase 16D entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase16D_spatial_model_reduction(cfg);

fprintf('v8.0 Phase 16D spatial model reduction complete.\n');
end
