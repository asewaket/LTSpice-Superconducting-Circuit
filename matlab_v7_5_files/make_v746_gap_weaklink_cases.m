function cases = make_v746_gap_weaklink_cases(opts)
%MAKE_V746_GAP_WEAKLINK_CASES Build gap-tied weak-link class cases.
%
% Each case keeps the same Tc/Rn/proxy/disorder realization.  The ablated
% quantity is the weak-link class/transparency field used to convert the
% local gap scale into Ic.  Uniform/shuffled/central-lane controls are
% retained so topology can still be separated from a mere transparency
% histogram.

if nargin < 1
    opts = make_v746_gap_weaklink_options();
end

rows = {};
rows(end+1,:) = {'bulk_AB_reference', 'bulk AB reference: no weak-link mask', ...
    'none', 'bulk_sns', NaN, 0, 1.0, opts.alphaGap.priorMean}; %#ok<AGROW>

for ia = 1:numel(opts.alphaGap.values)
    alphaGap = opts.alphaGap.values(ia);
    for ig = 1:numel(opts.gammaW_values)
        gammaW = opts.gammaW_values(ig);
        for ip = 1:numel(opts.pW_values)
            pW = opts.pW_values(ip);
            tag = sprintf('a%g_g%g_p%g', alphaGap, gammaW, pW);
            tag = regexprep(tag, '[^a-zA-Z0-9]+', '_');

            rows(end+1,:) = {sprintf('boundary_sns_%s', tag), ...
                sprintf('SNS-like boundary constriction, alpha=%g, tau=%g, p=%g', alphaGap, gammaW, pW), ...
                'boundary_lane', 'boundary_constriction', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
            rows(end+1,:) = {sprintf('contact_relaxed_%s', tag), ...
                sprintf('contact-relaxed SNS links, alpha=%g, tau=%g, p=%g', alphaGap, gammaW, pW), ...
                'contact_relaxation', 'contact_relaxed', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
            rows(end+1,:) = {sprintf('crack_tunnel_%s', tag), ...
                sprintf('tunnel/crack-like links, alpha=%g, tau=%g, p=%g', alphaGap, gammaW, pW), ...
                'tear_lane', 'crack_tunnel', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
            rows(end+1,:) = {sprintf('combined_%s', tag), ...
                sprintf('combined weak-link classes, alpha=%g, tau=%g, p=%g', alphaGap, gammaW, pW), ...
                'combined', 'boundary_constriction', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
        end
    end
end

% A small set of topology-only controls at the central prior value avoids a
% large factorial sweep while keeping the important null tests.
alphaGap = opts.alphaGap.priorMean;
gammaW = 0.010;
pW = 0.08;
rows(end+1,:) = {'uniform_tau_control', 'same mean weak transparency, spatially uniform', ...
    'uniform', 'boundary_constriction', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
rows(end+1,:) = {'shuffled_tau_control', 'same weak-link histogram, shuffled positions', ...
    'shuffled', 'boundary_constriction', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
rows(end+1,:) = {'central_lane_gap_control', 'central-lane topology with same gap-derived links', ...
    'central_lane', 'boundary_constriction', gammaW, pW, 1.0, alphaGap}; %#ok<AGROW>
rows(end+1,:) = {'anisotropic_gap_control', 'anisotropic weak-link transparency', ...
    'anisotropic', 'anisotropic', gammaW, pW, opts.anisotropyFactorY, alphaGap}; %#ok<AGROW>

n = size(rows, 1);
cases = repmat(struct(), n, 1);
for k = 1:n
    cases(k).name = string(rows{k,1});
    cases(k).description = string(rows{k,2});
    cases(k).topology = string(rows{k,3});
    cases(k).linkClass = string(rows{k,4});
    cases(k).gammaW = rows{k,5};
    cases(k).pW = rows{k,6};
    cases(k).anisotropyFactor = rows{k,7};
    cases(k).alphaGap = rows{k,8};
end

end
