function result = solve_iv_sweep(net, spec, params, T, I_vec)
%SOLVE_IV_SWEEP Compute nonlinear I-V curves using local branch currents.

pairNames = fieldnames(spec.probePairs);
for kp = 1:numel(pairNames)
    result.V4p.(pairNames{kp}) = zeros(size(I_vec));
    result.R4p.(pairNames{kp}) = zeros(size(I_vec));
end
result.I = I_vec;
result.T = T;

[Rx0, Ry0] = link_resistance_T(params, spec, T);
gxPrev = safe_conductance(Rx0, net.link.activeX);
gyPrev = safe_conductance(Ry0, net.link.activeY);

for kI = 1:numel(I_vec)
    Iapp = I_vec(kI);

    [v, gxPrev, gyPrev] = solve_network_nonlinear(net, spec, params, T, Iapp, gxPrev, gyPrev);

    for kp = 1:numel(pairNames)
        pairName = pairNames{kp};
        probes = spec.probePairs.(pairName);
        Vp = mean_probe_voltage(net, v, probes{1});
        Vm = mean_probe_voltage(net, v, probes{2});
        result.V4p.(pairName)(kI) = Vp - Vm;
        if abs(Iapp) > 0
            result.R4p.(pairName)(kI) = (Vp - Vm) / Iapp;
        else
            result.R4p.(pairName)(kI) = NaN;
        end
    end
end

end

