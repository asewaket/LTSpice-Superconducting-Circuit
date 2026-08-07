function out = run_v800_phase16B_sensitivity_conditioning()
%RUN_V800_PHASE16B_SENSITIVITY_CONDITIONING Phase 16B entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase16B_sensitivity_conditioning(cfg);

fprintf('v8.0 Phase 16B sensitivity/conditioning analysis complete.\n');
end
