function out = run_v800_phase16E_final_recoverability_claim_freeze()
%RUN_V800_PHASE16E_FINAL_RECOVERABILITY_CLAIM_FREEZE Phase 16E entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase16E_final_recoverability_claim_freeze(cfg);

fprintf('v8.0 Phase 16E final recoverability/model-claim freeze complete.\n');
end
