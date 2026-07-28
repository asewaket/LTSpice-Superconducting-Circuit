function out = run_v800_phase5C_phase5D_artifact_generation(expectedCommitSha)
%RUN_V800_PHASE5C_PHASE5D_ARTIFACT_GENERATION Freeze 5C/5D artifacts.
%
% This is the strict provenance path: it captures source state before either
% Phase 5C or Phase 5D writes generated files, then passes that immutable
% session snapshot to both phases.

rootDir = add_v800_paths();
repoRoot = fileparts(rootDir);

if nargin < 1
    expectedCommitSha = "";
else
    expectedCommitSha = string(expectedCommitSha);
end

sessionProv = v800.capture_source_provenance( ...
    repoRoot, "combined_phase5C_phase5D_session");

if strlength(expectedCommitSha) > 0 && ...
        sessionProv.source_commit_sha ~= expectedCommitSha
    error('v8:phase5CDCommitMismatch', ...
        'Expected source commit %s, but current commit is %s.', ...
        char(expectedCommitSha), char(sessionProv.source_commit_sha));
end

if ~sessionProv.session_pre_run_clean
    error('v8:phase5CDDirtySource', ...
        ['Phase 5C/5D artifact generation must begin from a clean ', ...
        'source tree. Tracked clean: %s. Untracked clean: %s.'], ...
        char(string(sessionProv.session_pre_run_tracked_clean)), ...
        char(string(sessionProv.session_pre_run_untracked_clean)));
end

cfg = v800.phase5_config(rootDir);
out5C = v800.run_phase5C_synthetic_recovery(cfg, sessionProv);
out5D = v800.build_phase5D_calibration_plan(cfg, sessionProv);

out = struct();
out.phase5C = out5C;
out.phase5D = out5D;
out.sessionProvenance = sessionProv;

fprintf('v8.0 Phase 5C/5D artifact generation complete.\n');
fprintf('Session source commit: %s\n', char(sessionProv.source_commit_sha));
fprintf('Session source tree: %s\n', char(sessionProv.source_tree_sha));
fprintf('Session pre-run clean: %s\n', ...
    char(string(sessionProv.session_pre_run_clean)));
fprintf('Phase 5C provenance: %s\n', out5C.paths.sourceProvenance);
fprintf('Phase 5D provenance: %s\n', out5D.paths.sourceProvenance);
end
