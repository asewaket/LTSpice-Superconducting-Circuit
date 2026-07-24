function rootDir = add_v771_paths()
%ADD_V771_PATHS Add v7.7.1 and prerequisite v7.7 code to the MATLAB path.
%
% v7.7.1 is a reporting layer: it consumes the real v7.7 score ledgers
% rather than rebuilding the transport model.

thisDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(thisDir);

addpath(thisDir);
addpath(fullfile(rootDir, 'matlab_v7_7_files'));

end
