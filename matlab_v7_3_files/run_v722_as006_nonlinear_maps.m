%RUN_V722_AS006_NONLINEAR_MAPS Explicit v7.2.2 entry point.
%
% MATLAB function names cannot contain dots, so this wrapper keeps the
% versioned command name readable while reusing the maintained v7.2 script.

run(fullfile(fileparts(mfilename('fullpath')), 'run_v72_as006_nonlinear_maps.m'));
