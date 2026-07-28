function out = run_v800_phase5D2_result_freeze()
%RUN_V800_PHASE5D2_RESULT_FREEZE Freeze Phase 5D.2 evidence policy.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase5D2_result_freeze(cfg);

fprintf('v8.0 Phase 5D.2 result freeze complete.\n');
fprintf('Result-freeze status: %s\n', out.paths.resultFreezeStatus);
fprintf('Compatibility freeze status: %s\n', out.paths.freezeStatus);
fprintf('Interpretation policy: %s\n', out.paths.interpretationPolicy);
fprintf('Validation status: %s\n', out.paths.validationStatus);
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Real-device score context: %s\n', out.paths.realDeviceScoreContext);
fprintf('Device evidence synthesis: %s\n', out.paths.deviceEvidenceSynthesis);
fprintf('Final gate summary: %s\n', out.paths.finalGateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Figure: %s\n', out.paths.figurePng);
end
