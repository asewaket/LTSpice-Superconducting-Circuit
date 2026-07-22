function cases = make_v743_wij_ablation_cases(opts)
%MAKE_V743_WIJ_ABLATION_CASES Build controlled W_ij topology cases.
%
% For each gammaW/pW pair, the same underlying full W_ij field is transformed
% into topology ablations:
%   full weak-link model, uniform W, shuffled W, boundary/crack off, and
%   central-lane topology.  A no-weak-links reference is included separately.

if nargin < 1
    opts = make_v743_wij_ablation_options();
end

rows = {};
rows(end+1,:) = {'no_weak_links', 'no weak links', 'none', NaN, 0};

for ig = 1:numel(opts.gammaW_values)
    gammaW = opts.gammaW_values(ig);
    for ip = 1:numel(opts.pW_values)
        pW = opts.pW_values(ip);
        tag = sprintf('g%g_p%g', gammaW, pW);
        tag = regexprep(tag, '[^a-zA-Z0-9]+', '_');

        rows(end+1,:) = {sprintf('full_%s', tag), ...
            sprintf('full W_{ij}, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'full', gammaW, pW}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('uniform_%s', tag), ...
            sprintf('uniform W, same mean, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'uniform', gammaW, pW}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('shuffled_%s', tag), ...
            sprintf('shuffled W histogram, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'shuffled', gammaW, pW}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('boundary_off_%s', tag), ...
            sprintf('boundary/crack W mask off, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'boundary_off', gammaW, pW}; %#ok<AGROW>
        rows(end+1,:) = {sprintf('central_lane_%s', tag), ...
            sprintf('central-lane topology, \\gamma_W=%g, p_W=%g', gammaW, pW), ...
            'central_lane', gammaW, pW}; %#ok<AGROW>
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
end

end
