function out = run_v800_phase13B_limiting_case_verification()
%RUN_V800_PHASE13B_LIMITING_CASE_VERIFICATION Run Phase 13B.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13B_limiting_case_verification(cfg);

fprintf('v8.0 Phase 13B limiting-case verification prepared.\n');
fprintf('Limiting cases: %s\n', out.paths.limitingCaseSpecification);
fprintf('Synthetic proxy response: %s\n', out.paths.syntheticProxyResponse);
fprintf('Component ablations: %s\n', out.paths.componentAblationSummary);
fprintf('Monotonicity checks: %s\n', out.paths.monotonicityChecks);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Figure: %s\n', out.paths.figurePng);
end
