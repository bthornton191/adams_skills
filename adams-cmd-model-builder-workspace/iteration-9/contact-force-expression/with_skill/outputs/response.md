# One-Sided Floor Contact Force Expression

## FUNCTION= Expression

```
IMPACT(DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref),
       VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref),
       0.0, 1.0E5, 1.5, 50.0, 0.1)
```

### Parameter mapping

| Argument | Value | Meaning |
|---|---|---|
| Displacement Var | `DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-position of CM above the floor (negative when penetrating) |
| Velocity Var | `VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-velocity of CM (rate of change of the displacement var, in the same frame) |
| Trigger | `0.0` | Contact activates when DZ < 0 (CM falls below Z = 0) |
| K | `1.0E5` | Contact stiffness |
| e | `1.5` | Stiffness exponent (Hertz contact) |
| C | `50.0` | Maximum damping coefficient |
| d | `0.1` | Penetration depth over which damping ramps from 0 to C (mm) |

**Force law (when penetration depth `p = 0.0 − DZ > 0`):**

$$F = K \cdot p^{1.5} - C \cdot \text{STEP}(p,\, 0,\, 0,\, 0.1,\, 1) \cdot V_Z$$

The damping term is zero at first contact and ramps linearly to full C over 0.1 mm of penetration, preventing a velocity-impulse discontinuity at the instant of contact.

---

## Prerequisites

Two markers are required before creating the force:

```cmd
! Floor reference marker on ground at the contact plane (Z = 0)
marker create &
    marker_name = .model.ground.floor_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D
```

The CM marker `.model.body.cm` must already exist on the moving part (see Rule 10 — always create `.cm` before setting mass properties).

---

## Complete Adams CMD Command

The contact force is applied as a `force_vector` so the direction is explicitly global +Z, independent of marker orientation:

```cmd
force create direct force_vector &
    force_vector_name = .model.contact_floor &
    i_marker_name     = .model.body.cm &
    j_part_name       = .model.ground &
    ref_marker_name   = .model.ground.floor_ref &
    function_x        = "0.0" &
    function_y        = "0.0" &
    function_z        = "IMPACT(DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref),", &
                               "VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref,", &
                               "   .model.ground.floor_ref),", &
                               "0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

`j_part_name = .model.ground` tells Adams to create a floating reaction marker on the ground part automatically. `ref_marker_name` sets the reference frame for the X/Y/Z force components — using `floor_ref` (aligned with global axes) ensures `function_z` acts in the global Z direction.

---

## Notes

- **Units assumed: mm, kg, N, s.** With these units stiffness is N/mm^1.5 and the 0.1 mm ramp-up distance is appropriate for the given stiffness scale.
- **DZ and VZ must use the same reference marker** (`floor_ref` for both From and Along). Mixing frames would produce an incorrect velocity argument and an IMPACT force that does not conserve energy correctly.
- **Trigger = 0.0** because the floor is at Z = 0. If the floor were at Z = −50 mm, the trigger and the `floor_ref` marker location would both shift to Z = −50.
- **`action_only`** is not set here; the equal-and-opposite reaction is transmitted to the ground part via the auto-created floating marker, which is correct physical behaviour for a floor-contact scenario.
