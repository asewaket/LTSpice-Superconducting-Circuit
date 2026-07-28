function out = run_v800_phase7B_geometry_mask_robustness()
%RUN_V800_PHASE7B_GEOMETRY_MASK_ROBUSTNESS Run Phase 7B-G audit.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase7B_geometry_mask_robustness(cfg);

fprintf('v8.0 Phase 7B-G geometry/mask robustness complete.\n');
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Prior variant ledger: %s\n', out.paths.priorVariantLedger);
fprintf('Geometry mask sensitivity: %s\n', out.paths.geometryMaskSensitivity);
fprintf('Crack mask sensitivity: %s\n', out.paths.crackMaskSensitivity);
fprintf('Raman registration sensitivity: %s\n', ...
    out.paths.ramanRegistrationSensitivity);
fprintf('Shuffled prior control: %s\n', out.paths.shuffledPriorControl);
fprintf('Device robustness annotations: %s\n', ...
    out.paths.deviceRobustnessAnnotations);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Figure: %s\n', out.paths.figurePng);
end
