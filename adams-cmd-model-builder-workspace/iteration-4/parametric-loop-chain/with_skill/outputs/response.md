# Parametric Chain of 8 Point Masses — Approach

## Overview

This script builds a 1-D chain of 8 point masses along the X axis using a single `for` loop. Every object — masses, markers, the fixed joint, and the spring-dampers — is created parametrically using `EVAL()`, `RTOI()`, and the string-concatenation operator `//`.

## Structure

### Model and Gravity
A model is created first, then gravity is set to –9806.65 mm/s² in the Y direction (standard gravity in mm/s² for a kg–mm–s unit system).

### Ground Marker
A single marker on ground (`fix_mkr`) is created at the origin before the loop. It serves as the J-marker for the fixed joint that anchors `mass_1`.

### FOR Loop (i = 1 … 8)

Each iteration performs three things in order:

1. **Create the point mass** at position `(i-1) * 50.0, 0.0, 0.0` with mass 0.25 kg.  
   Name: `.model.mass_<i>`

2. **Create a reference marker** on that mass at its local origin.  
   Name: `.model.mass_<i>.ref_mkr`  
   This is needed because spring-dampers require explicit marker references; the auto-created `.cm` marker is not used here.

3. **Conditional logic:**
   - `if condition = (i == 1)` — Fix `mass_1` to ground with a fixed joint.
   - `if condition = (i > 1)` — Create a spring-damper connecting `mass_(i-1)` and `mass_i`.

### Spring-Damper Parameters
| Parameter  | Value  |
|------------|--------|
| Stiffness  | 100.0 N/mm |
| Damping    | 1.0 N·s/mm |
| Free length | 50.0 mm |

The free length equals the spacing between adjacent masses, so the chain starts in its natural (unstressed) state.

### Simulation
A transient simulation runs for 2.0 seconds with a step size of 0.001 s (2000 output steps).

## Key CMD Techniques Used

- `RTOI(i)` converts the integer loop counter to a string.
- `//` concatenates strings to build object names dynamically, e.g. `".model.mass_" // RTOI(i)`.
- `EVAL(...)` dereferences the constructed string as an object name or evaluates an arithmetic expression.
- No `adams_id` is specified anywhere.
- All keywords are fully spelled out (no abbreviations).
