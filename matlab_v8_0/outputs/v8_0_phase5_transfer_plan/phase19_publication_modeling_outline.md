# Mechanics-Informed Superconducting Network: Publication Outline

## Final Paper-Level Claim

The frozen model supports the following paper-level statement:

> Mechanical heterogeneity organizes superconducting connectivity. A normalized mechanics-derived gradient field improves the frozen two-dimensional superconducting-network model relative to geometry-only, uniform, and spatially randomized controls. Coupling-role ablations indicate that weak-link connectivity carries the dominant transport-relevant effect, while local Tc modulation provides secondary support.

Required caveat:

> The mechanics calculation identifies transport-relevant normalized spatial structure. It is not an absolute device-specific strain-tensor reconstruction.

## Final Scientific Workflow

The paper should present the model as a final workflow, not as a phase history:

1. Six-device experimental hierarchy shows nominal film force alone is insufficient.
2. A two-dimensional superconducting-network framework separates local superconducting strength from connectivity.
3. Forward mechanics identifies normalized mechanical-gradient localization at boundaries and discontinuities.
4. Frozen prior ablation shows the mechanics-derived field outperforms geometry-only, uniform, and randomized controls.
5. Coupling-role ablation shows weak-link connectivity dominates over Tc-only coupling.
6. Final robustness checks show the conclusion survives disorder, grid/coarse-graining, prior normalization, current-overlap nulls, and anchor-device selection.

## Main Figure Architecture

### Figure 1: Experimental Device Hierarchy

Purpose: establish why nominal film force is insufficient.

Suggested panels:

- Device/stressor geometry thumbnails for AS001-AS006.
- Experimental transport summary arranged by device class.
- Evidence hierarchy: unresolved, M0star-sufficient, structured-supported, strong structured support.
- Compact statement that AS005 and AS006 become the mechanistic anchor pair, while AS001-AS003 remain guard devices.

Paper message:

> The device series cannot be explained by a scalar film-force descriptor; geometry, discontinuities, and connectivity must be represented.

### Figure 2: Final Superconducting-Network Architecture

Purpose: introduce the frozen model without implementation history.

Suggested panels:

- Schematic: device geometry -> normalized mechanical localization -> local superconducting landscape and weak-link network -> current redistribution -> four-probe transport.
- Network cartoon distinguishing local Tc field from weak-link/connectivity field W_ij.
- Frozen evidence hierarchy and prohibited operations: no retuning, no relabeling, no absolute strain claim.

Paper message:

> The model separates local superconducting strength from network connectivity and tests mechanics as an upstream spatial prior under frozen downstream rules.

### Figure 3: Normalized Forward Mechanics

Purpose: show that discontinuities generate robust mechanics-derived spatial structure.

Suggested panels:

- AS005 crack geometry and normalized H_gradient map.
- AS006 half-coverage boundary geometry and normalized H_gradient map.
- Descriptor robustness summary showing gradient localization survives bounded uncertainty.
- Explicit label: normalized mechanics-derived localization, not measured strain.

Paper message:

> Cracks and stressor boundaries generate localized normalized mechanical-gradient structure in the forward model.

### Figure 4: Frozen Prior Ablation

Purpose: demonstrate transport relevance of the mechanics field.

Suggested panels:

- Geometry, mechanics-gradient, uniform, and randomized prior comparison.
- Aggregate score comparison, lower is better.
- AS005 and AS006 critical-device contribution.
- Randomized prior distribution or permutation-style spatial-null diagnostic.

Paper message:

> The mechanics-derived prior contains transport-relevant spatial information beyond geometry, global enhancement, or the marginal distribution of prior values.

### Figure 5: Mechanics-Informed Network Integration

Purpose: show spatial interpretability and coupling-role result.

Suggested panels:

- AS005: H_gradient, Tc proxy, W proxy, transition current.
- AS006: H_gradient, Tc proxy, W proxy, transition current.
- Coupling-role ablation: Tc-only, weak-link-only, diagnostic both-channel.
- Current-weighted mechanics overlap at transition and low temperature.

Paper message:

> The dominant transport-relevant role of the mechanics-derived field is weak-link connectivity; local Tc modulation is secondary.

### Figure 6: Final Robustness Freeze

Purpose: demonstrate that the final conclusion is not fragile.

Suggested panels:

- Disorder/seed robustness: weak-link role preferred fraction.
- Grid/coarse-graining robustness: role ordering across coarse, nominal, fine.
- Prior normalization robustness: min-max, clipped, rank, sqrt variants.
- Current-overlap randomized-null Z for AS005 and AS006.
- Leave-one-anchor-out result: AS005 alone and AS006 alone each support the conclusion.

Paper message:

> The mechanics-informed connectivity conclusion survives the main numerical and representation checks without retuning.

## Supplementary Figure Candidates

### Supplementary Figure S1: Full Six-Device Score Table

Include all six devices under geometry, mechanics, uniform, and randomized/reference controls.

### Supplementary Figure S2: Descriptor Ranking and Uncertainty Screen

Show why H_gradient, rather than hydrostatic or shear-only descriptors, was selected as the final mechanics prior.

### Supplementary Figure S3: Full Current-Overlap Null Distributions

Show randomized overlap histograms for AS005 and AS006 at transition and low-temperature stages.

### Supplementary Figure S4: Full Coupling-Role Ledger

Show F-S0 reference, Tc-only, weak-link-only, and diagnostic both-channel rows for all devices.

### Supplementary Figure S5: Guard-Device Behavior

Show that AS001-AS003 are not forced into structured-connectivity conclusions by adding mechanics.

## Modeling Section Outline

### 1. Motivation: Film Force Is Not a Sufficient Descriptor

State that the six-device comparison motivates a spatial model. Avoid describing the phase history. The key point is that the data require geometry and connectivity, not merely a scalar stressor descriptor.

### 2. Frozen Two-Dimensional Superconducting Network

Describe the accepted network architecture:

- local superconducting landscape represented by Tc(x,y)-like fields;
- weak-link/connectivity represented by W_ij;
- four-probe transport obtained from the two-dimensional network;
- evidence hierarchy fixed before mechanics integration.

State explicitly that later mechanics tests do not retune this architecture.

### 3. Normalized Forward Mechanics Prior

Introduce H_gradient as a normalized mechanics-derived localization prior. Recommended language:

> We use H_gradient(x,y) as a normalized descriptor of mechanics-derived localization. It is not interpreted as the measured strain tensor.

Explain why AS005 and AS006 are the anchor cases:

- AS005: accidental crack/discontinuity.
- AS006: designed half-coverage boundary.

### 4. Frozen Prior Ablation

Describe the four controls:

- geometry reference;
- mechanics-gradient prior;
- uniform mean-matched prior;
- spatially randomized mechanics prior.

State that the downstream transport rules are frozen. The scientific question is whether spatial organization in the mechanics prior matters.

### 5. Coupling-Role Ablation

Describe the comparison among:

- Tc-only mechanics coupling;
- weak-link/connectivity-only mechanics coupling;
- diagnostic both-channel coupling.

Final interpretation:

> Weak-link/connectivity coupling retains the primary explanatory benefit, while Tc-only coupling is supporting but not sufficient.

### 6. Current-Weighted Mechanics Overlap

Define the interpretable overlap metric:

```text
O(T) = sum_ij H_gradient,ij * |I_ij(T)| / sum_ij |I_ij(T)|
```

Then compare the observed overlap to randomized mechanics fields.

Paper-facing statement:

> During the transition and low-temperature stages, current preferentially samples regions with high mechanics-derived localization relative to randomized controls.

### 7. Final Robustness and Freeze

Summarize the five robustness families:

- disorder/seed;
- grid/coarse-graining;
- prior normalization;
- current-overlap randomized null;
- leave-one-anchor-out.

Conclude:

> Because all five robustness families preserve the same conclusion without retuning, model development is frozen and subsequent work focuses on publication outputs.

## Claims Ledger

### Supported

- Mechanical-gradient structure is transport relevant under frozen downstream rules.
- Weak-link/connectivity coupling is the dominant supported role.
- Local Tc modulation is secondary/supporting.
- AS005 and AS006 independently support the final interpretation.
- AS001-AS003 preserve guard behavior.
- The final result is robust to seed, grid, normalization, overlap-null, and anchor-dependency checks.

### Not Claimed

- Absolute device-specific strain reconstruction.
- Quantitative epsilon_xx, epsilon_yy, epsilon_xy tensor inversion.
- Microscopic proof that strain gradients cause weak links.
- A new transport mechanism beyond the frozen superconducting-network architecture.
- Retuned device-specific superconducting parameters.

## Targeted 3D PDE Decision

The 3D PDE visualization should be optional and narrow. It should be included only if it clarifies the paper without reopening model development.

Recommended scope:

- AS005 and AS006 only.
- Visualize whether the established normalized gradient/localization feature persists in a layered 3D representation.
- Plot only quantities tied to the frozen mechanism: normalized epsilon_xx, normalized epsilon_yy, |epsilon_xy|, |grad epsilon|, and optionally u_z.

Recommended placement:

- Main text only if visually decisive and compact.
- Otherwise supplementary validation.

Do not use 3D PDE to introduce new fitting parameters, new transport roles, or absolute strain claims.

## Final Stop Condition

The modeling campaign should be treated as complete:

```ini
model_development_status = complete
next_stage = publication_outputs
new_transport_mechanisms_recommended = false
absolute_strain_claims_allowed = false
```
