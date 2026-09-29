function out = run_v800_phase19FS_mechanics_informed_superconducting_network()
%RUN_V800_PHASE19FS_MECHANICS_INFORMED_SUPERCONDUCTING_NETWORK
% Integrate the frozen mechanics-gradient prior into the network narrative.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase19FS_mechanics_informed_superconducting_network(cfg);

fprintf('v8.0 Phase 19F-S mechanics-informed superconducting network complete.\n');
fprintf('Frozen policy manifest: %s\n', out.paths.frozenPolicy);
fprintf('Coupling role ablation: %s\n', out.paths.couplingRoleAblation);
fprintf('Six-device comparison: %s\n', out.paths.sixDeviceComparison);
fprintf('Spatial field maps: %s\n', out.paths.spatialFieldMaps);
fprintf('Current overlap metrics: %s\n', out.paths.currentOverlapMetrics);
fprintf('Device interpretation: %s\n', out.paths.deviceInterpretation);
fprintf('Decision summary: %s\n', out.paths.decisionSummary);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Source provenance: %s\n', out.paths.sourceProvenance);
fprintf('Summary figure: %s\n', out.paths.figurePng);
fprintf('AS005/AS006 panel: %s\n', out.paths.mapPanelPng);
end
