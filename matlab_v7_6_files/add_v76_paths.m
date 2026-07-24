function add_v76_paths()
%ADD_V76_PATHS Add v7.6 scoring scaffold and inherited helper libraries.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'lib_v7_1'));

end
