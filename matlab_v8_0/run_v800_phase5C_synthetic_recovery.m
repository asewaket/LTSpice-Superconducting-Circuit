function out = run_v800_phase5C_synthetic_recovery(sessionProv)
%RUN_V800_PHASE5C_SYNTHETIC_RECOVERY Execute synthetic mechanism recovery.

rootDir = add_v800_paths();

cfg = v800.phase5_config(rootDir);
if nargin < 1
    sessionProv = [];
end
out = v800.run_phase5C_synthetic_recovery(cfg, sessionProv);

fprintf('v8.0 Phase 5C synthetic recovery complete.\n');
fprintf('Recovery matrix: %s\n', out.paths.recoveryMatrix);
fprintf('Recovery summary: %s\n', out.paths.recoverySummary);
fprintf('Label policy: %s\n', out.paths.labelPolicy);
fprintf('Source provenance checkpoint: %s\n', out.paths.sourceProvenance);
fprintf('Misspecification summary: %s\n', out.paths.misspecSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Gate results: %s\n', out.paths.gates);
fprintf('Figure: %s\n', out.paths.figurePng);
end
