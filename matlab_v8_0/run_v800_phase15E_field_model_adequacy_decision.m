function out = run_v800_phase15E_field_model_adequacy_decision()
%RUN_V800_PHASE15E_FIELD_MODEL_ADEQUACY_DECISION Run Phase 15E.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase15E_field_model_adequacy_decision(cfg);
fprintf('v8.0 Phase 15E AS006 field-model adequacy decision complete.\n');
end
