function V = mean_probe_voltage(net, v, probeName)
%MEAN_PROBE_VOLTAGE Average voltage over a passive probe sense mask.

mask = net.probeMasks.(probeName) & net.active;
vals = v(mask);
vals = vals(isfinite(vals));

if isempty(vals)
    error('Probe %s has no active grid nodes. Refine grid or probe geometry.', probeName);
end

V = mean(vals);

end

