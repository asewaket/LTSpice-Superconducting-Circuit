function [netPDE, pde, pdeMap, pdeOpts] = construct_mechanical_prior(netGeometry, spec, modelParams)
%CONSTRUCT_MECHANICAL_PRIOR Canonical geometry/Raman/PDE prior wrapper.

pdeOpts = make_v7_pde_options(spec);
pde = solve_v7_pde_mechanics(spec, pdeOpts);
[netPDE, pdeMap] = apply_pde_proxy_to_network(netGeometry, spec, ...
    modelParams, pde, pdeOpts);

end

