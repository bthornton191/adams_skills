# One-Sided Floor Contact — FUNCTION= Expression

## FUNCTION= expression

```adams_fn
IMPACT(DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref),
       VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref),
       0.0, 1.0E5, 1.5, 50.0, 0.1)
```

## Argument breakdown

| Argument | Value | Meaning |
|---|---|---|
| `Displacement Var` | `DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-height of part CM above the floor reference marker (Z=0) |
| `Velocity Var` | `VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref)` | Z-velocity of part CM in ground frame (time derivative of DZ) |
| `Trigger` | `0.0` | Contact activates when `DZ < 0.0`, i.e. CM crosses below Z=0 |
| `K` | `1.0E5` | Contact stiffness (N/mm^1.5 in mm-kg-s units) |
| `e` | `1.5` | Stiffness exponent (Hertz contact) |
| `C` | `50.0` | Maximum damping coefficient (N·s/mm) |
| `d` | `0.1` | Penetration depth over which damping ramps from 0 to C (mm) |

**Force equation (active when penetration `p = 0 - DZ > 0`):**

$$F = K \cdot p^e - C \cdot \text{STEP}(p,\; 0,\; 0,\; \delta,\; 1) \cdot V_Z$$

where $\delta = 0.1\,\text{mm}$, and $V_Z$ is the Z-velocity of the CM.

## Why this setup is correct

- When the CM is **above** Z=0: `DZ ≥ 0 ≥ trigger`, so IMPACT returns 0 (no force).
- When the CM **penetrates** below Z=0: `DZ < 0`, so `p = 0 − DZ > 0`, IMPACT returns a positive force value.
- The `single_component_force` with `action_only = on` applies this positive value **from the I marker (CM, below the floor) toward the J marker (floor reference at Z=0)** — which is the +Z (upward) direction. The sign convention produces a correctly directed repulsive force.

## Complete CMD snippet

```cmd
! Prerequisite: a reference marker on ground at Z=0
marker create &
    marker_name = .model.ground.floor_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! One-sided floor contact applied at the part CM
force create direct single_component_force &
    single_component_force_name = .model.contact_floor &
    i_marker_name               = .model.part.cm &
    j_marker_name               = .model.ground.floor_ref &
    action_only                 = on &
    function                    = "IMPACT(DZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref),", &
                                  " VZ(.model.part.cm, .model.ground.floor_ref, .model.ground.floor_ref, .model.ground.floor_ref),", &
                                  " 0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

> **Substitute names:** Replace `.model` with your model name and `.model.part` with the actual part path. `.model.part.cm` is the CM marker auto-created by Adams when mass properties are set — no need to create it manually.

## Notes

- **Units assumed:** mm-kg-s (lengths in mm, forces in N, time in s).  
  If your model uses MKS (meters), rescale: `K = 1e5` N/m^1.5, `C = 50` N·s/m, `d = 0.0001` m.
- **`action_only = on`** is correct here — the floor is stationary and does not receive a reaction force.
- **Long-expression splitting:** the `function =` value is split across three comma-separated quoted strings; Adams concatenates them at load time. Each line continuation uses `&` per CMD scripting rules.
- **DZ and VZ use the same landmark triple** — the time derivative of `DZ(To, From, Along)` is `VZ(To, From, Along, RefFrame)`. Using the same frame marker for both ensures consistency.
- **Damping ramp-up (`d = 0.1 mm`)** prevents an instantaneous damping jump at first contact, which would otherwise cause solver step-size problems.
