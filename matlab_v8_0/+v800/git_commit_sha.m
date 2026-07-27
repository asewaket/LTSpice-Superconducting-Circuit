function sha = git_commit_sha(repoRoot)
%GIT_COMMIT_SHA Return the current Git commit hash when available.

if nargin < 1 || isempty(repoRoot)
    repoRoot = pwd;
end

cmd = sprintf('git -C "%s" rev-parse HEAD', repoRoot);
[status, out] = system(cmd);
if status == 0
    sha = strtrim(out);
else
    sha = 'unknown';
end

end

