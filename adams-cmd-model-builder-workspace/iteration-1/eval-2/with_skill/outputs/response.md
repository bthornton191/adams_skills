# One-Sided Floor Contact: FUNCTION= Expression

## Overview

The `IMPACT` function is the correct choice for a one-sided contact because it activates only when a displacement variable drops below a trigger value, and produces a smoothly-ramped repulsive force with nonlinear stiffness and viscous damping.

**Contact activates when:** `DZ(part_CM, floor_ref) < 0.0` (part's CM penetrates the Z = 0 plane)

**Force equation during penetration** (penetration depth `d = 0.0 − DZ`):

$$F = K \cdot d^{e} - C \cdot \text{STEP}(d,\, 0,\, 0,\, \delta,\, 1) \cdot \dot{z}$$

where `K = 1e5`, `e = 1.5`, `C = 50`, `δ = 0.1 mm`.

---

## The FUNCTION= Expression

```cmd
function = "IMPACT( &
    DZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
    VZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, &
       .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
    0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

### Argument-by-argument breakdown

| Argument | Value | Meaning |
|---|---|---|
| Displacement Var | `DZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF)` | Z-component of the vector from `FLOOR_REF` to `BODY.cm`, measured along global Z |
| Velocity Var | `VZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF)` | Z-velocity of `BODY.cm` relative to `FLOOR_REF` in the global frame |
| Trigger | `0.0` | Floor is at Z = 0; contact activates when `DZ < 0.0` |
| K | `1.0E5` | Contact stiffness (N/mm^1.5 in mm-kg-s) |
| e | `1.5` | Hertz exponent — models elastic contact between curved surfaces |
| C | `50.0` | Maximum damping coefficient (N·s/mm) |
| d | `0.1` | Damping ramp-up distance (mm); damping ramps from 0 → C over first 0.1 mm of penetration to avoid a step change at contact initiation |

> **Critical pairing rule:** The `Along Marker` and `Reference Frame` arguments of `VZ` must match the `Along Marker` argument of `DZ`. Both use `FLOOR_REF` here to ensure the velocity fed to IMPACT is the true time derivative of the displacement fed to IMPACT.

---

## Full CMD Implementation

This snippet creates the required ground reference marker and the contact force element. Substitute `.MY_MODEL` and `.MY_MODEL.BODY` with your actual model and part names.

```cmd
! ─── Prerequisites ───────────────────────────────────────────────────────────
! Assumes the following already exist in the model:
!   .MY_MODEL              – the model
!   .MY_MODEL.BODY         – the part whose CM is monitored
!   .MY_MODEL.BODY.cm      – Adams-generated CM marker (created automatically
!                            when mass properties are set on the part)
! ─────────────────────────────────────────────────────────────────────────────

! Step 1: Create a reference marker on ground at the floor plane (Z = 0)
! Default orientation → z-axis points in global +Z (upward)
marker create &
    marker_name = .MY_MODEL.ground.FLOOR_REF &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Step 2: Create the contact force
! action_only = on   → no equal-and-opposite reaction on the ground
! Force acts along the z-axis of the i_marker (.MY_MODEL.BODY.cm)
! Ensure the i_marker's z-axis points in global +Z at the start of simulation
force create body_force single_component_force &
    force_name        = .MY_MODEL.FLOOR_CONTACT &
    adams_id          = 10 &
    i_marker_name     = .MY_MODEL.BODY.cm &
    j_floating_marker = .MY_MODEL.ground.FLOOR_REF &
    action_only       = on &
    function          = "IMPACT( &
        DZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
        VZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, &
           .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
        0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

---

## Notes and Caveats

### Units
The parameters above assume a **mm-kg-s** unit system:
- K = 1×10⁵ N/mm^1.5
- C = 50 N·s/mm
- d = 0.1 mm

If your model uses **MKS (m-kg-s)**, convert accordingly: K in N/m^1.5, C in N·s/m, d in m (0.0001 m for 0.1 mm).

### Force direction and part rotation
`single_component_force` applies the force along the **z-axis of the i_marker**. Here the i_marker is `.MY_MODEL.BODY.cm`. If the part undergoes significant rotation during simulation such that the cm marker's z-axis deviates from global +Z, the contact force direction will deviate accordingly.

For bodies that rotate substantially, use a `vector_force` instead to guarantee the contact force always acts in global +Z:

```cmd
force create body_force vector_force &
    force_name          = .MY_MODEL.FLOOR_CONTACT &
    adams_id            = 10 &
    i_marker_name       = .MY_MODEL.BODY.cm &
    j_floating_marker   = .MY_MODEL.ground.FLOOR_REF &
    ref_marker_name     = .MY_MODEL.ground.FLOOR_REF &
    function_x          = "0" &
    function_y          = "0" &
    function_z          = "IMPACT( &
        DZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
        VZ(.MY_MODEL.BODY.cm, .MY_MODEL.ground.FLOOR_REF, &
           .MY_MODEL.ground.FLOOR_REF, .MY_MODEL.ground.FLOOR_REF), &
        0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

### Why IMPACT and not IF or STEP?
- `IF` introduces a derivative discontinuity at contact; the solver must take a very small step at the transition and may struggle with convergence.
- `IMPACT` ramps damping smoothly over the first `d = 0.1 mm` of penetration via an internal `STEP`, giving the integrator a smooth transition from zero force to full contact force. This is the recommended approach for contact modeling in Adams.

### Choosing the damping ramp-up distance `d`
The value `d = 0.1 mm` means damping reaches its full value `C = 50 N·s/mm` after 0.1 mm of penetration. If `d` is too large relative to expected penetration, the contact will feel underdamped; if too small, it approximates a step and can cause integrator step-size reduction. A good heuristic: set `d` to roughly 1–10% of the expected maximum penetration depth.
