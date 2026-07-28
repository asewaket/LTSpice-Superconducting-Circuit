function out = score_nonlinear_transfer(device, mechanism, expField, cfg)
%SCORE_NONLINEAR_TRANSFER Placeholder Level-C nonlinear/field scorer.

out = struct();
out.device = string(device);
out.mechanism = string(mechanism);
out.available = false;
out.score = NaN;
out.note = "Level C not active: nonlinear transfer scorer is scaffolded only.";

if nargin >= 3 && isfield(expField, 'available') && expField.available
    out.note = "Nonlinear field data detected; use AS006 v7.4.6/Phase 4 anchor scorer.";
end
end
