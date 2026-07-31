function out = run_v800_phase12C_raman_forward_feasibility()
%RUN_V800_PHASE12C_RAMAN_FORWARD_FEASIBILITY Run Phase 12C.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase12C_raman_forward_feasibility(cfg);

fprintf('v8.0 Phase 12C Raman forward feasibility prepared.\n');
fprintf('Model specification: %s\n', ...
    out.paths.ramanForwardModelSpecification);
fprintf('Device predictions: %s\n', out.paths.deviceLevelModePredictions);
fprintf('Registered comparison status: %s\n', ...
    out.paths.registeredComparisonStatus);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
