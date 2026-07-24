function rootDir = add_v77_paths()
%ADD_V77_PATHS Add v7.7 scoring helpers and shared plotting utilities.

thisDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(thisDir);

addpath(thisDir);
sharedLib = fullfile(rootDir, 'matlab_v7_6_files', 'lib_v7_1');
if exist(sharedLib, 'dir')
    addpath(sharedLib);
end

end

