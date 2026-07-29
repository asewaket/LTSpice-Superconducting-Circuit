function out = run_v800_phase8B_numerical_replay()
%RUN_V800_PHASE8B_NUMERICAL_REPLAY Run Phase 8B replay audit.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase8B_numerical_replay(cfg);

fprintf('v8.0 Phase 8B frozen-context numerical replay complete.\n');
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Mesh replay: %s\n', out.paths.meshReplay);
fprintf('Solver replay: %s\n', out.paths.solverReplay);
fprintf('Normalization replay: %s\n', out.paths.normalizationReplay);
fprintf('Seed replay: %s\n', out.paths.seedReplay);
fprintf('Cached artifact replay: %s\n', out.paths.cachedArtifactReplay);
fprintf('Status stability: %s\n', out.paths.statusStability);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
