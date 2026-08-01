function out = run_v800_phase13F3_full_variant_LODO_execution()
%RUN_V800_PHASE13F3_FULL_VARIANT_LODO_EXECUTION Execute Phase 13F.3.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13F3_full_variant_LODO_execution(cfg);

fprintf('v8.0 Phase 13F.3 full four-variant LODO execution complete.\n');
fprintf('Variant comparison: %s\n', cfg.phase13F3.variantComparisonFile);
fprintf('Gate summary: %s\n', cfg.phase13F3.executionGateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase13F3.handoffStatusFile);
end
