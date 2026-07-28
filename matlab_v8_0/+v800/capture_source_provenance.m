function prov = capture_source_provenance(repoRoot, provenanceScope)
%CAPTURE_SOURCE_PROVENANCE Capture immutable session-start source state.

if nargin < 1 || isempty(repoRoot)
    repoRoot = pwd;
end
if nargin < 2 || isempty(provenanceScope)
    provenanceScope = "standalone_phase_run";
end

statusInfo = v800.git_tree_status(repoRoot);

prov = struct();
prov.provenance_scope = string(provenanceScope);
prov.source_commit_sha = statusInfo.commit_sha;
prov.source_tree_sha = statusInfo.tree_sha;
prov.session_pre_run_tracked_clean = statusInfo.tracked_clean;
prov.session_pre_run_untracked_clean = statusInfo.untracked_clean;
prov.session_pre_run_clean = statusInfo.tracked_clean && ...
    statusInfo.untracked_clean;
prov.session_started_at = string(datestr(now, 30));
prov.repo_root = string(repoRoot);
prov.tracked_status_text = statusInfo.tracked_status_text;
prov.untracked_status_text = statusInfo.untracked_status_text;
end
