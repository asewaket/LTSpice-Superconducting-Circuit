function out = score_probe_transfer(device, mechanism, expRT, cfg)
%SCORE_PROBE_TRANSFER Placeholder Level-B probe/asymmetry scorer.

out = struct();
out.device = string(device);
out.mechanism = string(mechanism);
out.available = false;
out.score = NaN;
out.note = "Level B not active: probe/asymmetry transfer scorer is scaffolded only.";

if nargin >= 3 && isfield(expRT, 'pairData') && ...
        isfield(expRT.pairData, 'available') && expRT.pairData.available
    out.note = "Probe data detected; Level B scorer still pending.";
end
end
