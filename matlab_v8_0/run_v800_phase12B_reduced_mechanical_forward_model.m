function out = run_v800_phase12B_reduced_mechanical_forward_model()
%RUN_V800_PHASE12B_REDUCED_MECHANICAL_FORWARD_MODEL Run Phase 12B.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase12B_reduced_mechanical_forward_model(cfg);

fprintf('v8.0 Phase 12B reduced mechanical forward model prepared.\n');
fprintf('Mechanical specification: %s\n', ...
    out.paths.mechanicalModelSpecification);
fprintf('Device summary: %s\n', out.paths.deviceMechanicalSummary);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
