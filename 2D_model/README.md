# Phenomenological 2D superconducting resistor network

This directory extends the calibrated 1D strained 1T'-MoTe2 model into a
three-lane by six-column network. It keeps the same local switching law:

```spice
.func sw(temp,tc,w) 0.5*(1+tanh((temp-tc)/w))
.func Rseg(rn,tc,w,f) {Rfloor + rn*(f + (1-f)*sw(T,tc,w))}
```

## Model progression

1. `multi_tc_2d_control.cir` uses three identical lanes scaled by three. It is
   the topology check and reproduces the calibrated 1D total resistance.
2. `multi_tc_2d_strain_contrast.cir` assigns enhanced high-temperature
   transitions to the covered lane, concentrates the 1 K transition weight at
   the boundary, and gives the uncovered lane lower Tc and incomplete drops.
3. `multi_tc_2d_weak_links.cir` adds selected temperature-dependent transverse
   links to represent cooling-enhanced connectivity and current redistribution.

The grid is an equivalent circuit, not a unique reconstruction of the strain
map or microscopic superconducting domains. Its identifiable outputs are the
network-level resistance, lane voltage responses, and redistribution of source
current under the assumed topology.

## Run

From this directory:

```bash
/Applications/LTspice.app/Contents/MacOS/LTspice -b multi_tc_2d_control.cir
/Applications/LTspice.app/Contents/MacOS/LTspice -b multi_tc_2d_strain_contrast.cir
/Applications/LTspice.app/Contents/MacOS/LTspice -b multi_tc_2d_weak_links.cir
python3 plot_2d_models.py \
  --experimental-image "$HOME/Desktop/Figures/t_superconducting_onset_1p8K.png"
```

Each netlist sweeps 4.20 K to 0.10 K in 0.002 K increments. The Python script
reads the LTspice raw files and writes CSV, 600 dpi PNG, and vector PDF outputs.

## Calibrated behavior

The identical-lane control retains the 1D fit (`2.608 ohm` at 0.10 K and
`48.259 ohm` at 4.20 K). The final weak-link network gives approximately
`2.739 ohm` and `48.211 ohm`, respectively. Its RMS difference from the trace
digitized from the supplied experimental raster is approximately `0.38 ohm`.

The nonidentical model intentionally accepts a modest increase from the 1D fit
error so covered, boundary, and uncovered paths have distinct electrical
responses. These lane assignments are hypotheses to test, not fitted spatial
measurements.
