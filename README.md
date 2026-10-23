# PA6: Stress-strain analysis

Open this folder in MATLAB and run `PA6.m`. The script uses base MATLAB only
(R2019a or later for `readmatrix`); it needs no toolbox, package, or separate
library. Keep `aluminum.xlsx` in the current MATLAB folder, or change `dataFile`
in the declarations section.

The script follows the supplied style example with declarations, calculations,
and outputs in one main program. It prints proportional, 0.2% offset yield,
ultimate, and fracture stresses and strains, elastic modulus, and stress
interpolated at the adjustable `queryStrain` (initially `0.1000`). Stresses and
modulus use SI prefixes; strains have four decimal places. The plot labels all
four critical points outside the measured curve. It also includes the four
extra-credit features: a 25-point moving average of force before conversion to
stress, resilience and toughness in MJ/m³, red elastic shading, and cyan plastic
shading.

## Assumptions and adjustable estimates

- The first two spreadsheet columns are displacement in metres and force in
  newtons. The supplied geometry is a 38 mm gage length and 1.5 mm radius.
- This is a monotonic tensile test of a ductile metal. After smoothing in
  acquisition order, the script sorts strain and averages exact duplicate
  strains to accommodate small displacement jitter. Substantial unloading or
  cyclic loading requires a different analysis.
- The elastic modulus is a least-squares slope over the initial rise from 5%
  to 20% of ultimate stress. The proportional limit is estimated as the last
  point before five consecutive samples differ from that fitted line by more
  than 5%. These are adjustable estimation choices, not a uniquely defined
  measurement of the proportional limit. Review them against the curve for a
  different dataset; the script reports an error if it cannot identify a
  consistent elastic region and point order.
- Yield is the linearly interpolated intersection with
  `stress = elasticModulus * (strain - 0.002)`. Ultimate is the maximum smoothed
  stress. A post-peak force drop of at least 50% between consecutive samples
  identifies the last loaded sample before rupture; otherwise, fracture is
  assumed to be the final supplied sample. A test truncated before failure
  cannot establish fracture stress.
- Averages shrink at the endpoints. Post-rupture readings are excluded before
  smoothing. An out-of-range query is reported without extrapolation. Energy
  integration includes the origin and the interpolated yield point so the
  elastic and plastic areas meet at the same boundary.

## Validation and submission

Only static checks were requested. MATLAB and Octave have not executed this
implementation; numerical results and figure rendering remain unverified.
Static review covers assignment requirements, base-MATLAB function usage,
delimiter/block structure, index guards, and preservation of the original data.

Submit `PA6.m` and `AI_USAGE.pdf` as requested by the assignment. The editable
`AI_USAGE.md` records the AI contribution, line references, and explanations of
built-in functions. Review it against your class coverage and update it honestly
if you change the program or perform additional validation.
