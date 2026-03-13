# One-Sided Contact Force Expression (Floor at Z = 0)

Use the `IMPACT()` function for one-sided contact. It produces a smooth, continuous force that activates when the displacement `x` drops below the threshold `x1`, avoiding the derivative discontinuities that a manual `IF()` would introduce.

## FUNCTION= Expression

```cmd
function = "IMPACT(DZ(.model.body.cm, .model.ground.ref, .model.ground.ref), &
                   VZ(.model.body.cm, .model.ground.ref, .model.ground.ref, .model.ground.ref), &
                   0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

## Parameter Breakdown

| Argument | Value | Meaning |
|---|---|---|
| `x` | `DZ(.model.body.cm, .model.ground.ref, .model.ground.ref)` | Z-distance of the part CM above the floor reference |
| `x_dot` | `VZ(.model.body.cm, .model.ground.ref, .model.ground.ref, .model.ground.ref)` | Z-velocity of the part CM |
| `x1` | `0.0` | Contact activates when Z drops below 0 (the floor) |
| `k` | `1.0E5` | Contact stiffness |
| `e` | `1.5` | Force exponent (Hertzian contact) |
| `cmax` | `50.0` | Maximum damping coefficient |
| `d` | `0.1` | Penetration depth (mm) at which full damping is applied |

## Notes

- Replace `.model.body.cm` with the actual dot-path to your part's CM marker.
- Replace `.model.ground.ref` with the actual dot-path to your floor reference marker.
- The `&` continuation character is required for multi-line CMD expressions.
- Do **not** specify `adams_id` manually on the force object.
- All keywords (e.g., `function`) must be spelled out in full — no abbreviations.
