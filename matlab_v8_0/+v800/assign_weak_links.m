function [netCase, paramsCase, weak] = assign_weak_links(netPDE, spec, baseParams, caseInfo, opts, calibrationMode, normalScale)
%ASSIGN_WEAK_LINKS Canonical W_ij/link-class assignment wrapper.

if nargin < 7
    normalScale = NaN;
end
[netCase, paramsCase, weak] = build_v746_gap_weaklink_case(netPDE, spec, ...
    baseParams, caseInfo, opts, calibrationMode, normalScale);

end

