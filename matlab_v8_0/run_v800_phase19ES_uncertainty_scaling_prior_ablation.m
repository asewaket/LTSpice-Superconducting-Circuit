function out = run_v800_phase19ES_uncertainty_scaling_prior_ablation()
%RUN_V800_PHASE19ES_UNCERTAINTY_SCALING_PRIOR_ABLATION
% Analyze 19D-S robustness and prepare mechanics-prior ablation.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19ES_uncertainty_scaling_prior_ablation(cfg);

fprintf('v8.0 Phase 19E-S uncertainty/scaling/prior ablation complete.\n');
fprintf('Robustness summary: %s\n', out.paths.robustnessSummary);
fprintf('Descriptor ranking: %s\n', out.paths.descriptorRanking);
fprintf('Prior family freeze: %s\n', out.paths.priorFamilyFreeze);
fprintf('Transport association screen: %s\n', ...
    out.paths.transportAssociationScreen);
fprintf('Ablation plan: %s\n', out.paths.ablationPlan);
fprintf('Decision summary: %s\n', out.paths.decisionSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
