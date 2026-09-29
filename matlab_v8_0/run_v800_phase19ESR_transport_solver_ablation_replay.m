function out = run_v800_phase19ESR_transport_solver_ablation_replay()
%RUN_V800_PHASE19ESR_TRANSPORT_SOLVER_ABLATION_REPLAY
% Frozen mechanics-prior transport ablation replay after Phase 19E-S.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19ESR_transport_solver_ablation_replay(cfg);

fprintf('v8.0 Phase 19E-S.R frozen transport-prior ablation replay complete.\n');
fprintf('Frozen policy manifest: %s\n', out.paths.frozenPolicy);
fprintf('Prior normalization: %s\n', out.paths.priorNormalization);
fprintf('Prior score replay: %s\n', out.paths.priorScoreReplay);
fprintf('Hierarchical score components: %s\n', ...
    out.paths.hierarchicalScoreComponents);
fprintf('Randomized spatial null: %s\n', out.paths.randomizedSpatialNull);
fprintf('Device interpretation: %s\n', out.paths.deviceInterpretation);
fprintf('Decision summary: %s\n', out.paths.decisionSummary);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
