* Shared geometry and material parameters for the constrained four-probe model.
* Conductance fractions represent effective covered/boundary/uncovered widths.
.param R4pNormal=48.26
.param probeFraction=0.8636
.param Rpath={R4pNormal/probeFraction}
.param gC=0.37 gB=0.36 gU={1-gC-gB}

* Fraction of each source-drain lane assigned to its bottleneck segment.
.param qC=0.65 qB=0.75 qU=0.55

* Covered, boundary, and uncovered bulk transitions.
.param TcC=1.62 wTcC=0.24 fCbulk=0.05
.param TcB=1.36 wTcB=0.07 fBbulk=0.06
.param TcU=0.72 wTcU=0.20 fUbulk=0.65

* One shared bottleneck transition per lane; no per-resistor fitting.
.param TcWc=1.03 wTcWc=0.18 fCweak=0.025
.param TcWb=0.96 wTcWb=0.14 fBweak=0.040
.param TcWu=0.40 wTcWu=0.12 fUweak=0.85

* Shared transverse coupling, expressed relative to the calibrated path scale.
.param kxy=3.0
.param RxyCB={kxy*Rpath}
.param RxyBU={1.7*kxy*Rpath}

* Field/current scales used by the nonlinear map at Tmap.
.param Tmap=0.10
.param Bnormal=1.75 wBnormal=0.18 nI=6
.param etaBulk=0.75 etaCweak=0.03 etaBweak=0.82 etaU=0.25
.param IcCbulk=4.75u BcCbulk=0.48
.param IcCweak=3.10u BcCweak=0.35
.param IcBbulk=4.55u BcBbulk=0.62
.param IcBweak=3.40u BcBweak=1.30
.param IcUbulk=1.00u BcUbulk=1.45
.param IcUweak=0.55u BcUweak=1.20
