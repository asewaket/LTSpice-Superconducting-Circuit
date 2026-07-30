function out = run_v800_phase12A_raman_registration_feasibility()
%RUN_V800_PHASE12A_RAMAN_REGISTRATION_FEASIBILITY Run Phase 12A.

rootDir = fileparts(mfilename('fullpath'));
if exist(fullfile(rootDir, 'add_v800_paths.m'), 'file')
    add_v800_paths();
else
    addpath(rootDir);
end
rehash;
clear('v800.run_phase12A_raman_registration_feasibility');

cfg = v800.phase5_config(rootDir);
out = v800.run_phase12A_raman_registration_feasibility(cfg);

fprintf('Phase 12A Raman registration feasibility complete.\n');
fprintf('Registration ledger: %s\n', ...
    out.paths.ramanRegistrationLedger);
fprintf('Transform manifest: %s\n', ...
    out.paths.coordinateTransformManifest);
fprintf('Mechanical inputs: %s\n', out.paths.mechanicalInputDefinition);
fprintf('Handoff: %s\n', out.paths.handoffStatus);
end
