# LTSpice Superconducting Circuit

MATLAB, Python, and LTspice models for superconducting transport in
Hall-bar-like MoTe2 devices. The repository preserves multiple modeling
iterations, from early local-link resistor-array scaffolds through
Raman-informed and constrained four-probe network models.

The core modeling idea is to assign local superconducting link parameters,

```text
(Rn, Tc, Ic)
```

across a device geometry, solve the resulting electrical network, and compare
predicted four-probe `R(T)` behavior with experimental transport trends.

## Repository Layout

| Path | Purpose |
|---|---|
| `matlab_sc_network_project/` | First Hall-bar-aware MATLAB scaffold derived from the original resistor-array model. |
| `matlab_sc_network_project_v2/` | Adds shared model parameters, mechanical proxy fields, ablations, and device metrics. |
| `matlab_sc_network_project_v3/` | Adds experimental `R(T)` import, model/experiment overlays, and thesis-style figures. |
| `matlab_sc_network_project_v4/` | Adds metric tables, probe-pair comparisons, and sensitivity sweeps. |
| `matlab_v5_raman_files/` | Digitized Raman line-scan import and Raman shift summaries. |
| `matlab_v5_5_registration_files/` | Raman scan registration to Hall-bar geometry. |
| `matlab_v5_6_files/` | Raman registration visualization cleanup and support/confidence maps. |
| `matlab_v6_files/` | First Raman-informed transport sweep using hybrid geometry/Raman proxies. |
| `matlab_v6_1_files/` | Raman representation, mode, reference, and coupling sensitivity tests. |
| `matlab_v6_2_files/` | Robustness and family-level summaries for selected Raman variants. |
| `matlab_v6_3_files/` | Out-of-plane/A4g Raman mode-ablation tests for transport relevance. |
| `matlab_v7_2_2_files/` | PDE-informed AS006 nonlinear `dV/dI(I,T)` scaffold with local `Ic` switching diagnostics and experimental top/bottom nonlinear cuts. |
| `2D_model/` | LTspice 2D network progression and plotting scripts. |
| `2D_model_four_probe_constrained/` | Constrained three-lane four-probe LTspice model with scoring utilities. |
| Root `*.m` files | Physics-informed domain/percolation model sweeps and plotting helpers. |

## Main MATLAB Entry Points

For the v4 Hall-bar network scaffold:

```matlab
cd matlab_sc_network_project_v4
run_six_device_scaffold
```

For the Raman-informed v6.3 mode-ablation workflow:

```matlab
cd matlab_v6_3_files
run_out_of_plane_mode_ablation
```

For the root-level physics-informed domain/percolation sweep:

```matlab
run_physics_informed_case_sweep
```

For the v7.2.2 AS006 nonlinear `dV/dI(I,T)` scaffold:

```matlab
cd matlab_v7_2_2_files
run_v722_as006_nonlinear_maps
```

Each iteration folder has its own `README.md` with more detailed notes,
expected outputs, and caveats.

## LTspice Workflows

The constrained four-probe model can be run with LTspice in batch mode:

```bash
cd 2D_model_four_probe_constrained
/Applications/LTspice.app/Contents/MacOS/LTspice -b four_probe_rt.cir
/Applications/LTspice.app/Contents/MacOS/LTspice -b four_probe_field_current.cir
python3 analyze_constrained_model.py
```

Generated `.raw` and `.log` simulator outputs are intentionally ignored by Git.

## Notes

- Several scripts reference experimental files stored outside this repository,
  especially transport curves under the local thesis data directory.
- Figures, CSV summaries, and PDFs included here are retained as compact
  reference outputs for the saved model states.
- The Raman-informed models are controlled sensitivity tests, not fully
  calibrated strain-tensor or microscopic superconductivity models.
- The constrained LTspice models are useful for broad-envelope transport
  accounting, but they do not include phase coherence, vortex dynamics,
  Josephson-junction physics, or thermal effects.

## Git Hygiene

The root `.gitignore` excludes local caches, MATLAB autosaves, LTspice
regenerated outputs, and scratch folders while keeping source files, netlists,
plots, PDFs, and CSV reference outputs under version control.
