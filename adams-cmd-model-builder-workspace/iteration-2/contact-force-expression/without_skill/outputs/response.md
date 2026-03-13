# One-Sided Contact Force Expression (Floor at Z = 0)

## Overview

This gives a `FUNCTION=` expression for a one-sided contact force that activates when a part's centre of mass (CM) drops below Z = 0 (a floor at Z = 0). The expression uses the Adams `IMPACT` function, which is the standard approach for compliance-based contact in Adams/View and Adams/Car CMD models.

### Specified Parameters

| Parameter | Value |
|---|---|
| Stiffness (k) | 1.0E5 |
| Exponent (e) | 1.5 |
| Maximum damping coefficient (cmax) | 50.0 |
| Penetration depth for full damping (d) | 0.1 mm |

---

## The IMPACT Function

The Adams `IMPACT` function models a compliant contact force. Its signature is:

```
IMPACT(x, xdot, x1, k, e, cmax, d)
```

| Argument | Meaning |
|---|---|
| `x` | Current value of the gap/penetration quantity |
| `xdot` | Time derivative of `x` (closing velocity) |
| `x1` | Boundary value at which contact initiates |
| `k` | Stiffness coefficient |
| `e` | Force exponent (penetration exponent) |
| `cmax` | Maximum damping coefficient |
| `d` | Penetration at which full damping (`cmax`) is applied |

**Behaviour:**
- When `x >= x1`: `IMPACT = 0` (no contact)
- When `x < x1`: `IMPACT = k*(x1 - x)^e - STEP(x, x1-d, cmax, x1, 0) * xdot`

The damping term is ramped smoothly from 0 (at the contact boundary) to `cmax` (at penetration depth `d`) using an internal STEP function, avoiding a discontinuity at first contact.

---

## FUNCTION= Expression

For a floor at Z = 0, with the part CM represented by marker `cm_marker` and the floor origin by `floor_marker` (fixed to Ground at Z = 0):

```
FUNCTION = IMPACT(DZ(cm_marker, floor_marker, floor_marker), &
                  VZ(cm_marker, floor_marker, floor_marker), &
                  0.0, 1.0E5, 1.5, 50.0, 0.1)
```

- `DZ(cm_marker, floor_marker, floor_marker)` — Z-displacement of the CM relative to the floor, expressed in the floor frame.
- `VZ(cm_marker, floor_marker, floor_marker)` — Z-velocity of the CM relative to the floor.
- `0.0` — Contact initiates at Z = 0 (the floor).
- `1.0E5` — Stiffness.
- `1.5` — Penetration exponent.
- `50.0` — Maximum damping.
- `0.1` — Full damping reached at 0.1 mm penetration.

> **Unit note:** The values above assume the model uses **mm** and **N**. Stiffness units are N/mm^1.5, damping units are N·s/mm, and penetration is in mm. If the model uses SI (m, N), convert `d` to `1.0E-4` (0.1 mm = 1×10⁻⁴ m) and confirm the stiffness and damping magnitudes are appropriate for those units.

---

## Full CMD Example

The force is applied as a single-component translational SFORCE acting on the part in the Z direction. Use `ACTION_ONLY` so the reaction does not load Ground.

```cmd
! ============================================================
! One-sided floor contact force
! Activates when part CM penetrates below Z = 0
! Units: mm, N
! ============================================================

MARKER/10, PART = 1, QP = 0, 0, 0, REULER = 0, 0, 0
! floor_marker: fixed to Ground at origin (Z = 0)

SFORCE/1, &
  I     = 2, &
  JFLOAT, &
  TRANSLATIONAL, &
  ACTION_ONLY, &
  FUNCTION = IMPACT(DZ(2, 10, 10), VZ(2, 10, 10), 0.0, 1.0E5, 1.5, 50.0, 0.1)
```

**Key points:**
- `I = 2` — the CM marker of the part (replace with actual marker ID).
- `JFLOAT` — the reaction point floats; no reaction is applied to Ground.
- `TRANSLATIONAL` — the force acts along the line between I and J markers (Z-axis in this configuration). Because the floor marker's Z-axis is aligned with global Z, the force acts in the +Z direction, pushing the part back up when penetration occurs.
- Replace marker IDs `2` and `10` with the actual IDs from your model.

---

## Alternative: Using IF and STEP

If you need explicit control without the built-in IMPACT function, an equivalent expression using `IF` and `STEP` is:

```
FUNCTION = IF(DZ(2, 10, 10):  &
    (1.0E5 * (-DZ(2, 10, 10))**1.5  &
     - STEP(DZ(2, 10, 10), -0.1, 50.0, 0.0, 0.0) * VZ(2, 10, 10)),  &
    0.0, 0.0)
```

`IF(expr: negative_value, zero_value, positive_value)` — returns the first branch when `expr < 0` (CM below floor), otherwise 0.

The `IMPACT` function formulation is preferred because it is optimised internally, handles sign conventions automatically, and is numerically more robust.

---

## Summary

| Item | Value |
|---|---|
| Function used | `IMPACT` |
| Contact boundary | Z = 0 (floor) |
| Gap quantity | `DZ(cm_marker, floor_marker, floor_marker)` |
| Closing velocity | `VZ(cm_marker, floor_marker, floor_marker)` |
| Stiffness | `1.0E5` |
| Exponent | `1.5` |
| Max damping | `50.0` |
| Damping ramp depth | `0.1` (mm) |
| Force element type | `SFORCE`, `TRANSLATIONAL`, `ACTION_ONLY` |
