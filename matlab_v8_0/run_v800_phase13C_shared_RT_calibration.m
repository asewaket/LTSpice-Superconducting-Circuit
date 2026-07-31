function out = run_v800_phase13C_shared_RT_calibration()
%RUN_V800_PHASE13C_SHARED_RT_CALIBRATION Run Phase 13C setup.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13C_shared_RT_calibration(cfg);

fprintf('v8.0 Phase 13C shared R(T) calibration campaign prepared.\n');
fprintf('R(T) data lock: %s\n', out.paths.RTDataLockManifest);
fprintf('Objective specification: %s\n', ...
    out.paths.calibrationObjectiveSpecification);
fprintf('Leave-one-device-out manifest: %s\n', ...
    out.paths.leaveOneDeviceOutManifest);
fprintf('Prediction ledger: %s\n', out.paths.deviceRTPredictions);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
