function out = run_v800_phase5B2_full_series_activation_consolidation()
%RUN_V800_PHASE5B2_FULL_SERIES_ACTIVATION_CONSOLIDATION Consolidate 5B.1.

rootDir = add_v800_paths();

cfg = v800.phase5_config(rootDir);
out = v800.run_phase5B2_full_series_activation_consolidation(cfg);

fprintf('v8.0 Phase 5B.2 full-series activation consolidation complete.\n');
fprintf('Joint comparison: %s\n', out.paths.jointComparison);
fprintf('AS004 profile: %s\n', out.paths.as004Profile);
fprintf('Gate results: %s\n', out.paths.gates);
fprintf('Figure: %s\n', out.paths.figurePng);
end
