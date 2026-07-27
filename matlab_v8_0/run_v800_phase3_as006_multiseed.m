function out = run_v800_phase3_as006_multiseed()
%RUN_V800_PHASE3_AS006_MULTISEED Run the AS006 Phase 3 seed campaign.
%
% This is the first v8 evidence campaign after the Phase 2 reproduction gate.
% It uses the v7.4.6 gap-tied weak-link physics path with a frozen 10-seed
% protocol and writes seed ledgers plus stop/go statistics.

rootDir = add_v800_paths();
cfg = v800.phase3_config(rootDir);

campaign = v800.run_as006_multiseed_campaign(cfg);
[mechanismReport, gateReport] = v800.build_as006_multiseed_report(cfg);

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.phase = 'Phase 3 AS006 multi-seed evidence campaign';
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.config = cfg;
manifest.campaign_status = campaign.statusTable;
manifest.mechanism_report_file = cfg.mechanismReportFile;
manifest.gate_report_file = cfg.gateReportFile;
v800.write_run_manifest(manifest, cfg.manifestFile);

out = struct();
out.config = cfg;
out.campaign = campaign;
out.mechanismReport = mechanismReport;
out.gateReport = gateReport;
out.manifestPath = cfg.manifestFile;

fprintf('\nv8.0 Phase 3 AS006 multi-seed campaign complete.\n');
fprintf('Mechanism report: %s\n', cfg.mechanismReportFile);
fprintf('Gate report: %s\n', cfg.gateReportFile);

end

