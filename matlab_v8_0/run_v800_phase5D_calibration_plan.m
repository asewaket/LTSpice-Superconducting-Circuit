function out = run_v800_phase5D_calibration_plan()
%RUN_V800_PHASE5D_CALIBRATION_PLAN Write the frozen Phase 5D plan.

rootDir = add_v800_paths();

cfg = v800.phase5_config(rootDir);
out = v800.build_phase5D_calibration_plan(cfg);

fprintf('v8.0 Phase 5D calibration plan prepared.\n');
fprintf('Scope: %s\n', out.paths.scope);
fprintf('M0* nuisance family: %s\n', out.paths.nuisanceFamily);
fprintf('Score-difference plan: %s\n', out.paths.scoreDifferencePlan);
fprintf('Calibration/validation split: %s\n', out.paths.syntheticSplit);
fprintf('Boundary sweep: %s\n', out.paths.boundarySweep);
fprintf('Success criteria: %s\n', out.paths.successCriteria);
fprintf('5C handoff archive: %s\n', out.paths.handoffArchive);
end
