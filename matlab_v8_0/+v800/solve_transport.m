function field = solve_transport(netCase, spec, paramsCase, fieldOpts, weak)
%SOLVE_TRANSPORT Canonical four-probe transport solver wrapper.

field = solve_v741_field_dvdi_map(netCase, spec, paramsCase, fieldOpts, weak);

end

