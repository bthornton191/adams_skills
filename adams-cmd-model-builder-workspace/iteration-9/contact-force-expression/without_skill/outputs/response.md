# One-Sided Contact Force Expression (Floor at Z = 0)

## FUNCTION= Expression

```
IMPACT(DZ(.model.part.cm), VZ(.model.part.cm), 0.0, 1.0E+05, 1.5, 50.0, 0.1)
```

## Parameters

| Argument | Value | Description |
|---|---|---|
| `x` | `DZ(.model.part.cm)` | Current Z position of the part's CM (gap from floor) |
| `x_dot` | `VZ(.model.part.cm)` | Z velocity of the part's CM |
| `x1` | `0.0` | Floor level — contact activates when `x < x1` |
| `k` | `1.0E+05` | Stiffness (N/mm) |
| `e` | `1.5` | Force exponent |
| `cmax` | `50.0` | Maximum damping coefficient (N·s/mm) |
| `d` | `0.1` | Penetration depth at which full damping is applied (mm) |

## How It Works

The Adams `IMPACT` function computes a one-sided spring-damper contact force:

$$F = k \cdot (x_1 - x)^e - c_{max} \cdot \text{STEP}(x,\, x_1 - d,\, 0,\, x_1,\, 1) \cdot \dot{x}$$

- When the CM is **above** the floor (`DZ > 0`): `x > x1`, so `F = 0` (no contact).
- When the CM **penetrates** the floor (`DZ < 0`): `x < x1`, and the function returns a positive (upward) restoring force.

The damping term ramps from 0 to `cmax` over the first `d = 0.1 mm` of penetration via the `STEP` function, preventing a discontinuous damping jump at first contact.

## Complete Force Definition (Adams CMD)

```adams_cmd
! Apply as a single-component force acting in the +Z direction (action-only)
force create direct single_component_force &
    single_component_force_name = .model.floor_contact &
    type_of_freedom             = translational &
    action_only                 = on &
    i_marker_name               = .model.part.cm &
    j_floating_marker_name      = .model.ground.flt_mkr &
    ref_marker_name             = .model.ground.ref &
    function = "IMPACT(DZ(.model.part.cm), VZ(.model.part.cm), 0.0, 1.0E+05, 1.5, 50.0, 0.1)"
```

### Key points
- `type_of_freedom = translational` — the force acts along a translational axis.
- `action_only = on` — the reaction is absorbed by ground; suitable for floor contact.
- The force direction is along the Z-axis of `ref_marker_name` (global Z when using `.model.ground.ref`), so the positive IMPACT value pushes the part upward (+Z), opposing penetration.
- Replace `.model.part.cm` with the actual fully-qualified marker name for your model.
