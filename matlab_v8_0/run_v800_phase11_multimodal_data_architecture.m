function out = run_v800_phase11_multimodal_data_architecture()
%RUN_V800_PHASE11_MULTIMODAL_DATA_ARCHITECTURE Build Phase 11 schemas.

rootDir = fileparts(mfilename('fullpath'));
if exist(fullfile(rootDir, 'add_v800_paths.m'), 'file')
    add_v800_paths();
else
    addpath(rootDir);
end
rehash;
clear('v800.run_phase11_multimodal_data_architecture');

cfg = v800.phase5_config(rootDir);
out = v800.run_phase11_multimodal_data_architecture(cfg);

fprintf('Phase 11 multimodal data architecture complete.\n');
fprintf('Device observable manifest: %s\n', ...
    out.paths.deviceObservableManifest);
fprintf('Probe mapping: %s\n', out.paths.probeMapping);
fprintf('Registration availability: %s\n', ...
    out.paths.registrationAvailability);
fprintf('Handoff: %s\n', out.paths.handoffStatus);
end
