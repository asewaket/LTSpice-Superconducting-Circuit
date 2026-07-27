function write_ledger(T, pathToFile)
%WRITE_LEDGER Canonical table-ledger writer.

folder = fileparts(pathToFile);
if ~exist(folder, 'dir')
    mkdir(folder);
end
writetable(T, pathToFile);

end

