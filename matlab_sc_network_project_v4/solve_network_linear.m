function [v, Ix, Iy] = solve_network_linear(net, gx, gy, Iapp)
%SOLVE_NETWORK_LINEAR Current-biased solve on an arbitrary active mask.

active = net.active;
[Ny, Nx] = size(active);

groundCandidates = find(net.drainMask & active, 1, 'first');
if isempty(groundCandidates)
    groundCandidates = find(active, 1, 'last');
end

unknown = active;
unknown(groundCandidates) = false;

map = zeros(Ny, Nx);
map(unknown) = 1:nnz(unknown);
Nu = nnz(unknown);

ii = zeros(5*Nu,1);
jj = zeros(5*Nu,1);
ss = zeros(5*Nu,1);
entry = 0;
b = zeros(Nu,1);

src = net.sourceMask & active;
drn = net.drainMask & active;
nsrc = nnz(src);
ndrn = nnz(drn);

for col = 1:Nx
    for row = 1:Ny
        if ~unknown(row,col)
            continue;
        end

        p = map(row,col);
        diagVal = 0;

        if src(row,col)
            b(p) = b(p) + Iapp / nsrc;
        end
        if drn(row,col)
            b(p) = b(p) - Iapp / ndrn;
        end

        % Left neighbor
        if col > 1
            g = gx(row,col-1);
            if g > 0 && isfinite(g)
                diagVal = diagVal + g;
                if unknown(row,col-1)
                    entry = entry + 1;
                    ii(entry) = p;
                    jj(entry) = map(row,col-1);
                    ss(entry) = -g;
                end
            end
        end

        % Right neighbor
        if col < Nx
            g = gx(row,col);
            if g > 0 && isfinite(g)
                diagVal = diagVal + g;
                if unknown(row,col+1)
                    entry = entry + 1;
                    ii(entry) = p;
                    jj(entry) = map(row,col+1);
                    ss(entry) = -g;
                end
            end
        end

        % Lower-y neighbor
        if row > 1
            g = gy(row-1,col);
            if g > 0 && isfinite(g)
                diagVal = diagVal + g;
                if unknown(row-1,col)
                    entry = entry + 1;
                    ii(entry) = p;
                    jj(entry) = map(row-1,col);
                    ss(entry) = -g;
                end
            end
        end

        % Upper-y neighbor
        if row < Ny
            g = gy(row,col);
            if g > 0 && isfinite(g)
                diagVal = diagVal + g;
                if unknown(row+1,col)
                    entry = entry + 1;
                    ii(entry) = p;
                    jj(entry) = map(row+1,col);
                    ss(entry) = -g;
                end
            end
        end

        entry = entry + 1;
        ii(entry) = p;
        jj(entry) = p;
        ss(entry) = diagVal;
    end
end

G = sparse(ii(1:entry), jj(1:entry), ss(1:entry), Nu, Nu);
u = G \ b;

v = zeros(Ny, Nx);
v(unknown) = u(map(unknown));
v(~active) = NaN;

[Ix, Iy] = compute_link_currents(v, gx, gy, net);

end

function [Ix, Iy] = compute_link_currents(v, gx, gy, net)

[Ny, Nx] = size(v);
Ix = zeros(Ny, Nx-1);
Iy = zeros(Ny-1, Nx);

for row = 1:Ny
    for col = 1:Nx-1
        if net.link.activeX(row,col)
            Ix(row,col) = gx(row,col) * (v(row,col) - v(row,col+1));
        end
    end
end

for row = 1:Ny-1
    for col = 1:Nx
        if net.link.activeY(row,col)
            Iy(row,col) = gy(row,col) * (v(row,col) - v(row+1,col));
        end
    end
end

end
