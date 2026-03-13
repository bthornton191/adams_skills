# One-Sided Floor Contact Force Expression in Adams/View

## Overview

To model a one-sided contact force that activates when a part's center of mass (CM) falls below Z = 0 (a floor), Adams provides the built-in **IMPACT** function. This function computes a penetration-based contact force using a Hertzian stiffness law combined with a damping term that ramps in smoothly with penetration depth.

---

## IMPACT Function Syntax

```
IMPACT(x, x_dot, x1, k, e, cmax, d, order)
```

| Argument | Description |
|----------|-------------|
| `x`      | The displacement variable being monitored (position) |
| `x_dot`  | Time derivative of `x` (velocity) |
| `x1`     | Threshold value — contact activates when `x < x1` |
| `k`      | Stiffness coefficient |
| `e`      | Force exponent (Hertzian: typically 1.5 for sphere-on-flat) |
| `cmax`   | Maximum damping coefficient |
| `d`      | Penetration depth at which full damping (`cmax`) is applied |
| `order`  | Order of the STEP function used to ramp damping (0 = cubic) |

When `x ≥ x1`, the function returns **0** (no contact).  
When `x < x1`, the force is:

$$F = k \cdot (x_1 - x)^e + c(x) \cdot \dot{x}$$

where $c(x)$ ramps from 0 (at $x = x_1$) to $c_{\max}$ (at $x = x_1 - d$) using a smooth STEP function.

---

## Parameters for This Problem

| Parameter | Value |
|-----------|-------|
| Floor Z-level (`x1`) | `0.0` |
| Stiffness (`k`) | `1.0E+05` |
| Exponent (`e`) | `1.5` |
| Max damping (`cmax`) | `50.0` |
| Penetration depth (`d`) | `0.1` (mm, if model units are mm) |
| Order | `0` |

---

## FUNCTION= Expression

The Z-position and Z-velocity of the part's CM relative to the global frame are obtained using `DZ` and `VZ` Adams runtime functions:

```
FUNCTION = IMPACT(DZ(cm_marker, 0, 0), VZ(cm_marker, 0, 0), 0.0, 1.0E+05, 1.5, 50.0, 0.1, 0)
```

- `DZ(cm_marker, 0, 0)` — Z-displacement of the CM marker relative to the global origin, expressed in the global frame (`0` = global reference).
- `VZ(cm_marker, 0, 0)` — Z-velocity of the CM marker in the global frame.
- `0.0` — Floor is at Z = 0.
- Contact force is zero when `DZ ≥ 0`, and ramps on as the CM penetrates below Z = 0.

---

## Full Adams CMD SFORCE Definition

To apply this as a vertical (Z-direction) force on the part, define a translational `SFORCE` using the `ACTIONONLY` flag so the reaction is absorbed by ground:

```adams
SFORCE/1
, I = <cm_marker_id>
, J = <ground_ref_marker_id>
, ACTIONONLY
, TRANSLATIONAL
, FUNCTION = IMPACT(DZ(cm_marker_id, 0, 0), VZ(cm_marker_id, 0, 0), 0.0, 1.0E+05, 1.5, 50.0, 0.1, 0)
```

**Notes:**
- Replace `<cm_marker_id>` with the integer ID of the CM marker on your part.
- Replace `<ground_ref_marker_id>` with a ground-fixed reference marker whose Z-axis is aligned with the global Z-axis. A marker at the global origin with default orientation works.
- The `TRANSLATIONAL` keyword means the force is applied along the Z-axis of the **I marker**. Ensure the I marker's Z-axis points in the global +Z direction (upward) so the contact force pushes the part upward when it penetrates the floor.
- The `ACTIONONLY` flag means no reaction force is applied to the J (ground) marker body, which is the typical convention for contact with the ground.

---

## Behavior Summary

| Condition | Contact Force |
|-----------|--------------|
| CM at Z > 0 (above floor) | 0 — no contact |
| CM at Z = 0 (just touching) | 0 — contact initiating |
| CM at Z = −0.05 mm (half penetration) | Partial stiffness + partial damping |
| CM at Z = −0.1 mm (full damping depth) | Full stiffness + full damping (`cmax = 50`) |

The STEP-based damping ramp prevents a discontinuous jump in damping force at first contact, improving numerical stability during simulation.

---

## Unit Consistency Note

The penetration depth `d = 0.1` is in the model's length units. This expression assumes **millimeters**. If your model uses **meters**, change `0.1` to `0.0001`. Similarly, ensure the stiffness `k = 1E+05` has consistent units (e.g., N/mm^1.5 for mm-tonne-s or N/m^1.5 for MKS).
