# One-Sided Contact Force: Part CM Hits Floor at Z = 0

## FUNCTION= Expression

```adams_fn
IMPACT(DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref),
       VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref),
       0.0, 1.0E5, 1.5, 50.0, 0.1)
```

### Argument Breakdown

| Argument | Value | Meaning |
|---|---|---|
| `Displacement Var` | `DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-height of the part's CM above the floor marker, expressed in ground frame |
| `Velocity Var` | `VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-velocity of the CM (time derivative of the displacement var, same frame) |
| `Trigger` | `0.0` | Contact activates when `ZCM < 0` (i.e., part penetrates the floor) |
| `K` | `1.0E5` | Contact stiffness |
| `e` | `1.5` | Stiffness exponent (Hertz contact) |
| `C` | `50.0` | Maximum damping coefficient |
| `d` | `0.1` | Penetration depth over which damping ramps from 0 → C (avoids a damping discontinuity at first contact) |

### How IMPACT Works

The force is zero while `DZ ≥ 0` (part above the floor). Once the CM drops below Z = 0, penetration is:

$$\delta = 0 - DZ = -DZ$$

The contact force magnitude is:

$$F = K \cdot \delta^{e} - C \cdot \text{STEP}(\delta,\, 0,\, 0,\, 0.1,\, 1) \cdot V_Z$$

The stiffness term pushes the body back up; the damping term dissipates energy and is ramped in smoothly over the first 0.1 mm of penetration to avoid solver discontinuities.

---

## Complete CMD Block

Replace `.model`, `.model.body.cm`, and `.model.ground.floor_ref` with your actual model and marker names. The force is applied as a Z-direction action-only force at the part's CM.

```cmd
! Create a reference marker on ground at Z = 0 (the floor)
marker create &
    marker_name = .model.ground.floor_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Apply one-sided contact force in the Z direction
force create direct single_component_force &
    single_component_force_name = .model.floor_contact &
    i_marker_name               = .model.body.cm &
    j_floating_marker           = .model.ground.floor_ref &
    action_only                 = on &
    function                    = "IMPACT(DZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref),", &
                                  "VZ(.model.body.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref),", &
                                  "0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

### Notes

- **Unit system**: The values above assume **mm / N / kg / s** units (`defaults units length = mm`). With those units:
  - `K = 1.0E5` → N/mm^1.5
  - `C = 50.0` → N·s/mm
  - `d = 0.1` → mm
  - If your model uses metres, scale accordingly (K → 1.0E5 N/m^1.5, C → 50 N·s/m, d → 0.0001 m).
- **`action_only = on`**: The force acts on `.model.body` only. There is no equal-and-opposite reaction on ground (ground is fixed and not integrated).
- **`j_floating_marker`**: Using a floating marker on ground means the force direction tracks the ground frame Z-axis throughout the simulation.
- **Velocity argument**: `VZ` takes four arguments — `(To, From, Along, RefFrame)`. All four must use the same reference marker to match the displacement variable's frame.
- **Long function string**: The `FUNCTION=` value is split across three comma-separated quoted strings. Adams concatenates them at load time; this keeps each line short without using `&` continuation inside the expression string.
