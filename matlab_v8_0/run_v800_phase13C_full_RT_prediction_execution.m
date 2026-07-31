function out = run_v800_phase13C_full_RT_prediction_execution()
%RUN_V800_PHASE13C_FULL_RT_PREDICTION_EXECUTION Run Phase 13C.2.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13C_full_RT_prediction_execution(cfg);

fprintf('v8.0 Phase 13C.2 full R(T) prediction execution complete.\n');
fprintf('Execution manifest: %s\n', out.paths.fullRTExecutionManifest);
fprintf('Fold training manifest: %s\n', out.paths.foldTrainingManifest);
fprintf('Device predictions: %s\n', out.paths.deviceRTPredictions);
fprintf('Execution gates: %s\n', out.paths.executionGateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
