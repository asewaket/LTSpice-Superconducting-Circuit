function out = run_v800_phase19GS_final_robustness_freeze()
%RUN_V800_PHASE19GS_FINAL_ROBUSTNESS_FREEZE
% Final robustness and multiscale model freeze after Phase 19F-S.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19GS_final_robustness_freeze(cfg);

fprintf('v8.0 Phase 19G-S final robustness freeze complete.\n');
fprintf('Frozen policy: %s\n', out.paths.frozenPolicy);
fprintf('Disorder robustness: %s\n', out.paths.disorderRobustness);
fprintf('Grid robustness: %s\n', out.paths.gridRobustness);
fprintf('Prior normalization robustness: %s\n', ...
    out.paths.priorNormalizationRobustness);
fprintf('Overlap null distribution: %s\n', out.paths.overlapNullDistribution);
fprintf('Anchor dependency: %s\n', out.paths.anchorDependency);
fprintf('Final model freeze: %s\n', out.paths.finalModelFreeze);
fprintf('Decision summary: %s\n', out.paths.decisionSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
