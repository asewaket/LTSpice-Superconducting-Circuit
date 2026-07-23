%% superconducting_resistor_array_demo.m
%
% Simulation of a 2D square array of superconducting resistor links.
%
% Each nearest-neighbor link is assigned a triple:
%
%       (Rn, Tc, Ic)
%
% where:
%   Rn = normal-state resistance
%   Tc = local superconducting transition temperature
%   Ic = local critical current
%
% The array is modeled as an N x N grid of nodes connected by nearest-
% neighbor nonlinear resistive links.
%
% The program computes:
%
%   1. Effective resistance vs temperature, R_eff(T)
%   2. I-V curves at selected temperatures
%
% MB/ChatGPT draft, July 2026

clear; close all; clc;

%% ================================================================
%  User parameters
%  ================================================================

N = 4;                      % Number of nodes along each side

Rn_mean = 1.0;               % Ohms
Rn_sigma = 0.15;             % Fractional standard deviation

Tc_mean = 90.0;              % K
Tc_sigma = 1.0;              % K

Ic_mean = 1e-3;              % A
Ic_sigma = 0.25;             % Fractional standard deviation

Rsc = 1e-6;                  % Small residual superconducting resistance
dT = 0.15;                   % Transition width in K
dI_frac = 0.05;              % Current-transition width as fraction of Ic

T_vec = linspace(86, 94, 161);

T_IV_list = [88.5, 89.5, 90.5, 91.5];    % Temperatures for I-V curves
Iapp_vec = linspace(0, 8e-3, 121);        % Applied total current values

V_left = 1.0;                % Voltage used for small-signal R(T) solve
V_right = 0.0;

max_iter = 200;              % Nonlinear iteration limit
tol_g = 1e-6;                % Relative conductance convergence tolerance
alpha = 0.25;                % Conductance update damping

rng(1);                      % Reproducibility


%% ================================================================
%  Create random link parameter matrices
%  ================================================================
%
% Horizontal links connect node (row,col) to (row,col+1).
% Size: N x (N-1)
%
% Vertical links connect node (row,col) to (row+1,col).
% Size: (N-1) x N

[Rn_x, Tc_x, Ic_x, Rn_y, Tc_y, Ic_y] = make_random_link_matrices( ...
    N, Rn_mean, Rn_sigma, Tc_mean, Tc_sigma, Ic_mean, Ic_sigma);


%% ================================================================
%  Compute R_eff(T)
%  ================================================================

R_eff = zeros(size(T_vec));

for k = 1:length(T_vec)

    T = T_vec(k);

    % For small-signal R(T), use only temperature-dependent resistance.
    Rx = link_resistance_T(Rn_x, Tc_x, T, dT, Rsc);
    Ry = link_resistance_T(Rn_y, Tc_y, T, dT, Rsc);

    gx = 1 ./ Rx;
    gy = 1 ./ Ry;

    [v, Itot] = solve_network_fixed_voltage(N, gx, gy, V_left, V_right);

    R_eff(k) = (V_left - V_right) / Itot;

end


%% ================================================================
%  Compute I-V curves
%  ================================================================

IV_data = struct();

for kt = 1:length(T_IV_list)

    T = T_IV_list(kt);

    Vout = zeros(size(Iapp_vec));

    % Start nonlinear conductance guess from temperature-only conductance
    Rx0 = link_resistance_T(Rn_x, Tc_x, T, dT, Rsc);
    Ry0 = link_resistance_T(Rn_y, Tc_y, T, dT, Rsc);

    gx_init = 1 ./ Rx0;
    gy_init = 1 ./ Ry0;

    gx_prev_bias = gx_init;
    gy_prev_bias = gy_init;

    for ki = 1:length(Iapp_vec)

        Iapp = Iapp_vec(ki);

        [v, gx_sol, gy_sol] = solve_network_current_biased_nonlinear( ...
            N, Iapp, T, Rn_x, Tc_x, Ic_x, Rn_y, Tc_y, Ic_y, ...
            Rsc, dT, dI_frac, gx_prev_bias, gy_prev_bias, ...
            max_iter, tol_g, alpha);

        % Terminal voltage is average left-edge voltage minus average
        % right-edge voltage.
        V_L = mean(v(:,1));
        V_R = mean(v(:,N));

        Vout(ki) = V_L - V_R;

        % Use previous current point as next initial condition
        gx_prev_bias = gx_sol;
        gy_prev_bias = gy_sol;

    end

    IV_data(kt).T = T;
    IV_data(kt).I = Iapp_vec;
    IV_data(kt).V = Vout;

end


%% ================================================================
%  Plot results
%  ================================================================

figure;
plot(T_vec, R_eff, 'LineWidth', 2);
grid on;
xlabel('Temperature T [K]');
ylabel('Effective Resistance R_{eff} [\Omega]');
title(sprintf('R(T) of %d x %d superconducting resistor array', N, N));

figure;
hold on;
for kt = 1:length(IV_data)
    plot(IV_data(kt).I * 1e3, IV_data(kt).V, 'LineWidth', 2, ...
        'DisplayName', sprintf('T = %.2f K', IV_data(kt).T));
end
grid on;
xlabel('Applied Current I [mA]');
ylabel('Voltage V [V]');
title(sprintf('I-V curves of %d x %d superconducting resistor array', N, N));
legend('Location', 'northwest');


%% ================================================================
%  Optional: visualize the random Tc distribution of the links
%  ================================================================

figure;
subplot(1,2,1);
imagesc(Tc_x);
axis image;
colorbar;
title('Horizontal-link T_c matrix');
xlabel('column');
ylabel('row');

subplot(1,2,2);
imagesc(Tc_y);
axis image;
colorbar;
title('Vertical-link T_c matrix');
xlabel('column');
ylabel('row');


%% =================================================================
%  Local functions
%  =================================================================

function [Rn_x, Tc_x, Ic_x, Rn_y, Tc_y, Ic_y] = make_random_link_matrices( ...
    N, Rn_mean, Rn_sigma, Tc_mean, Tc_sigma, Ic_mean, Ic_sigma)

    % Horizontal links: N x (N-1)
    Rn_x = Rn_mean * (1 + Rn_sigma * randn(N, N-1));
    Tc_x = Tc_mean + Tc_sigma * randn(N, N-1);
    Ic_x = Ic_mean * (1 + Ic_sigma * randn(N, N-1));

    % Vertical links: (N-1) x N
    Rn_y = Rn_mean * (1 + Rn_sigma * randn(N-1, N));
    Tc_y = Tc_mean + Tc_sigma * randn(N-1, N);
    Ic_y = Ic_mean * (1 + Ic_sigma * randn(N-1, N));

    % Prevent unphysical negative values
    Rn_x = max(Rn_x, 0.05 * Rn_mean);
    Rn_y = max(Rn_y, 0.05 * Rn_mean);

    Ic_x = max(Ic_x, 0.02 * Ic_mean);
    Ic_y = max(Ic_y, 0.02 * Ic_mean);

end


function R = link_resistance_T(Rn, Tc, T, dT, Rsc)

    % Smooth superconducting transition.
    %
    % For T << Tc, R -> Rsc.
    % For T >> Tc, R -> Rn.
    %
    % S_T goes from 0 to 1 as T rises through Tc.

    S_T = 1 ./ (1 + exp(-(T - Tc) ./ dT));

    R = Rsc + (Rn - Rsc) .* S_T;

end


function R = link_resistance_TI(Rn, Tc, Ic, T, Iabs, dT, dI_frac, Rsc)

    % Smooth temperature- and current-dependent resistance.
    %
    % The resistance is low only when:
    %   T < Tc and |I| < Ic.
    %
    % Either high temperature or excessive current drives the link toward Rn.

    S_T = 1 ./ (1 + exp(-(T - Tc) ./ dT));

    dI = dI_frac .* Ic;
    S_I = 1 ./ (1 + exp(-(Iabs - Ic) ./ dI));

    % Combine temperature and current switching.
    %
    % A link becomes resistive if either temperature or current causes
    % switching. This OR-like combination is:
    %
    %   S = 1 - (1 - S_T)(1 - S_I)

    S = 1 - (1 - S_T) .* (1 - S_I);

    R = Rsc + (Rn - Rsc) .* S;

end


function idx = node_index(row, col, N)

    % Map 2D node coordinate to 1D index.
    %
    % row = 1...N
    % col = 1...N

    idx = row + (col - 1) * N;

end


function [G, b] = build_laplacian_fixed_voltage(N, gx, gy, V_left, V_right)

    % Build sparse system for unknown interior node voltages.
    %
    % Left edge is fixed to V_left.
    % Right edge is fixed to V_right.
    %
    % Unknown nodes are columns 2 through N-1.
    %
    % gx is N x (N-1)
    % gy is (N-1) x N

    unknown = false(N, N);
    unknown(:,2:N-1) = true;

    map = zeros(N, N);
    counter = 0;

    for col = 1:N
        for row = 1:N
            if unknown(row,col)
                counter = counter + 1;
                map(row,col) = counter;
            end
        end
    end

    Nu = counter;

    ii = [];
    jj = [];
    ss = [];
    b = zeros(Nu, 1);

    for col = 2:N-1
        for row = 1:N

            p = map(row,col);
            diag_val = 0;

            % Left neighbor
            g = gx(row,col-1);
            diag_val = diag_val + g;
            if col-1 == 1
                b(p) = b(p) + g * V_left;
            else
                q = map(row,col-1);
                ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
            end

            % Right neighbor
            g = gx(row,col);
            diag_val = diag_val + g;
            if col+1 == N
                b(p) = b(p) + g * V_right;
            else
                q = map(row,col+1);
                ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
            end

            % Up neighbor
            if row > 1
                g = gy(row-1,col);
                diag_val = diag_val + g;
                q = map(row-1,col);
                ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
            end

            % Down neighbor
            if row < N
                g = gy(row,col);
                diag_val = diag_val + g;
                q = map(row+1,col);
                ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
            end

            ii(end+1) = p; jj(end+1) = p; ss(end+1) = diag_val;

        end
    end

    G = sparse(ii, jj, ss, Nu, Nu);

end


function [v, Itot] = solve_network_fixed_voltage(N, gx, gy, V_left, V_right)

    % Solve linear resistor network with left and right edges fixed.

    [G, b] = build_laplacian_fixed_voltage(N, gx, gy, V_left, V_right);

    u = G \ b;

    v = zeros(N, N);
    v(:,1) = V_left;
    v(:,N) = V_right;

    counter = 0;
    for col = 2:N-1
        for row = 1:N
            counter = counter + 1;
            v(row,col) = u(counter);
        end
    end

    % Total current entering from the left electrode through the links
    % between column 1 and column 2.
    Itot = sum(gx(:,1) .* (v(:,1) - v(:,2)));

end


function [G, b, unknown, map] = build_laplacian_current_biased(N, gx, gy, Iapp)

    % Build sparse system for a current-biased solve.
    %
    % Current is injected uniformly along the left edge and removed
    % uniformly along the right edge.
    %
    % To fix the voltage gauge, the lower-right node is grounded:
    %
    %       v(N,N) = 0
    %
    % All other node voltages are unknown.

    ground_row = N;
    ground_col = N;

    unknown = true(N, N);
    unknown(ground_row, ground_col) = false;

    map = zeros(N, N);
    counter = 0;

    for col = 1:N
        for row = 1:N
            if unknown(row,col)
                counter = counter + 1;
                map(row,col) = counter;
            end
        end
    end

    Nu = counter;

    ii = [];
    jj = [];
    ss = [];
    b = zeros(Nu, 1);

    for col = 1:N
        for row = 1:N

            if ~unknown(row,col)
                continue;
            end

            p = map(row,col);
            diag_val = 0;

            % External current injection
            if col == 1
                b(p) = b(p) + Iapp / N;
            end

            if col == N
                b(p) = b(p) - Iapp / N;
            end

            % Left neighbor
            if col > 1
                g = gx(row,col-1);
                diag_val = diag_val + g;
                if unknown(row,col-1)
                    q = map(row,col-1);
                    ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
                end
            end

            % Right neighbor
            if col < N
                g = gx(row,col);
                diag_val = diag_val + g;
                if unknown(row,col+1)
                    q = map(row,col+1);
                    ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
                end
            end

            % Up neighbor
            if row > 1
                g = gy(row-1,col);
                diag_val = diag_val + g;
                if unknown(row-1,col)
                    q = map(row-1,col);
                    ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
                end
            end

            % Down neighbor
            if row < N
                g = gy(row,col);
                diag_val = diag_val + g;
                if unknown(row+1,col)
                    q = map(row+1,col);
                    ii(end+1) = p; jj(end+1) = q; ss(end+1) = -g;
                end
            end

            ii(end+1) = p; jj(end+1) = p; ss(end+1) = diag_val;

        end
    end

    G = sparse(ii, jj, ss, Nu, Nu);

end


function v = solve_network_current_biased_linear(N, gx, gy, Iapp)

    % Solve linear network with current injection on left edge and
    % extraction on right edge.

    [G, b, unknown, map] = build_laplacian_current_biased(N, gx, gy, Iapp);

    u = G \ b;

    v = zeros(N, N);

    for col = 1:N
        for row = 1:N
            if unknown(row,col)
                v(row,col) = u(map(row,col));
            else
                v(row,col) = 0.0;
            end
        end
    end

end


function [Ix, Iy] = compute_link_currents(N, v, gx, gy)

    % Compute horizontal and vertical link currents.
    %
    % Ix(row,col) is current from (row,col) to (row,col+1).
    % Iy(row,col) is current from (row,col) to (row+1,col).

    Ix = zeros(N, N-1);
    Iy = zeros(N-1, N);

    for row = 1:N
        for col = 1:N-1
            Ix(row,col) = gx(row,col) * (v(row,col) - v(row,col+1));
        end
    end

    for row = 1:N-1
        for col = 1:N
            Iy(row,col) = gy(row,col) * (v(row,col) - v(row+1,col));
        end
    end

end


function [v, gx, gy] = solve_network_current_biased_nonlinear( ...
    N, Iapp, T, Rn_x, Tc_x, Ic_x, Rn_y, Tc_y, Ic_y, ...
    Rsc, dT, dI_frac, gx_init, gy_init, max_iter, tol_g, alpha)

    % Nonlinear solve by fixed-point iteration.
    %
    % At each iteration:
    %   1. Solve linear network using current conductances.
    %   2. Compute link currents.
    %   3. Update link resistances based on T and |I_link|.
    %   4. Damped conductance update.
    %
    % This is not a full Newton solve, but it is simple and robust enough
    % for first exploration.

    gx = gx_init;
    gy = gy_init;

    for iter = 1:max_iter

        gx_old = gx;
        gy_old = gy;

        v = solve_network_current_biased_linear(N, gx, gy, Iapp);

        [Ix, Iy] = compute_link_currents(N, v, gx, gy);

        Rx_new = link_resistance_TI(Rn_x, Tc_x, Ic_x, T, abs(Ix), ...
            dT, dI_frac, Rsc);

        Ry_new = link_resistance_TI(Rn_y, Tc_y, Ic_y, T, abs(Iy), ...
            dT, dI_frac, Rsc);

        gx_target = 1 ./ Rx_new;
        gy_target = 1 ./ Ry_new;

        gx = (1 - alpha) * gx_old + alpha * gx_target;
        gy = (1 - alpha) * gy_old + alpha * gy_target;

        err_x = norm(gx(:) - gx_old(:)) / max(norm(gx_old(:)), eps);
        err_y = norm(gy(:) - gy_old(:)) / max(norm(gy_old(:)), eps);

        err = max(err_x, err_y);

        if err < tol_g
            break;
        end

    end

    if iter == max_iter
        warning('Nonlinear solve reached max_iter at T = %.3f K, I = %.3g A', ...
            T, Iapp);
    end

end