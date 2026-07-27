function out = run_v800_phase5_transfer_plan()
%RUN_V800_PHASE5_TRANSFER_PLAN Prepare the reduced six-device transfer plan.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.build_phase5_transfer_plan(cfg);

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.phase = 'Phase 5 reduced six-device transfer plan';
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.config = cfg;
manifest.outputs = out.paths;
v800.write_run_manifest(manifest, cfg.manifestFile);
out.manifestPath = cfg.manifestFile;

fprintf('\nv8.0 Phase 5 transfer plan prepared.\n');
fprintf('Candidate set: %s\n', cfg.candidateSetFile);
fprintf('Device plan: %s\n', cfg.devicePlanFile);
fprintf('Validation gates: %s\n', cfg.validationGateFile);

end
