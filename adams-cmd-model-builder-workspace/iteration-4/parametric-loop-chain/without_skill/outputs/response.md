# Parametric Chain of 8 Point Masses — Approach

## Overview

This script builds a 1-D chain of 8 point masses connected by spring-dampers entirely through
parametric FOR loops, avoiding any hard-coded repetition beyond the loop bounds.

## Model Structure

| Entity | Count | Key Parameters |
|---|---|---|
| Point mass parts | 8 | 0.25 kg each, spaced 50 mm along X |
| Fixed joint | 1 | `mass_1` pinned to ground at origin |
| Spring-dampers | 7 | k = 100 N/mm, c = 1.0 N·s/mm, free length = 50 mm |

## Parametric Construction

### Name Building with `EVAL`, `RTOI`, and `//`

Adams CMD loop variables are real numbers. The three operators work together to produce
part and element names inside a loop:

```
"mass_" // RTOI(ii)
```

- `RTOI(ii)` — converts the real loop counter to an integer (strips the decimal part)
- `//`       — string concatenation operator; Adams automatically converts the integer to its
               string representation in this context
- `EVAL(...)` — forces Adams to evaluate the entire expression at run-time so the result
               is used as the actual name rather than treated as a literal string

Example: when `ii = 3`, `(EVAL("mass_" // RTOI(ii)))` resolves to `mass_3`.

### Mass Position Computation

A scratch variable `xpos` is computed inside the loop to avoid embedding an expression
directly in the `location=` field:

```
variable create variable_name=xpos &
  real_value=(EVAL((ii - 1) * 50.0))
```

This gives x-positions 0, 50, 100, 150, 200, 250, 300, 350 mm.

### Spring-Damper Loop

The spring loop runs from `ii = 1` to `7` and connects marker `mass_N.cm` to `mass_(N+1).cm`,
relying on the same `// RTOI` pattern for both endpoint names:

```
i_marker_name=(EVAL("mass_" // RTOI(ii)     // ".cm"))
j_marker_name=(EVAL("mass_" // RTOI(ii + 1) // ".cm"))
```

## Simulation

A 2-second transient simulation is run with 200 output steps (10 ms resolution).
`initial_static=no` keeps the chain in its initial straight-line configuration so the
spring-damper oscillation dynamics are immediately visible from t = 0.

## Units

The model explicitly sets `mm / N / kg / s` via `defaults units` to ensure all numeric
literals (stiffness, damping, free length, mass positions) are consistent.
