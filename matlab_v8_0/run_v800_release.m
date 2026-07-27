function out = run_v800_release()
%RUN_V800_RELEASE Canonical v8 release orchestration entry point.
%
% Phase 2 gate: reproduce the v7.4.6 AS006 gap-tied weak-link screening
% result through the v8 wrapper before any new fitting is allowed.

rootDir = add_v800_paths();
cfg = v800.default_config(rootDir);
out = v800.run_as006_v746_reproduction(cfg);

fprintf('\nv8.0 Phase 2 reproduction gate: %s\n', out.gate.status);
fprintf('Manifest: %s\n', out.manifestPath);

end

