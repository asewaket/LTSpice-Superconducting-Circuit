function out = run_v800_phase9_final_model_packaging()
%RUN_V800_PHASE9_FINAL_MODEL_PACKAGING Final v8 model package and claim freeze.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);

cfg = v800.phase5_config(rootDir);
out = v800.run_phase9_final_model_packaging(cfg);

fprintf('v8.0 Phase 9 final model packaging complete.\n');
fprintf('Model specification: %s\n', out.paths.finalModelSpecification);
fprintf('Device conclusion ledger: %s\n', out.paths.finalDeviceConclusionLedger);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff: %s\n', out.paths.handoffStatus);
end
