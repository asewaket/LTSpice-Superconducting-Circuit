function params = calibrate_normal_resistance(net, spec, params)
%CALIBRATE_NORMAL_RESISTANCE Scale Rn so the default normal R4p is sensible.
%
% This gives each device a first-pass absolute resistance scale while leaving
% normalized transition shape controlled by the region distributions.

Tnormal = 4.0;        % K, above all scaffold Tc values
Iprobe = 1e-8;        % A

[Rx, Ry] = link_resistance_T(params, spec, Tnormal);
gx = safe_conductance(Rx, net.link.activeX);
gy = safe_conductance(Ry, net.link.activeY);

v = solve_network_linear(net, gx, gy, Iprobe);
R = extract_all_probe_resistances(net, spec, v, Iprobe);

if isfield(R, 'top_4_10')
    Rnow = R.top_4_10;
else
    names = fieldnames(R);
    Rnow = R.(names{1});
end

if isfinite(Rnow) && Rnow > 0
    scale = spec.targetRN_ohm / Rnow;
    params.RnX = params.RnX * scale;
    params.RnY = params.RnY * scale;
    params.normalScale = scale;
else
    params.normalScale = NaN;
    warning('Normal resistance calibration failed for %s.', spec.name);
end

end

