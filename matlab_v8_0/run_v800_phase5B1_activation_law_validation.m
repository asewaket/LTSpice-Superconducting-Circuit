function out = run_v800_phase5B1_activation_law_validation()
%RUN_V800_PHASE5B1_ACTIVATION_LAW_VALIDATION Global activation-law validation.

rootDir = add_v800_paths();

cfg = v800.phase5_config(rootDir);
out = v800.run_phase5B1_activation_law_validation(cfg);

fprintf('v8.0 Phase 5B.1 activation-law validation complete.\n');
fprintf('Heldout validation: %s\n', out.paths.heldout);
fprintf('Gate results: %s\n', out.paths.gates);
fprintf('Figure: %s\n', out.paths.figurePng);
end
