function result = solve_rt_sweep(net, spec, params, T_vec, Iprobe)
%SOLVE_RT_SWEEP Compute small-signal four-probe R(T).

pairNames = fieldnames(spec.probePairs);
for kp = 1:numel(pairNames)
    result.R4p.(pairNames{kp}) = zeros(size(T_vec));
end

result.T = T_vec;

for kT = 1:numel(T_vec)
    T = T_vec(kT);
    [Rx, Ry] = link_resistance_T(params, spec, T);
    gx = safe_conductance(Rx, net.link.activeX);
    gy = safe_conductance(Ry, net.link.activeY);

    [v, Ix, Iy] = solve_network_linear(net, gx, gy, Iprobe);
    R = extract_all_probe_resistances(net, spec, v, Iprobe);

    for kp = 1:numel(pairNames)
        result.R4p.(pairNames{kp})(kT) = R.(pairNames{kp});
    end

    if kT == numel(T_vec)
        result.lastVoltage = v;
        result.lastIx = Ix;
        result.lastIy = Iy;
    end
end

end
