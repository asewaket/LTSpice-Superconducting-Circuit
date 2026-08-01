function out = run_v800_phase13F2_limiting_case_ablation_verification()
%RUN_V800_PHASE13F2_LIMITING_CASE_ABLATION_VERIFICATION Run Phase 13F.2.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13F2_limiting_case_ablation_verification(cfg);

fprintf('v8.0 Phase 13F.2 limiting-case/ablation verification complete.\n');
fprintf('Limiting cases: %s\n', out.paths.limitingCaseManifest);
fprintf('Variant response summary: %s\n', out.paths.variantResponseSummary);
fprintf('Ablation verification: %s\n', out.paths.ablationVerification);
fprintf('Identifiability checks: %s\n', out.paths.identifiabilityChecks);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
