function out = run_v800_phase5D1b_calibration_revision()
%RUN_V800_PHASE5D1B_CALIBRATION_REVISION Run versioned 5D.1b calibration audit.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
cfg.phase5D.revisionTag = "Phase 5D.1b";
cfg.phase5D.tuningSeeds = (101:140).';
cfg.phase5D.internalCheckSeeds = (141:160).';
cfg = localize_phase5D1b_outputs(cfg);

out = v800.run_phase5D1_calibrate_m0star(cfg);

fprintf('v8.0 Phase 5D.1b calibration revision complete.\n');
fprintf('Delta-S distribution: %s\n', out.paths.deltaSDistribution);
fprintf('Threshold ROC: %s\n', out.paths.thresholdRocByEvidenceTier);
fprintf('Operating-point feasibility: %s\n', out.paths.operatingPointFeasibility);
fprintf('Sigma audit: %s\n', out.paths.sigmaDeltaSAudit);
fprintf('Uncertainty decomposition: %s\n', out.paths.uncertaintyComponentDecomposition);
fprintf('Nuisance penalty sensitivity: %s\n', out.paths.nuisancePenaltySensitivity);
fprintf('Internal calibration check: %s\n', out.paths.internalCalibrationCheck);
fprintf('Phase 5D handoff status: %s\n', out.paths.handoffStatus);
fprintf('Calibration gates: %s\n', out.paths.calibrationGates);
fprintf('Figure: %s\n', out.paths.figurePng);
end

function cfg = localize_phase5D1b_outputs(cfg)
prefix = 'phase5D1b';
cfg.phase5D.nuisanceProfileLedgerFile = fullfile(cfg.outputDir, ...
    [prefix '_nuisance_profile_ledger.csv']);
cfg.phase5D.deltaSDistributionFile = fullfile(cfg.outputDir, ...
    [prefix '_deltaS_distribution.csv']);
cfg.phase5D.calibratedThresholdsFile = fullfile(cfg.outputDir, ...
    [prefix '_calibrated_thresholds.csv']);
cfg.phase5D.boundaryDetectionCurvesFile = fullfile(cfg.outputDir, ...
    [prefix '_boundary_detection_curves.csv']);
cfg.phase5D.nuisanceBoundaryOccupancyFile = fullfile(cfg.outputDir, ...
    [prefix '_nuisance_boundary_occupancy.csv']);
cfg.phase5D.calibrationSelectionLedgerFile = fullfile(cfg.outputDir, ...
    [prefix '_calibration_selection_ledger.csv']);
cfg.phase5D.operatingPointFeasibilityFile = fullfile(cfg.outputDir, ...
    [prefix '_operating_point_feasibility.csv']);
cfg.phase5D.thresholdRocByEvidenceTierFile = fullfile(cfg.outputDir, ...
    [prefix '_threshold_ROC_by_evidence_tier.csv']);
cfg.phase5D.sigmaDeltaSAuditFile = fullfile(cfg.outputDir, ...
    [prefix '_sigmaDeltaS_audit.csv']);
cfg.phase5D.uncertaintyComponentDecompositionFile = fullfile(cfg.outputDir, ...
    [prefix '_uncertainty_component_decomposition.csv']);
cfg.phase5D.nuisancePenaltySensitivityFile = fullfile(cfg.outputDir, ...
    [prefix '_nuisance_penalty_sensitivity.csv']);
cfg.phase5D.internalCalibrationCheckFile = fullfile(cfg.outputDir, ...
    [prefix '_internal_calibration_check.csv']);
cfg.phase5D.calibrationGateFile = fullfile(cfg.outputDir, ...
    [prefix '_calibration_gate_results.csv']);
cfg.phase5D.calibrationSummaryFigureBaseFile = fullfile(cfg.outputDir, ...
    [prefix '_calibration_summary']);
end
