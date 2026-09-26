function out = run_v800_phase18BR_legacy_bidirectional_recovery_audit()
%RUN_V800_PHASE18BR_LEGACY_BIDIRECTIONAL_RECOVERY_AUDIT
% Recover what legacy nonlinear transport files can support for Phase 18B.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase18BR_legacy_bidirectional_recovery_audit(cfg);

fprintf('v8.0 Phase 18B-R legacy bidirectional recovery audit complete.\n');
fprintf('Recovery manifest: %s\n', out.paths.recoveryManifest);
fprintf('Device summary: %s\n', out.paths.deviceRecoverySummary);
fprintf('Canonical readiness: %s\n', out.paths.canonicalReadiness);
fprintf('Legacy rate context: %s\n', out.paths.legacyRateContext);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
