function out = run_v800_phase5_transfer_campaign(runDeviceSweeps)
%RUN_V800_PHASE5_TRANSFER_CAMPAIGN Execute/report the Phase 5 transfer gate.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);
if nargin >= 1 && ~isempty(runDeviceSweeps)
    cfg.runDeviceSweeps = logical(runDeviceSweeps);
end

if isfield(cfg, 'phase5A') && isfield(cfg.phase5A, 'enabled') && cfg.phase5A.enabled
    out = v800.run_phase5A_frozen_rt_transfer(cfg);

    manifest = struct();
    manifest.model_version = cfg.modelVersion;
    manifest.phase = 'Phase 5A frozen-basin primary R(T) transfer';
    manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
    manifest.generated_at = datestr(now, 30);
    manifest.config = cfg;
    manifest.outputs = out.paths;
    v800.write_run_manifest(manifest, cfg.manifestFile);
    out.manifestPath = cfg.manifestFile;

    fprintf('\nv8.0 Phase 5A frozen R(T) transfer campaign reported.\n');
    fprintf('R(T) manifest: %s\n', cfg.phase5A.rtManifestFile);
    fprintf('Frozen basin set: %s\n', cfg.phase5A.frozenBasinFile);
    fprintf('Frozen transfer ledger: %s\n', cfg.phase5A.frozenTransferLedgerFile);
    fprintf('Device summary: %s\n', cfg.phase5A.summaryFile);
    fprintf('Leave-one-device-out: %s\n', cfg.phase5A.leaveOneOutFile);
    fprintf('Gate results: %s\n', cfg.phase5A.gateResultFile);
    return;
end

plan = v800.build_phase5_transfer_plan(cfg);
out = v800.run_phase5_transfer_campaign(cfg, plan);

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.phase = 'Phase 5 six-device transfer campaign';
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.config = cfg;
manifest.outputs = out.paths;
v800.write_run_manifest(manifest, cfg.manifestFile);
out.manifestPath = cfg.manifestFile;

fprintf('\nv8.0 Phase 5 transfer campaign reported.\n');
fprintf('Data manifest: %s\n', cfg.dataManifestFile);
fprintf('Transfer scores: %s\n', cfg.transferScoreFile);
fprintf('Device summary: %s\n', cfg.deviceSummaryFile);
fprintf('Leave-one-device-out: %s\n', cfg.leaveOneOutFile);
fprintf('Gate results: %s\n', cfg.gateResultFile);

end
