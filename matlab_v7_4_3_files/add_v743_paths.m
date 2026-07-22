function projectDir = add_v743_paths()
%ADD_V743_PATHS Add v7.4.3 project and bundled helper paths.
%
% MATLAB keeps a single global path. If an older model version is already on
% that path, helper functions with the same name can silently shadow the
% v7.4.3 copies. Put v7.4.3 first and remove older v7 model paths so the
% controlled-Wij scripts are self-contained and reproducible.

projectDir = fileparts(mfilename('fullpath'));
libDir = fullfile(projectDir, 'lib_v7_1');

pathEntries = strsplit(path, pathsep);
for k = 1:numel(pathEntries)
    p = pathEntries{k};
    if isempty(p)
        continue;
    end

    isVersionedModelPath = ~isempty(strfind(p, 'matlab_v7_')) || ...
        ~isempty(strfind(p, 'MoTe2_SC_Network_Model_v7_'));
    isCurrentPath = strcmp(p, projectDir) || strcmp(p, libDir);

    if isVersionedModelPath || isCurrentPath
        try
            rmpath(p);
        catch
            % Ignore path entries that MATLAB cannot remove.
        end
    end
end

addpath(projectDir, '-begin');
if exist(libDir, 'dir')
    addpath(libDir, '-begin');
end

% Clear only common v7.4.3 entry points/helpers so edited files are picked up
% without requiring a full MATLAB restart.
clear apply_light_figure_style
clear plot_v743_wij_ablation_summary
clear run_v743_as006_wij_ablation_sweep

end
