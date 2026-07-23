function projectDir = add_v73_paths()
%ADD_V73_PATHS Add local helper paths for the v7.3 scaffold.
%
% v7.3 is intentionally more stand-alone than v7.2.2: the v7.1 helper
% functions needed by the PDE/network solver are bundled in lib_v7_1.

projectDir = fileparts(mfilename('fullpath'));
libDir = fullfile(projectDir, 'lib_v7_1');

if exist(libDir, 'dir')
    addpath(libDir, '-end');
else
    error('Missing v7.3 helper library folder: %s', libDir);
end

addpath(projectDir, '-begin');

end
