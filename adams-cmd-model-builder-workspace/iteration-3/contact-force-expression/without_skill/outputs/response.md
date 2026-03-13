# FUNCTION= Expression for One-Sided Contact Force (Floor at Z=0)

## Overview

In MSC Adams, a one-sided contact force (impact model) is typically expressed using the built-in `IMPACT` function. This function models a force that activates when two bodies come into contact and returns zero when they are separated.

## IMPACT Function Syntax

```
IMPACT(x, ẋ, x1, k, e, cmax, d)
```

| Parameter | Description |
|-----------|-------------|
| `x`       | Current value of the gap/position measure |
| `ẋ`       | Time derivative of `x` (velocity) |
| `x1`      | Threshold at which contact initiates |
| `k`       | Contact stiffness |
| `e`       | Force exponent (controls nonlinearity of stiffness term) |
| `cmax`    | Maximum damping coefficient |
| `d`       | Penetration depth at which damping reaches `cmax` |

The force is active when `x < x1`, and the output is:

$$F = k \cdot (x_1 - x)^e - \text{step}(x,\ x_1 - d,\ c_{max},\ x_1,\ 0) \cdot \dot{x}$$

---

## Expression for a Floor at Z = 0

The part's CM Z-position can be obtained using `DZ(i, j)` where `i` is the marker at the CM and `j` is a ground-fixed reference marker (or the global origin).

```
FUNCTION = IMPACT(DZ(CM_MARKER, GROUND_MARKER), VZ(CM_MARKER, GROUND_MARKER), 0.0, 1.0E5, 1.5, 50.0, 0.1)
```

### Parameter Mapping

| Parameter | Value | Notes |
|-----------|-------|-------|
| `x`       | `DZ(CM_MARKER, GROUND_MARKER)` | Z-coordinate of the part CM relative to ground |
| `ẋ`       | `VZ(CM_MARKER, GROUND_MARKER)` | Z-velocity of the part CM |
| `x1`      | `0.0` | Contact threshold — the floor is at Z = 0 |
| `k`       | `1.0E5` | Stiffness (units: N/mm or N/m depending on model units) |
| `e`       | `1.5` | Force exponent |
| `cmax`    | `50.0` | Maximum damping coefficient |
| `d`       | `0.1` | Penetration depth for full damping (0.1 mm) |

---

## How to Apply This

This expression should be used as the `FUNCTION=` property of a **SFORCE** (single-component force) element acting in the **Z-direction** on the part, with the reaction going to ground.

Example Adams CMD snippet:

```
force/1,
  sforce,
  i=cm_marker_id,
  j=ground_marker_id,
  function = IMPACT(DZ(cm_marker_id, ground_marker_id), VZ(cm_marker_id, ground_marker_id), 0.0, 1.0E5, 1.5, 50.0, 0.1),
  actiononly
```

> **Note on units:** The stiffness `1e5` and damping `50` are assumed to be consistent with the model's unit system. If the model is in SI (meters, Newtons), and the penetration depth `0.1` is in millimeters, you may need to convert it to `0.0001` meters. Verify your model's unit system to ensure consistency.

---

## Notes

- The `IMPACT` function only produces a force when the part penetrates below Z = 0 (i.e., `DZ < 0`). When `DZ >= 0`, the force is zero.
- `actiononly` ensures the force acts only on the part (no equal-and-opposite reaction applied to ground, since ground is typically fixed).
- Replace `CM_MARKER` and `GROUND_MARKER` with the actual integer marker IDs from your Adams model.
