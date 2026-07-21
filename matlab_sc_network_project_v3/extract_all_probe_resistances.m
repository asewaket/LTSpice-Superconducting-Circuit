function R = extract_all_probe_resistances(net, spec, v, Iapp)
%EXTRACT_ALL_PROBE_RESISTANCES Return all named four-probe resistances.

R = struct();
pairNames = fieldnames(spec.probePairs);

for kp = 1:numel(pairNames)
    pairName = pairNames{kp};
    probes = spec.probePairs.(pairName);
    Vp = mean_probe_voltage(net, v, probes{1});
    Vm = mean_probe_voltage(net, v, probes{2});
    R.(pairName) = (Vp - Vm) / Iapp;
end

end

