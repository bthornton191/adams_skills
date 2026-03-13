# One-Sided Floor Contact Force — FUNCTION= Expression

## Overview

To model a one-sided contact force that activates when a part's CM falls below Z = 0, use the Adams `IMPACT` function. This function generates a repulsive force when a displacement variable drops below a trigger threshold.

## FUNCTION= Expression

```
"IMPACT(DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref), &
        VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref), &
        0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

### Parameter Mapping

| Argument | Value | Meaning |
|----------|-------|---------|
| Displacement Var | `DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-component of part CM position measured from floor reference marker |
| Velocity Var | `VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-component of part CM velocity in the same reference frame |
| Trigger | `0.0` | Contact activates when DZ < 0.0 (CM crosses below Z = 0) |
| K | `1.0E5` | Contact stiffness (N/mm^e or applicable units) |
| e | `1.5` | Stiffness exponent — Hertz contact value |
| C | `50.0` | Maximum damping coefficient |
| d | `0.1` | Damping ramp-up distance (mm) — damping ramps from 0 to C over first 0.1 mm of penetration |

### Force Equation

When penetration depth $\delta = 0.0 - \text{DZ} > 0$:

$$F = K \cdot \delta^e - C \cdot \text{STEP}(\delta,\, 0,\, 0,\, 0.1,\, 1) \cdot V_z$$

The STEP term prevents a damping discontinuity at initial contact by ramping the damping coefficient from 0 up to C over the first 0.1 mm of penetration.

---

## Full CMD Example

```cmd
! ============================================================
! One-sided floor contact at Z = 0
! Part CM monitored: .model.part.cm (auto-created CM marker)
! Floor reference:   .model.ground.floor_ref at origin (0, 0, 0)
! Stiffness:  K = 1e5   [N/mm^e]
! Exponent:   e = 1.5   (Hertz contact)
! Damping:    C = 50.0  [N·s/mm]
! Ramp depth: d = 0.1   [mm]
! ============================================================

! Create floor reference marker on ground at Z = 0
marker create &
    marker_name = .model.ground.floor_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Create the contact force (action-only — no reaction on ground)
force create direct single_component_force &
    single_component_force_name = .model.floor_contact &
    i_marker_name               = .model.part.cm &
    j_part_name                 = .model.ground &
    action_only                 = off &
    function                    = "IMPACT( &
        DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref), &
        VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, &
           .model.ground.floor_ref), &
        0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

---

## Key Notes

1. **`DZ` vs `DM`**: Use `DZ` (not `DM`) because `DM` is always positive and cannot detect which side of the floor the part is on. `DZ` with a shared reference frame measures the signed Z-distance from the floor.

2. **Trigger = 0.0**: Since the floor is at Z = 0 and we monitor `DZ` of the CM from a marker *at* Z = 0, the trigger is `0.0`. The force is zero when the CM is above the floor (`DZ > 0`) and positive when the CM penetrates below (`DZ < 0`).

3. **Velocity variable**: `VZ` must use exactly the same marker arguments as `DZ` (with the addition of a reference frame marker as the 4th argument). Mismatched arguments create solver errors.

4. **`action_only`**: Set to `off` so the reaction is applied to the ground part (physically correct — the floor pushes back on the part). Set to `on` only if you are modelling a force with no reaction (e.g., an environmental load with no physical floor geometry).

5. **Exponent e = 1.5**: This is the classic Hertz contact exponent for spherical contact. For rigid flat-on-flat contact, e = 1.0 may be more appropriate.

6. **Units**: The values above assume an mm-N-s unit system. The stiffness `1e5 N/mm^1.5`, damping `50 N·s/mm`, and ramp-up `0.1 mm` must be consistent with your model's unit settings. Verify with `defaults units` at the top of your script.
