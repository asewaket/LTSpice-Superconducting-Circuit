function [baseParams, seed] = assign_local_superconductivity(netPDE, spec, modelParams, pdeOpts, cfg)
%ASSIGN_LOCAL_SUPERCONDUCTIVITY Canonical local Tc/Rn/Ic seed wrapper.

seed = spec.randomSeed + pdeOpts.transport.seedOffset;
if isfield(cfg, 'seedOverride') && ~isempty(cfg.seedOverride) && isfinite(cfg.seedOverride)
    seed = cfg.seedOverride;
end

baseParams = assign_link_parameters(netPDE, spec, modelParams, seed, ...
    'v8_0_gap_weaklink_base');

end

