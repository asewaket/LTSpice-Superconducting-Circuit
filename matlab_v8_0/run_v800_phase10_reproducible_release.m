function out = run_v800_phase10_reproducible_release()
%RUN_V800_PHASE10_REPRODUCIBLE_RELEASE Final v8 release dossier.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
rehash;
clear('v800.run_phase10_reproducible_release');

cfg = v800.phase5_config(rootDir);
out = v800.run_phase10_reproducible_release(cfg);

fprintf('v8.0 Phase 10 reproducible release dossier complete.\n');
fprintf('Release manifest: %s\n', out.paths.releaseManifest);
fprintf('Artifact checksums: %s\n', out.paths.artifactChecksums);
fprintf('Gate summary: %s\n', out.paths.gateSummary);
fprintf('Handoff: %s\n', out.paths.handoffStatus);
end
