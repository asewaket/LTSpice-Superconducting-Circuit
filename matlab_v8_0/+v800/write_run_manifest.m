function write_run_manifest(manifest, pathToFile)
%WRITE_RUN_MANIFEST Write a JSON run manifest.

folder = fileparts(pathToFile);
if ~exist(folder, 'dir')
    mkdir(folder);
end

try
    jsonText = jsonencode(manifest, 'PrettyPrint', true);
catch
    jsonText = jsonencode(manifest);
end
fid = fopen(pathToFile, 'w');
if fid < 0
    error('Could not open manifest for writing: %s', pathToFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonText);

end
