function out = run_v800_phase8_numerical_robustness()
%RUN_V800_PHASE8_NUMERICAL_ROBUSTNESS Run Phase 8A audit.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase8_numerical_robustness(cfg);

fprintf('v8.0 Phase 8A numerical/implementation robustness audit complete.\n');
fprintf('Scope policy: %s\n', out.paths.scopePolicy);
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Numerical test plan: %s\n', out.paths.numericalTestPlan);
fprintf('Schema audit: %s\n', out.paths.schemaAudit);
fprintf('Reproducibility audit: %s\n', out.paths.reproducibilityAudit);
fprintf('Tolerance policy: %s\n', out.paths.tolerancePolicy);
fprintf('Implementation audit: %s\n', out.paths.implementationAudit);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
