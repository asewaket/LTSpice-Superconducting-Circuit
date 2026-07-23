function opts = make_v7_pde_options(spec)
%MAKE_V7_PDE_OPTIONS Options for the first PDE-informed v7 scaffold.
%
% v7.1 is a geometry/PDE bridge, not yet a calibrated mechanical
% reconstruction. It replaces the hand-built eta proxy with a PDE-derived
% strain/displacement proxy plus explicit contact-relaxation masks.

if nargin < 1 || isempty(spec)
    spec = make_device_spec('AS006');
end

opts = struct();

% PDE geometry and mesh. Units are micrometers for geometry coordinates. The
% first scaffold uses normalized mechanical fields, so the absolute elastic
% scale is less important than spatial pattern.
opts.mesh.Hmax_um = 0.35;
opts.mesh.Hmin_um = 0.08;
opts.mesh.Hgrad = 1.35;

% Plane-stress material values. These are placeholders for the effective
% flake/support system, not final MoTe2 elastic constants.
opts.material.YoungsModulus = 1.0;
opts.material.PoissonsRatio = 0.30;

% Rectangle edge convention from decsg rectangle used here:
% 1 bottom, 2 right, 3 top, 4 left.
opts.edge.left = 4;
opts.edge.right = 2;
opts.edge.bottom = 1;
opts.edge.top = 3;

% Convert film force sign/magnitude into a normalized traction proxy. This is
% intentionally dimensionless in v7.1; future versions can replace it with
% calibrated stressor eigenstrain or traction.
opts.load.forceScale_Npm = 40;
opts.load.tractionScale = 1.0;
opts.load.applyOppositeEdgeRelaxation = true;
opts.load.oppositeEdgeTractionFraction = 0.20;

% Contact/support relaxation mask. Source/drain and voltage probes are not
% yet subdomains in the PDE mesh, but they are explicit spatial regions that
% suppress the final superconductivity-driving eta map.
opts.contact.sourceDrainRelaxWidth_um = 0.85;
opts.contact.probeRelaxWidth_um = 0.65;
opts.contact.gaussianSigma_um = 0.45;
opts.contact.relaxationStrength = 0.50;

% Mapping from PDE fields to superconducting-network eta. These weights are
% deliberately separated so v7 can test whether strain-gradient/current-path
% features or contact relaxation dominate the transport mismatch.
opts.map.strainWeight = 1.00;
opts.map.displacementWeight = 0.25;
opts.map.boundaryWeight = 0.35;
opts.map.stressorMaskWeight = 0.18;
opts.map.contactSuppressionWeight = 0.55;
opts.map.smoothSigma_um = 0.35;
opts.map.clipMin = 0;
opts.map.clipMax = 1;

% Transport settings for the AS006 scaffold.
opts.transport.T_vec = linspace(0.05, 2.20, 140);
opts.transport.Iprobe = 1e-8;
opts.transport.seedOffset = 7000;

opts.output.device = spec.name;
opts.output.versionLabel = sprintf('v7.1 PDE-informed %s scaffold', spec.name);

end
