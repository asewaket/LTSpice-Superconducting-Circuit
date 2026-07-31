function out = run_v800_phase13D_predictive_adequacy()
%RUN_V800_PHASE13D_PREDICTIVE_ADEQUACY Run Phase 13D adequacy review.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase13D_predictive_adequacy(cfg);

fprintf('v8.0 Phase 13D predictive adequacy assessment complete.\n');
fprintf('Execution validity: %s\n', out.paths.executionValidity);
fprintf('Full-curve adequacy: %s\n', out.paths.fullCurveAdequacy);
fprintf('Transition crossing status: %s\n', out.paths.transitionCrossingStatus);
fprintf('Adequacy decision: %s\n', out.paths.predictiveAdequacyDecision);
fprintf('Figure: %s\n', out.paths.figurePng);
end
