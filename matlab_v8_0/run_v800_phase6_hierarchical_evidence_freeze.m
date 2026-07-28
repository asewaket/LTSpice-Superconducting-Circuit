function out = run_v800_phase6_hierarchical_evidence_freeze()
%RUN_V800_PHASE6_HIERARCHICAL_EVIDENCE_FREEZE Freeze six-device hierarchy.

rootDir = add_v800_paths();
cfg = v800.phase5_config(rootDir);

out = v800.run_phase6_hierarchical_evidence_freeze(cfg);

fprintf('v8.0 Phase 6 hierarchical evidence freeze complete.\n');
fprintf('Model hierarchy: %s\n', out.paths.modelHierarchyFreeze);
fprintf('Frozen input manifest: %s\n', out.paths.frozenInputManifest);
fprintf('Six-device evidence matrix: %s\n', out.paths.sixDeviceEvidenceMatrix);
fprintf('Device model status: %s\n', out.paths.deviceModelStatus);
fprintf('Evidence tier assignments: %s\n', out.paths.evidenceTierAssignments);
fprintf('Claim hierarchy: %s\n', out.paths.claimHierarchy);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff status: %s\n', out.paths.handoffStatus);
fprintf('Figure: %s\n', out.paths.figurePng);
end
