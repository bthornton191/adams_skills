# One-Sided Contact Force Expression — Adams CMD

## FUNCTION= Expression

```
FUNCTION = IMPACT(DZ(PART_CM,0,0), VZ(PART_CM,0,0), 0.0, 1E5, 1.5, 50.0, 0.1)
```

### Parameter Breakdown

| Argument | Value | Description |
|---|---|---|
| `x` | `DZ(PART_CM,0,0)` | Z position of the part's CM in the global frame |
| `ẋ` | `VZ(PART_CM,0,0)` | Z velocity of the part's CM in the global frame |
| `x1` | `0.0` | Contact threshold — floor at Z = 0 |
| `k` | `1E5` | Stiffness coefficient |
| `e` | `1.5` | Force exponent |
| `cmax` | `50.0` | Maximum damping coefficient |
| `d` | `0.1` | Penetration depth at which full damping is applied (mm) |

The IMPACT function returns zero when `DZ(PART_CM,0,0) >= 0` (part above floor) and a positive resisting force when `DZ(PART_CM,0,0) < 0` (part penetrates the floor).

---

## Full SFORCE Definition in Adams CMD

Replace `PART_CM` with the actual marker ID of the part's CM.

```
SFORCE/1, ACTIONONLY, &
  I=PART_CM, &
  JFLOAT, &
  TRANSLATIONAL, &
  FUNCTION = IMPACT(DZ(PART_CM,0,0), VZ(PART_CM,0,0), 0.0, 1E5, 1.5, 50.0, 0.1)
```

### Notes
- `ACTIONONLY` means the reaction force is not applied to a second body (ground absorbs it).
- `TRANSLATIONAL` with `JFLOAT` applies the force along the line connecting the I marker's z-axis to the floating reference — ensure the CM marker's z-axis is aligned with the global Z direction for a vertical floor contact.
- If the CM marker z-axis is not aligned with global Z, use a fixed grounded marker whose z-axis points upward as the J marker instead of `JFLOAT`.

---

## Force Law

The IMPACT function implements:

$$F = k \cdot (x_1 - x)^e - c_{\max} \cdot \text{STEP}(x,\, x_1 - d,\, 1,\, x_1,\, 0) \cdot \dot{x} \quad \text{when } x < x_1$$

$$F = 0 \quad \text{when } x \geq x_1$$

- The stiffness term grows nonlinearly as penetration increases (exponent 1.5).
- The damping term ramps from zero at the contact surface to `cmax = 50` at 0.1 mm penetration, avoiding a damping discontinuity at first contact.
