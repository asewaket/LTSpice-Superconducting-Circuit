function out = smooth_random_field(in, sigmaCells)
%SMOOTH_RANDOM_FIELD Gaussian-smoothed random field without toolboxes.

sigmaCells = max(1, sigmaCells);
radius = max(2, ceil(3 * sigmaCells));
x = -radius:radius;
g = exp(-(x.^2) / (2 * sigmaCells^2));
g = g / sum(g);

out = conv2(conv2(in, g, 'same'), g', 'same');
out = out - mean(out(:));
s = std(out(:));
if s > 0
    out = out / s;
end

end
