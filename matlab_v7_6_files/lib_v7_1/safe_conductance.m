function g = safe_conductance(R, activeLink)
%SAFE_CONDUCTANCE Convert resistance to conductance on valid links only.

g = zeros(size(R));
mask = activeLink & isfinite(R) & R > 0;
g(mask) = 1 ./ R(mask);

end
