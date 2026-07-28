function out = run_v800_phase5B_secondary_validation()
%RUN_V800_PHASE5B_SECONDARY_VALIDATION Execute held-out secondary validation.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase5B_secondary_validation(cfg);

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.phase = 'Phase 5B held-out secondary-probe hierarchy validation';
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.config = cfg;
manifest.outputs = out.paths;
v800.write_run_manifest(manifest, cfg.manifestFile);
out.manifestPath = cfg.manifestFile;

fprintf('\nv8.0 Phase 5B secondary/hierarchy validation reported.\n');
fprintf('Frozen Phase 5A archive: %s\n', cfg.phase5B.freezeManifestFile);
fprintf('Secondary manifest: %s\n', cfg.phase5B.secondaryManifestFile);
fprintf('Secondary ledger: %s\n', cfg.phase5B.secondaryLedgerFile);
fprintf('Device evidence table: %s\n', cfg.phase5B.deviceEvidenceFile);
fprintf('Class-heldout validation: %s\n', cfg.phase5B.classHeldoutFile);
fprintf('Activation-law plan: %s\n', cfg.phase5B.activationPlanFile);
fprintf('Hierarchical gates: %s\n', cfg.phase5B.gateResultFile);

end
