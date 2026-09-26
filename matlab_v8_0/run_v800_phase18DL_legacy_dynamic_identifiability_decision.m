function out = run_v800_phase18DL_legacy_dynamic_identifiability_decision()
%RUN_V800_PHASE18DL_LEGACY_DYNAMIC_IDENTIFIABILITY_DECISION
% Read-only decision after the canonical Phase 18C-L artifact freeze.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase18DL_legacy_dynamic_identifiability_decision(cfg);

fprintf('v8.0 Phase 18D-L legacy dynamic identifiability decision complete.\n');
fprintf('Input integrity: %s\n', out.paths.inputIntegrity);
fprintf('Dynamic identifiability ledger: %s\n', ...
    out.paths.dynamicIdentifiabilityLedger);
fprintf('Decision matrix: %s\n', out.paths.decisionMatrix);
fprintf('Development decision: %s\n', out.paths.developmentDecision);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
