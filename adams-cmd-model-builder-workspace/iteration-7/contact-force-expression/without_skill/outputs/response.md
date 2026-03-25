# One-Sided Contact Force — FUNCTION= Expression

## SFORCE Definition

```
SFORCE/1, I=cm_marker_id, J=ground_marker_id, &
  TRANSLATIONAL, &
  FUNCTION=IMPACT(DZ(cm_marker_id, ground_marker_id), &
                  VZ(cm_marker_id, ground_marker_id), &
                  0.0, 1.0E+5, 1.5, 50.0, 0.1)
```

## Explanation

The `IMPACT` function signature is:

```
IMPACT(x, x_dot, x1, k, e, cmax, d)
```

| Argument | Value | Meaning |
|---|---|---|
| `x` | `DZ(cm_marker_id, ground_marker_id)` | Current Z-position of the part's CM |
| `x_dot` | `VZ(cm_marker_id, ground_marker_id)` | Current Z-velocity of the part's CM |
| `x1` | `0.0` | Contact boundary — floor at Z = 0 |
| `k` | `1.0E+5` | Contact stiffness |
| `e` | `1.5` | Force-penetration exponent |
| `cmax` | `50.0` | Maximum damping coefficient |
| `d` | `0.1` | Penetration depth (in model length units, e.g. mm) at which full damping is applied |

## How it works

`IMPACT` produces a positive (upward) force only when `x < x1`, i.e., when the CM drops below Z = 0:

$$F = k \cdot (x_1 - x)^e - c_{\max} \cdot \text{STEP}(x,\; x_1 - d,\; 1,\; x_1,\; 0) \cdot \dot{x}$$

- When `x ≥ x1` (CM above the floor): no force is applied.
- When `x < x1` (CM penetrates the floor): a stiffness term `k*(x1-x)^1.5` resists further penetration, and a damping term proportional to `cmax` dissipates energy. The `STEP` function ramps damping from 0 to its full value over the 0.1 mm penetration depth, preventing a damping discontinuity at first contact.

## Notes

- Replace `cm_marker_id` and `ground_marker_id` with the actual integer marker IDs in your model.
- The SFORCE must be set to `TRANSLATIONAL` and oriented so that its action axis is the global Z direction. Placing marker J at the global origin with no rotation ensures `DZ` and `VZ` measure in the global Z frame.
- Units: the stiffness `1.0E+5`, damping `50.0`, and penetration depth `0.1` must be consistent with the model's unit system. If the model uses mm-N-s, then `d = 0.1` is 0.1 mm and `k = 1.0E+5` is N/mm^1.5.
