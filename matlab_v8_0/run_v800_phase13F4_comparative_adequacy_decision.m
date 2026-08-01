function out = run_v800_phase13F4_comparative_adequacy_decision()
%RUN_V800_PHASE13F4_COMPARATIVE_ADEQUACY_DECISION Decide 13F adequacy.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13F4_comparative_adequacy_decision(cfg);

fprintf('v8.0 Phase 13F.4 comparative adequacy decision complete.\n');
fprintf('Variant summary: %s\n', cfg.phase13F4.variantAdequacySummaryFile);
fprintf('Parsimony decision: %s\n', cfg.phase13F4.parsimonyDecisionFile);
fprintf('Gate summary: %s\n', cfg.phase13F4.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase13F4.handoffStatusFile);
end
