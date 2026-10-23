# PA6 AI-use summary

This summary describes the AI assistance used to prepare the current `PA6.m`.
Line references below refer to the 239-line version included with this summary.

## How AI was used

- **Lines 1-22:** AI used the supplied MATLAB style example to organize a single
  script with `clear`, `clc`, `close all`, section headings, camelCase names,
  declared geometry, an adjustable query strain, and documented thresholds.
- **Lines 24-86:** AI wrote spreadsheet import and input checks, pre-rupture
  trimming, the 25-point force average, stress/strain conversion, and handling
  for small displacement reversals and exact repeats.
- **Lines 88-124:** AI selected an explicit estimation method for elastic
  modulus and proportional limit: fit the 5%-20% portion of the initial stress
  rise, then require a 5% departure for five consecutive points. These choices
  are adjustable assumptions, not independently verified material properties.
- **Lines 126-152:** AI implemented the 0.2% offset intersection using linear
  interpolation between adjacent samples, plus interpolation at the exact
  declared query strain. Out-of-range requests are not extrapolated.
- **Lines 154-176:** AI split the curve at the interpolated yield point,
  calculated resilience and toughness, and selected SI prefixes for output.
- **Lines 177-239:** AI wrote formatted command-window output, the curve plot,
  critical-point markers, labels outside the data, and red/cyan energy shading.
- AI wrote the README and this disclosure. The user supplied the assignment,
  example style, and instructions to use base MATLAB without add-ons and to
  perform static checks only.
- AI checked character vectors, delimiters, control-block nesting, base-MATLAB
  function usage, original input-file preservation, and Git whitespace errors.
  **This program was not executed in MATLAB or Octave.** Numerical results,
  graph appearance, and MATLAB Code Analyzer results remain unverified.
- This document does not claim that the student ran or personally verified the
  solution. Update it if the program, AI involvement, or validation changes.

## Function explanations

Class and zyBooks coverage was not supplied. To support the assignment's
disclosure rule, the following list explains the built-ins used, including
ones that may already be familiar. All are part of base MATLAB.

- **Lines 1-4, 206, 237-239 - `clear`, `clc`, `close`, `warning`, `hold`,
  `grid`, `box`:** Clear workspace variables and command-window text; close
  figures; enable or report warnings; retain multiple plotted objects; and
  display plot grid lines and an axes border.
- **Lines 21-22 - `char`:** Convert character code 181 to the micro-prefix
  symbol for units. A cell array stores the SI prefix character vectors.
- **Lines 24-43, 48-62, 79-99, 119-143 - `error`:** Stop with an explanation
  when the input or identified elastic/critical-point region is unusable.
- **Lines 27, 36-41, 79, 91, 98, 119, 132, 168-170, 186 - `isscalar`,
  `isnan`, `isinf`, `all`, `any`, `size`, `numel`, `isempty`:** Check for a scalar
  query, missing numbers, and infinities; combine logical tests; count rows, columns, or
  elements; and check whether a search produced no index.
- **Line 31 - `readmatrix`:** Import the spreadsheet as a numeric matrix.
  Columns one and two supply displacement and force. This function requires
  MATLAB R2019a or later, without a toolbox.
- **Lines 47, 83, 108, 172, 236 - `max`, `min`:** Locate peak force and
  stress, protect a relative-deviation denominator, limit the SI exponent to
  the available prefixes, and choose axis limits.
- **Line 68 - `movmean`:** Take a centered 25-sample moving average of force.
  `'Endpoints', 'shrink'` uses the available samples at the beginning and end;
  it does not pad with zeros or include post-rupture readings.
- **Lines 75-78, 215 - `sort`, `unique`, `accumarray`, `mean`:** Sort strain
  and reorder stress with the same indices. `unique` returns one copy of each
  strain and a group number for each reading. `accumarray` with `@mean` averages
  stresses in each exact-repeat group. `@mean` passes a built-in function
  handle, not an external library. A second sort orders point labels by stress.
- **Lines 89-90, 129-131 - `find`:** Locate the first index meeting the
  elastic-fit stress threshold or the offset-line sign-change condition.
  Empty results are checked before indexing.
- **Lines 95-101 - `polyfit`, `polyval`:** Fit a first-degree least-squares
  line to the initial elastic section and evaluate that line. Its slope is
  the estimated elastic modulus; the intercept helps assess proportionality.
  The offset-yield line separately passes through strain 0.002 at zero stress.
- **Lines 107-108, 171-172 - `abs`, `log10`, `floor`:** Measure an absolute
  deviation and choose a power-of-1000 SI scale. Rounding the base-10 exponent
  down to a multiple of three chooses a metric prefix.
- **Line 149 - `interp1`:** Linearly interpolate stress at `queryStrain`,
  rather than substituting the closest measured strain. The offset-yield
  intersection at lines 136-141 uses the equivalent two-point formula directly.
- **Lines 159-160 - `trapz`:** Integrate stress against the actual,
  nonuniform strain spacing using trapezoids. Pa times dimensionless strain
  gives J/m^3; division by one million gives MJ/m^3.
- **Lines 166-167 - `ones`, `cell`:** Allocate the numeric scale vector and
  a cell array of text prefixes before the output-formatting loop.
- **Lines 178-200, 230 - `fprintf`, `sprintf`:** Print aligned values with
  controlled decimal places or build a plot label containing the selected
  stress unit. `%.4f` prints strain to four decimals; `%.2f` prints stress to
  hundredths in its selected metric unit.
- **Lines 205-211 - `figure`, `area`, `plot`:** Create a figure; shade the
  energy areas to and after yield; and draw the smoothed stress-strain curve.
  Stored graphics handles control the legend's membership and order.
- **Lines 217-227 - `linspace`, `plot`, `text`:** Space four label heights
  evenly, draw critical-point markers and connecting lines, and position
  labels to the right of the measured curve so text does not cover its points.
- **Lines 229-236 - `xlabel`, `ylabel`, `title`, `legend`, `xlim`, `ylim`:**
  Set axis labels, title, legend entries and location, and visible plot limits.
  Disabling the unit label's text interpreter displays the prefix literally.

## Assumptions to review before submission

- **Lines 14-18, 45-60, 73-78, 88-124:** Automatic elastic-region,
  proportional-limit, and rupture choices are heuristics for monotonic ductile
  tensile data. Large unloading, unusual noise, or a different sampling density
  can require adjusting the declared thresholds. Small strain reversals are
  treated as sensor jitter. The final sample is assumed to be fracture when a
  sudden post-peak force drop is absent.
- **Lines 154-161:** The energy calculation adds the origin, uses the
  interpolated yield point as the common boundary, and defines resilience as
  area to yield and toughness as area to fracture.
- The PDF is generated from this Markdown disclosure. Keep the line references
  and function explanations synchronized with any changes to `PA6.m`.
