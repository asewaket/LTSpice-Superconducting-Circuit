function [T, Rnorm, RN] = normalize_rt_curve(T, R, nHigh)
%NORMALIZE_RT_CURVE Normalize R(T) by the high-temperature mean.

if nargin < 3
    nHigh = min(10, numel(R));
end

T = T(:);
R = R(:);

[T, order] = sort(T);
R = R(order);

nHigh = min(nHigh, numel(R));
hi = R(end-nHigh+1:end);
hi = hi(isfinite(hi));

if isempty(hi)
    RN = NaN;
    Rnorm = NaN(size(R));
else
    RN = mean(hi);
    Rnorm = R ./ RN;
end

end
