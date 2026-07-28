function out = run_v800_phase5D1_calibrate_m0star()
%RUN_V800_PHASE5D1_CALIBRATE_M0STAR Calibrate the M0* decision rule.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase5D1_calibrate_m0star(cfg);

fprintf('v8.0 Phase 5D.1 M0* calibration complete.\n');
fprintf('Nuisance ledger: %s\n', out.paths.nuisanceProfileLedger);
fprintf('Delta-S distribution: %s\n', out.paths.deltaSDistribution);
fprintf('Calibrated thresholds: %s\n', out.paths.calibratedThresholds);
fprintf('Boundary curves: %s\n', out.paths.boundaryDetectionCurves);
fprintf('Calibration gates: %s\n', out.paths.calibrationGates);
fprintf('Figure: %s\n', out.paths.figurePng);
end
