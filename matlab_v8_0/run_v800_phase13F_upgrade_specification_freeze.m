function out = run_v800_phase13F_upgrade_specification_freeze()
%RUN_V800_PHASE13F_UPGRADE_SPECIFICATION_FREEZE Run Phase 13F.1.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13F_upgrade_specification_freeze(cfg);

fprintf('v8.0 Phase 13F.1 constrained upgrade specification freeze complete.\n');
fprintf('Upgrade specification: %s\n', out.paths.upgradeModelSpecification);
fprintf('Variant manifest: %s\n', out.paths.variantManifest);
fprintf('Comparison thresholds: %s\n', out.paths.comparisonThresholds);
fprintf('Figure: %s\n', out.paths.figurePng);
end
