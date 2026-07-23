function projectDir = add_v741_paths()
%ADD_V741_PATHS Add v7.4.1 project and bundled helper paths.

projectDir = fileparts(mfilename('fullpath'));
libDir = fullfile(projectDir, 'lib_v7_1');

if exist(libDir, 'dir')
    addpath(libDir, '-end');
end
addpath(projectDir, '-begin');

end
