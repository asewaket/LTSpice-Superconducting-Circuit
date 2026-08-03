function out = run_v800_phase15C_synthetic_flux_interference_verification()
%RUN_V800_PHASE15C_SYNTHETIC_FLUX_INTERFERENCE_VERIFICATION Run Phase 15C.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase15C_synthetic_flux_interference_verification(cfg);
fprintf('v8.0 Phase 15C synthetic flux/interference verification complete.\n');
end
