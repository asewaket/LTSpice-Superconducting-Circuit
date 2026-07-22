# MoTe2 superconducting network MATLAB scaffold, v7.2.2

v7.2.2 adds nonlinear current-dependent transport diagnostics on top of v7.1.
It also fixes the first v7.2 plotting issue by loading a true experimental
AS006 `dV/dI(I,T)` file instead of trying to place an `R(T)` curve on an
I-axis plot.

This folder is intentionally a thin v7.2.2 layer: it adds the v7.1 folder to the
MATLAB path and keeps only the new nonlinear/current-map code here.

Main entry point:

```matlab
run_v722_as006_nonlinear_maps
```

The first v7.2.2 scaffold targets AS006 and adds:

- nonlinear link resistance using each link's existing `IcX`/`IcY`;
- simulated `dV/dI(I,T)` maps for top `4-10` and bottom `3-9`;
- experimental AS006 `dV/dI(I,T)` current cuts from `ASD092_dVdIvIvT_0118.dat`;
- current-dependent switched-link maps;
- current-density/current-redistribution maps.
- a `max |I_link|/Ic` diagnostic to show whether the current sweep is actually
  strong enough to trigger local critical-current switching.

The nonlinear resistance rule is inherited from v7.1:

```text
R_link(T,I) = Rfloor + Rn [ f + (1-f) S(T,I) ]
S(T,I) = 1 - [1-S_T(T)] [1-S_I(I)]
S_I(I) = sigmoid((|I_link|-Ic)/dI)
```

This is not yet a quantitative critical-current fit. It is a diagnostic test
of whether local `Ic` heterogeneity plus alternate 2D current paths can produce
nonlinear switching and current redistribution.
