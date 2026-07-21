# Constrained four-probe 2D model

This model is a more testable successor to the freely parameterized 2D grid.
It uses a three-lane by six-column geometry with current contacts outside the
voltage-probe span. Source/drain contact drops are excluded from every reported
four-probe resistance.

## Constraints introduced

- The normal resistance is set by one measured four-probe scale and three lane
  conductance fractions that sum to one.
- Every lane has five identical bulk segments and one central bottleneck. There
  are no independent parameters for all 18 longitudinal resistors.
- Covered, boundary, and uncovered lanes each share one bulk and one bottleneck
  transition. Every transverse edge uses one of two shared coupling values.
- The residual resistance arises from lane-level incomplete suppression and a
  poorly superconducting uncovered shunt, not an added series residual resistor.
- Full-width, covered, boundary, uncovered, and transverse probe predictions
  are generated from one parameter set.

The full-width probe is presently defined as the conductance-weighted internal
voltage at columns 1 and 5. This must be changed if the device contact drawing
places the experimental probes at different columns or couples them to only one
side of the channel.

## Files

- `constrained_parameters.inc`: all shared geometry/material parameters.
- `four_probe_rt.cir`: temperature sweep and all probe configurations.
- `four_probe_field_current.cir`: field/current sweep at `Tmap`.
- `analyze_constrained_model.py`: raw-file parser, numerical `dV/dI`, CSVs, and
  publication figures.
- `score_joint_probe_fit.py`: simultaneous score, AIC, and BIC for any measured
  subset of the five probe configurations.
- `probe_measurements_template.csv`: required joint-data column format.

## Run

```bash
/Applications/LTspice.app/Contents/MacOS/LTspice -b four_probe_rt.cir
/Applications/LTspice.app/Contents/MacOS/LTspice -b four_probe_field_current.cir
python3 analyze_constrained_model.py \
  --rt-image "$HOME/Desktop/Figures/t_superconducting_onset_1p8K.png" \
  --dvdi-image /path/to/experimental_dvdi.png
```

To score multiple measured probe curves simultaneously:

```bash
python3 score_joint_probe_fit.py measured_probe_curves.csv \
  --model four_probe_rt_predictions.csv --parameter-count 25
```

The default count of 25 includes every potentially adjustable R(T) parameter.
Parameters fixed independently by lithographic dimensions, normal-state sheet
resistance, or separate probe data should remain fixed and should not be counted
as fitted degrees of freedom. The field/current parameters are counted
separately when comparing nonlinear models.

Only the supplied total R(T) trace is currently available for numerical R(T)
comparison. Covered, boundary, uncovered, and transverse curves are therefore
predictions, not fitted observations. Adding those measurements to the template
CSV is necessary before claiming a validated spatial interpretation.

## Magnetic-field interpretation

The nonlinear model uses lane-shared critical-current and critical-field scales.
It can represent a low-resistance central region, multiple critical-current
envelopes, differential-resistance ridges, and current redistribution.

It does not contain superconducting phase, flux quantization, vortex dynamics,
or electron heating. Therefore fine branching, interference-like lobes,
asymmetry, and hysteresis in the experimental map are not evidence for this
resistor topology. Reproducing those features would require an RSJ/Josephson
junction network, TDGL-style model, and/or an independently constrained thermal
model. The field/current result should be described as qualitative accounting
of the broad envelope, not a quantitative fit to the full raster.
