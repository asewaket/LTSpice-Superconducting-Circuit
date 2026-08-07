function out = run_v800_phase16A_identifiability_inventory()
%RUN_V800_PHASE16A_IDENTIFIABILITY_INVENTORY Run Phase 16A.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase16A_identifiability_inventory(cfg);
fprintf('v8.0 Phase 16A joint-identifiability inventory complete.\n');
end
