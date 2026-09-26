function out = run_v800_phase18CL_legacy_sweep_rate_dependence_analysis()
%RUN_V800_PHASE18CL_LEGACY_SWEEP_RATE_DEPENDENCE_ANALYSIS
% Legacy-only programmed sweep-rate context analysis after Phase 18B-R.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase18CL_legacy_sweep_rate_dependence_analysis(cfg);

fprintf('v8.0 Phase 18C-L legacy sweep-rate dependence analysis complete.\n');
fprintf('Comparability ledger: %s\n', out.paths.scanComparabilityLedger);
fprintf('Rate context matrix: %s\n', out.paths.rateContextMatrix);
fprintf('Confounder audit: %s\n', out.paths.confounderAudit);
fprintf('Rate sensitivity summary: %s\n', out.paths.rateSensitivitySummary);
fprintf('Device summary: %s\n', out.paths.deviceSummary);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Figure: %s\n', out.paths.figurePng);
end
