# MoTe2 superconducting network MATLAB scaffold, v7.5

v7.5 is a deliberate departure from the v7.4 weak-link-optimization sequence.
Instead of adding another unconstrained transport fit, it adds a
literature-prior and competing-hypotheses layer around the existing
PDE/Raman/gap-tied network scaffold.

Main entry point:

```matlab
run_v75_literature_prior_audit
```

The v7.4.6 gap-tied AS006 sweep is still present in this folder as the runnable
transport base, but the new v7.5 entry point focuses on interpretability:
which parts of the model are evidence-backed, which are hypothesis-backed, and
which are intentionally outside the scalar resistor-network core.

## Minimal source set

The v7.5 prior table records the user-requested references:

1. Qi et al., Nature Communications 7, 11038 (2016):
   `https://www.nature.com/articles/ncomms11038`
2. The same Nature Communications 7, 11038 link was provided twice; v7.5 stores
   it once as a physical source and once as duplicate-source bookkeeping.
3. MoTe2 point-contact/gap-ratio reference:
   `https://arxiv.org/abs/1805.02470`
4. Ambegaokar-Baratoff tunnel-junction critical-current relation:
   `https://www.osti.gov/biblio/4700205`
5. MoTe2 field/edge-supercurrent reference:
   `https://www.osti.gov/biblio/1803173`

## How the literature is used

Literature is used as priors and model boundaries, not replacement data.

- MoTe2 pressure/superconductivity work justifies lattice-sensitive
  superconducting scales, a low unenhanced baseline, and a bounded enhanced-Tc
  population.  It does not justify converting hydrostatic pressure directly
  into the local uniaxial strain produced by lithographic stressors.
- The MoTe2 point-contact/gap result motivates a narrow shared prior on
  `alpha_gap = 2 Delta / k_B Tc`, rather than arbitrary link-by-link gaps.
- The Ambegaokar-Baratoff relationship is used only as a tunnel/crack-like
  weak-link hypothesis.  Continuous intraflake weak regions remain
  SNS/constriction-like hypotheses with separate normalized behavior.
- Field-oscillation literature motivates edges, loops, and weak links, but it
  also defines a boundary: a scalar resistance network without superconducting
  phase cannot quantitatively fit fluxoid periods.

## v7.5 hypothesis cases

The new `make_v75_hypothesis_cases.m` table defines thesis-facing competing
hypotheses:

- `H0_baseline_geometry`: geometry and correlated disorder only;
- `H1_lattice_sensitive_Tc`: bounded lattice-sensitive local Tc prior;
- `H2_gap_tied_SNS_constrictions`: gap-tied continuous weak boundaries;
- `H3_gap_tied_crack_tunnel_links`: lower-transparency crack/tunnel bottlenecks;
- `H4_contact_relaxation_anisotropy`: contact relaxation plus anisotropic
  transparency;
- `H5_phase_field_boundary`: field oscillations are outside the present core
  model unless a later phase-aware Josephson module is introduced.

## Outputs

The audit runner writes:

```text
outputs/v7_5_literature_prior_framework
```

Key outputs:

- `v7_5_literature_priors.csv`
- `v7_5_hypothesis_cases.csv`
- `v7_5_literature_prior_map.png/.fig`
- `v7_5_hypothesis_case_map.png/.fig`

## Transport base retained from v7.4.6

The copied v7.4.6 scripts remain available:

```matlab
run_v746_as006_gap_weaklink_sweep
```

Those scripts implement the gap-tied weak-link scaffold:

```text
Delta_0,ij = 0.5 * alpha_gap * k_B * Tc,ij
Ic,ij(0)   = pi * Delta_0,ij / (2 e Rn,ij)
```

with compact sweeps over `alpha_gap`, `gammaW = G_weak/G_bulk`, and weak-link
fraction.  In v7.5, those model choices are now explicitly connected to the
reference-prior table instead of being presented as free phenomenological
choices.

## Caveat

v7.5 is still semi-phenomenological.  It does not compute an actual strain
tensor, electron-phonon coupling, order-parameter symmetry, Usadel equations,
time-dependent phase dynamics, heating, or vortex motion.  That limitation is
intentional: the thesis-safe claim is a controlled two-dimensional network
framework constrained by literature priors and available device data.
