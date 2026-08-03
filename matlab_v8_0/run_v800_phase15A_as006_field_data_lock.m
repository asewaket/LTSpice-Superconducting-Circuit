function out = run_v800_phase15A_as006_field_data_lock()
%RUN_V800_PHASE15A_AS006_FIELD_DATA_LOCK Run Phase 15A.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase15A_as006_field_data_lock(cfg);
fprintf('v8.0 Phase 15A AS006 field-data observable lock complete.\n');
end
