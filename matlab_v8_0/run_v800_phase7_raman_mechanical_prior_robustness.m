function out = run_v800_phase7_raman_mechanical_prior_robustness()
%RUN_V800_PHASE7_RAMAN_MECHANICAL_PRIOR_ROBUSTNESS Start Phase 7A.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase7_raman_mechanical_prior_robustness(cfg);

fprintf('v8.0 Phase 7A Raman/mechanical prior robustness start complete.\n');
fprintf('Scope policy: %s\n', out.paths.scopePolicy);
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Prior evidence manifest: %s\n', out.paths.priorEvidenceManifest);
fprintf('Perturbation scenarios: %s\n', out.paths.perturbationScenarios);
fprintf('Device robustness: %s\n', out.paths.deviceRobustness);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Figure: %s\n', out.paths.figurePng);
end
