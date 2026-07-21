function [v, gx, gy] = solve_network_nonlinear(net, spec, params, T, Iapp, gxInit, gyInit)
%SOLVE_NETWORK_NONLINEAR Fixed-point nonlinear solve using local branch current.

gx = gxInit;
gy = gyInit;

for iter = 1:spec.solver.maxIter
    gxOld = gx;
    gyOld = gy;

    [v, Ix, Iy] = solve_network_linear(net, gx, gy, Iapp);

    [RxNew, RyNew] = link_resistance_TI(params, spec, T, abs(Ix), abs(Iy));
    gxTarget = safe_conductance(RxNew, net.link.activeX);
    gyTarget = safe_conductance(RyNew, net.link.activeY);

    gx = (1 - spec.solver.alpha) * gxOld + spec.solver.alpha * gxTarget;
    gy = (1 - spec.solver.alpha) * gyOld + spec.solver.alpha * gyTarget;

    errX = norm(gx(:) - gxOld(:)) / max(norm(gxOld(:)), eps);
    errY = norm(gy(:) - gyOld(:)) / max(norm(gyOld(:)), eps);

    if max(errX, errY) < spec.solver.tolG
        [v, ~, ~] = solve_network_linear(net, gx, gy, Iapp);
        return;
    end
end

warning('Nonlinear solve reached maxIter for %s at T=%.3g K, I=%.3g A.', spec.name, T, Iapp);
[v, ~, ~] = solve_network_linear(net, gx, gy, Iapp);

end

