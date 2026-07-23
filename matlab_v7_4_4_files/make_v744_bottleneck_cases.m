function cases = make_v744_bottleneck_cases(opts)
%MAKE_V744_BOTTLENECK_CASES Build physical bottleneck W_ij topology cases.
%
% For each gammaW/pW pair, v7.4.4 tests named bottleneck mechanisms:
% boundary/crack lane, contact relaxation, current crowding, tear-like lane,
% anisotropic transparency, combined physical bottleneck, and the old
% central-lane limiting case.  Uniform and shuffled controls are retained.

if nargin < 1
    opts = make_v744_bottleneck_options();
end

rows = {};
rows(end+1,:) = {'no_weak_links', 'no weak links', 'none', NaN, 0, 1.0};

for ig = 1:numel(opts.gammaW_values)
    gammaW = opts.gammaW_values(ig);
    for ip = 1:numel(opts.pW_values)
        pW = opts.pW_values(ip);
        tag = sprintf('g%g_p%g', gammaW, pW);
        tag = regexprep(tag, '[^a-zA-Z0-9]+', '_');

        rows(end+1,:) = {sprintf('combined_%s', tag), ...
            sprintf('combined physical bottleneck, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'combined', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('boundary_lane_%s', tag), ...
            sprintf('coverage-boundary lane, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'boundary_lane', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('contact_relaxation_%s', tag), ...
            sprintf('metal-contact relaxation halos, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'contact_relaxation', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('current_crowding_%s', tag), ...
            sprintf('source/drain and probe current-crowding bottlenecks, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'current_crowding', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('tear_lane_%s', tag), ...
            sprintf('tear-like interrupted lane, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'tear_lane', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('anisotropic_%s', tag), ...
            sprintf('anisotropic weak transparency, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'anisotropic', gammaW, pW, opts.anisotropyFactorY}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('uniform_%s', tag), ...
            sprintf('uniform W, same mean, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'uniform', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('shuffled_%s', tag), ...
            sprintf('shuffled W histogram, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'shuffled', gammaW, pW, 1.0}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('central_lane_%s', tag), ...
            sprintf('central-lane topology, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'central_lane', gammaW, pW, 1.0}; %#ok<AGROW>
    end
end

n = size(rows, 1);
cases = repmat(struct(), n, 1);
for k = 1:n
    cases(k).name = string(rows{k,1});
    cases(k).description = string(rows{k,2});
    cases(k).topology = string(rows{k,3});
    cases(k).gammaW = rows{k,4};
    cases(k).pW = rows{k,5};
    cases(k).anisotropyFactor = rows{k,6};
end

end
