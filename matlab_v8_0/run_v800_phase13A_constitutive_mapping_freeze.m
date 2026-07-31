function out = run_v800_phase13A_constitutive_mapping_freeze()
%RUN_V800_PHASE13A_CONSTITUTIVE_MAPPING_FREEZE Run Phase 13A.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13A_constitutive_mapping_freeze(cfg);

fprintf('v8.0 Phase 13A constitutive mapping freeze prepared.\n');
fprintf('Constitutive specification: %s\n', ...
    out.paths.constitutiveModelSpecification);
fprintf('Parameter roles: %s\n', out.paths.parameterRoleLedger);
fprintf('Calibration/holdout plan: %s\n', out.paths.calibrationHoldoutPlan);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
