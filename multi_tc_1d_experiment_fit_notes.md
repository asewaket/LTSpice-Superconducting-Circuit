# Calibrated 1D multi-Tc model

The fitted circuit is a phenomenological six-region series model. It matches
the uploaded strained 1T'-MoTe2 trace with a normal resistance near 48.26 ohm,
a superconducting onset near 1.8 K, multiple shoulders, a dominant transition
near 1 K, and a finite low-temperature resistance near 2.5 ohm.

| Region | Tc midpoint (K) | Width (K) | Resistance drop (ohm) |
|---|---:|---:|---:|
| 1 | 1.60264 | 0.27924 | 6.94420 |
| 2 | 1.35885 | 0.05929 | 4.74553 |
| 3 | 1.01000 | 0.11602 | 18.17317 |
| 4 | 0.90456 | 0.05247 | 11.95118 |
| 5 | 0.86000 | 0.25793 | 3.07969 |
| 6 | 0.13420 | 0.04627 | 0.94131 |

The fixed residual element is 2.42371 ohm. The total normal-state resistance
is 48.25879 ohm. The fit RMS error against the trace digitized from the raster
figure is approximately 0.17 ohm.

The fitted curve constrains each transition amplitude, `Rn*(1-f)`, and the
total residual resistance. It cannot uniquely determine how the residual is
partitioned between contacts, nonsuperconducting channel regions, and finite
`f` values. Therefore the calibrated baseline uses `f=0` and assigns the
remainder to `Rresidual`. The broad fitted widths should be interpreted as
effective distributions/weak-link broadening, not intrinsic thermodynamic
transition widths.
