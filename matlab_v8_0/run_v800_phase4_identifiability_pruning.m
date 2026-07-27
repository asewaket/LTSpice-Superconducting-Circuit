function out = run_v800_phase4_identifiability_pruning()
%RUN_V800_PHASE4_IDENTIFIABILITY_PRUNING Build Phase 4 pruning diagnostics.
%
% This is read-only with respect to Phase 3. It consumes completed seed
% ledgers and writes provisional diagnostics when fewer than 10 seeds exist.

rootDir = add_v800_paths();
cfg = v800.phase4_config(rootDir);

out = v800.build_phase4_identifiability_report(cfg);
out.figure = v800.plot_phase4_pruning_summary(cfg, ...
    out.mechanismSummary, out.pruningDecisions);

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.phase = 'Phase 4 AS006 identifiability and pruning diagnostics';
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.config = cfg;
manifest.seed_count = out.seedCount;
manifest.evidence_maturity = out.evidenceMaturity;
manifest.outputs = out.paths;
v800.write_run_manifest(manifest, cfg.manifestFile);

out.manifestPath = cfg.manifestFile;

fprintf('\nv8.0 Phase 4 identifiability/pruning diagnostics complete.\n');
fprintf('Evidence maturity: %s (%d/%d seeds)\n', ...
    out.evidenceMaturity, out.seedCount, cfg.expectedFinalSeedCount);
fprintf('Pruning decisions: %s\n', cfg.pruningDecisionFile);

end
