function out = run_v800_phase13E_missing_input_model_adequacy_audit()
%RUN_V800_PHASE13E_MISSING_INPUT_MODEL_ADEQUACY_AUDIT Run Phase 13E.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13E_missing_input_model_adequacy_audit(cfg);

fprintf('v8.0 Phase 13E missing-input/model-adequacy audit complete.\n');
fprintf('Failure decomposition: %s\n', out.paths.deviceFailureDecomposition);
fprintf('Missing-input ledger: %s\n', out.paths.missingInputLedger);
fprintf('Selected upgrade scope: %s\n', out.paths.selectedUpgradeScope);
fprintf('Figure: %s\n', out.paths.figurePng);
end
