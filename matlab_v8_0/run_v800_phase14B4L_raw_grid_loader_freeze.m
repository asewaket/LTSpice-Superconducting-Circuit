function out = run_v800_phase14B4L_raw_grid_loader_freeze()
%RUN_V800_PHASE14B4L_RAW_GRID_LOADER_FREEZE Lock raw nonlinear grids.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
out = v800.run_phase14B4L_raw_grid_loader_freeze(cfg);

fprintf('v8.0 Phase 14B.4L raw grid loader freeze complete.\n');
fprintf('Raw source lock manifest: %s\n', ...
    cfg.phase14B4L.rawSourceLockManifestFile);
fprintf('Checksum manifest: %s\n', ...
    cfg.phase14B4L.fileChecksumManifestFile);
fprintf('Canonical grid manifest: %s\n', ...
    cfg.phase14B4L.canonicalGridManifestFile);
fprintf('Gate summary: %s\n', cfg.phase14B4L.gateSummaryFile);
fprintf('Handoff: %s\n', cfg.phase14B4L.handoffStatusFile);
end
