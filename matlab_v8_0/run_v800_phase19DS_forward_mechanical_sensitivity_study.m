function out = run_v800_phase19DS_forward_mechanical_sensitivity_study()
%RUN_V800_PHASE19DS_FORWARD_MECHANICAL_SENSITIVITY_STUDY
% Normalized forward mechanics branch after Phase 19B.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19DS_forward_mechanical_sensitivity_study(cfg);

fprintf('v8.0 Phase 19D-S forward mechanical sensitivity study complete.\n');
fprintf('Branch policy: %s\n', out.paths.branchPolicy);
fprintf('Atlas manifest: %s\n', out.paths.atlasManifest);
fprintf('Metric summary: %s\n', out.paths.metricSummary);
fprintf('Sensitivity summary: %s\n', out.paths.sensitivitySummary);
fprintf('Transport coupling candidates: %s\n', ...
    out.paths.transportCouplingCandidates);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
