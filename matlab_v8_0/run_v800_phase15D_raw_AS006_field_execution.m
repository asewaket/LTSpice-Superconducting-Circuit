function out = run_v800_phase15D_raw_AS006_field_execution()
%RUN_V800_PHASE15D_RAW_AS006_FIELD_EXECUTION Run Phase 15D.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase15D_raw_AS006_field_execution(cfg);
fprintf('v8.0 Phase 15D raw AS006 field-dependent execution complete.\n');
end
