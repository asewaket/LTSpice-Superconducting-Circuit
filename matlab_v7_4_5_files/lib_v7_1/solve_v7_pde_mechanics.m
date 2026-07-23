function pde = solve_v7_pde_mechanics(spec, opts)
%SOLVE_V7_PDE_MECHANICS Solve a first PDE mechanical proxy for one device.
%
% v7.1 uses a device-aware flake outline when one is provided by
% make_device_spec. This remains a normalized plane-stress proxy, but the
% finite-element body is no longer forced to be a perfect rectangle.

if nargin < 2 || isempty(opts)
    opts = make_v7_pde_options(spec);
end

require_pde_toolbox();

L = spec.geom.activeLength_um;
W = spec.geom.channelWidth_um;

model = createpde('structural', 'static-planestress');
g = make_v71_pde_geometry(spec, L, W);
geometryFromEdges(model, g);
edgeInfo = classify_v71_geometry_edges(model, spec, L, W);

structuralProperties(model, ...
    'YoungsModulus', opts.material.YoungsModulus, ...
    'PoissonsRatio', opts.material.PoissonsRatio);

% Remove rigid-body motion. The support edges are a numerical anchor chosen
% from the source-side boundary of the actual scaffold geometry, not a claim
% that the entire experimental left edge is rigidly clamped.
structuralBC(model, 'Edge', edgeInfo.supportEdges, 'Constraint', 'fixed');

% Film-force sign is retained. Negative MgO film force is treated as an
% opposite-direction x-traction on the covered edge. The field is normalized
% later, so this encodes spatial pattern and sign, not calibrated strain.
amp = min(1, abs(spec.filmForce_Npm) / opts.load.forceScale_Npm);
sgn = sign_with_zero(spec.filmForce_Npm);
traction = opts.load.tractionScale * amp * sgn;

coveredEdge = covered_edge_for_spec(spec, opts, edgeInfo);
structuralBoundaryLoad(model, 'Edge', coveredEdge, ...
    'SurfaceTraction', [traction; 0]);

if opts.load.applyOppositeEdgeRelaxation
    oppositeEdge = opposite_covered_edge(coveredEdge, opts, edgeInfo);
    if ~isempty(oppositeEdge)
        structuralBoundaryLoad(model, 'Edge', oppositeEdge, ...
            'SurfaceTraction', [-opts.load.oppositeEdgeTractionFraction * traction; 0]);
    end
end

mesh = generateMesh(model, ...
    'Hmax', opts.mesh.Hmax_um, ...
    'Hmin', opts.mesh.Hmin_um, ...
    'Hgrad', opts.mesh.Hgrad);

solution = solve(model);

pde = struct();
pde.model = model;
pde.mesh = mesh;
pde.solution = solution;
pde.coveredEdge = coveredEdge;
pde.edgeInfo = edgeInfo;
pde.appliedTraction = traction;
pde.forceAmplitude = amp;
pde.forceSign = sgn;
pde.description = sprintf('%s PDE plane-stress proxy, %s', ...
    spec.name, spec.filmForceLabel);

end

function g = make_v71_pde_geometry(spec, L, W)

if isfield(spec, 'flakeOutline') && isfield(spec.flakeOutline, 'enabled') && ...
        spec.flakeOutline.enabled
    xv = spec.flakeOutline.x_um(:)';
    yv = spec.flakeOutline.y_um(:)';
    if numel(xv) ~= numel(yv) || numel(xv) < 3
        error('Invalid flakeOutline for %s.', spec.name);
    end
    P1 = [2; numel(xv); xv(:); yv(:)];
    gd = P1;
    ns = char('P1')';
    sf = 'P1';
else
    R1 = [3; 4; -L/2; L/2; L/2; -L/2; -W/2; -W/2; W/2; W/2];
    gd = R1;
    ns = char('R1')';
    sf = 'R1';
end

g = decsg(gd, sf, ns);

end

function edgeInfo = classify_v71_geometry_edges(model, spec, L, W)

nEdges = model.Geometry.NumEdges;
mid = NaN(nEdges, 2);

for eid = 1:nEdges
    try
        p = evaluate(model.Geometry, eid, linspace(0, 1, 7));
        mid(eid,:) = finite_row_mean(p(1:2,:));
    catch
        mid(eid,:) = fallback_edge_midpoint(eid, L, W);
    end
end

valid = all(isfinite(mid), 2);
if ~any(valid)
    edgeInfo = rectangle_edge_info();
    return;
end

xv = mid(valid,1);
yv = mid(valid,2);
xRange = max(xv) - min(xv);
yRange = max(yv) - min(yv);
xTol = max(0.12 * xRange, spec.geom.currentContactDepth_um);
yTol = max(0.18 * yRange, spec.geom.boundaryWidth_um);

edgeIDs = (1:nEdges)';
leftEdges = edgeIDs(valid & mid(:,1) <= min(xv) + xTol);
rightEdges = edgeIDs(valid & mid(:,1) >= max(xv) - xTol);
bottomEdges = edgeIDs(valid & mid(:,2) <= min(yv) + yTol);
topEdges = edgeIDs(valid & mid(:,2) >= max(yv) - yTol);

if isempty(leftEdges), leftEdges = 4; end
if isempty(rightEdges), rightEdges = 2; end
if isempty(bottomEdges), bottomEdges = 1; end
if isempty(topEdges), topEdges = 3; end

edgeInfo = struct();
edgeInfo.midpoints = mid;
edgeInfo.leftEdges = leftEdges(:)';
edgeInfo.rightEdges = rightEdges(:)';
edgeInfo.bottomEdges = bottomEdges(:)';
edgeInfo.topEdges = topEdges(:)';
edgeInfo.supportEdges = leftEdges(:)';
edgeInfo.note = 'v7.1 edge classes inferred from finite-element boundary midpoints.';

end

function m = finite_row_mean(p)

m = NaN(1, size(p, 1));
for row = 1:size(p, 1)
    vals = p(row, isfinite(p(row,:)));
    if ~isempty(vals)
        m(row) = mean(vals);
    end
end

end

function mid = fallback_edge_midpoint(eid, L, W)

switch eid
    case 1
        mid = [0, -W/2];
    case 2
        mid = [L/2, 0];
    case 3
        mid = [0, W/2];
    case 4
        mid = [-L/2, 0];
    otherwise
        mid = [NaN, NaN];
end

end

function edgeInfo = rectangle_edge_info()

edgeInfo = struct();
edgeInfo.midpoints = [];
edgeInfo.leftEdges = 4;
edgeInfo.rightEdges = 2;
edgeInfo.bottomEdges = 1;
edgeInfo.topEdges = 3;
edgeInfo.supportEdges = 4;
edgeInfo.note = 'v7.1 fallback rectangle edge convention.';

end

function require_pde_toolbox()

if ~(exist('createpde', 'file') == 2 || exist('createpde', 'builtin') == 5)
    error(['PDE Toolbox function createpde was not found. ', ...
        'Install Partial Differential Equation Toolbox before running v7.']);
end

end

function s = sign_with_zero(x)

if x > 0
    s = 1;
elseif x < 0
    s = -1;
else
    s = 0;
end

end

function edgeID = covered_edge_for_spec(spec, opts, edgeInfo)

switch spec.geometryClass
    case 'half'
        switch spec.coveredSide
            case 'top'
                edgeID = edgeInfo.topEdges;
            case 'bottom'
                edgeID = edgeInfo.bottomEdges;
            otherwise
                edgeID = opts.edge.bottom;
        end
    case {'full','cracked_full'}
        edgeID = setdiff(unique([edgeInfo.bottomEdges edgeInfo.topEdges edgeInfo.rightEdges]), ...
            edgeInfo.supportEdges);
        if isempty(edgeID)
            edgeID = edgeInfo.bottomEdges;
        end
    otherwise
        edgeID = opts.edge.bottom;
end

end

function edgeID = opposite_covered_edge(coveredEdge, opts, edgeInfo)

if isequal(sort(coveredEdge), sort(edgeInfo.bottomEdges))
    edgeID = edgeInfo.topEdges;
elseif isequal(sort(coveredEdge), sort(edgeInfo.topEdges))
    edgeID = edgeInfo.bottomEdges;
elseif isequal(sort(coveredEdge), sort(edgeInfo.leftEdges))
    edgeID = edgeInfo.rightEdges;
else
    edgeID = [];
end

end
