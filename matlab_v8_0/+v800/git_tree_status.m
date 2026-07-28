function statusInfo = git_tree_status(repoRoot)
%GIT_TREE_STATUS Capture source commit and tree cleanliness before a run.

if nargin < 1 || isempty(repoRoot)
    repoRoot = pwd;
end

statusInfo = struct();
statusInfo.commit_sha = string(v800.git_commit_sha(repoRoot));

[treeCode, treeText] = system(sprintf( ...
    'git -C "%s" rev-parse HEAD^{tree}', repoRoot));
treeText = string(strtrim(treeText));
statusInfo.tree_status_code = treeCode;
if treeCode == 0
    statusInfo.tree_sha = treeText;
else
    statusInfo.tree_sha = "unknown";
end

[trackedCode, trackedText] = system(sprintf( ...
    'git -C "%s" status --porcelain --untracked-files=no', repoRoot));
trackedText = string(strtrim(trackedText));
statusInfo.tracked_status_code = trackedCode;
statusInfo.tracked_status_text = trackedText;
statusInfo.tracked_clean = trackedCode == 0 && strlength(trackedText) == 0;

[untrackedCode, untrackedText] = system(sprintf( ...
    'git -C "%s" ls-files --others --exclude-standard', repoRoot));
untrackedText = string(strtrim(untrackedText));
statusInfo.untracked_status_code = untrackedCode;
statusInfo.untracked_status_text = untrackedText;
statusInfo.untracked_clean = untrackedCode == 0 && strlength(untrackedText) == 0;

statusInfo.source_pre_run_clean = statusInfo.tracked_clean && ...
    statusInfo.untracked_clean;
end
