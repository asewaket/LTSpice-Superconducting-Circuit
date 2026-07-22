function projectDir = add_v743_paths()
%ADD_V743_PATHS Add v7.4.3 project and bundled helper paths.

projectDir = fileparts(mfilename('fullpath'));
libDir = fullfile(projectDir, 'lib_v7_1');

if exist(libDir, 'dir')
    addpath(libDir, '-end');
end
addpath(projectDir, '-begin');

end
