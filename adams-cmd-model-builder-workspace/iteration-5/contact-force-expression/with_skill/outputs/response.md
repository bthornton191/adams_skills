# One-Sided Floor Contact Force — FUNCTION= Expression

## Setup

The scenario requires a contact force that:
- Activates when a part's CM drops **below Z = 0** (the floor)
- Uses the `IMPACT` function for a smooth, nonlinear repulsive force

**Parameters:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `K` | `1.0E5` | Contact stiffness (N/mm^e) |
| `e` | `1.5` | Stiffness exponent (Hertz contact) |
| `C` | `50.0` | Maximum damping coefficient (N·s/mm) |
| `d` | `0.1` | Damping ramp-up penetration depth (mm) |
| Trigger | `0.0` | Floor Z-coordinate; contact activates when DZ < 0.0 |

---

## FUNCTION= Expression

```
IMPACT(DZ(.model.body.cm, .model.ground.global_mkr, .model.ground.global_mkr),
       VZ(.model.body.cm, .model.ground.global_mkr, .model.ground.global_mkr, .model.ground.global_mkr),
       0.0, 1.0E5, 1.5, 50.0, 0.1)
```

**How it works:**

- `DZ(cm, global_mkr, global_mkr)` — Z-component of the CM's position relative to the floor reference, measured along the ground marker's Z-axis (= global Z when the marker is at the origin with default orientation). This value is positive when the CM is above Z = 0.  
- `VZ(cm, global_mkr, global_mkr, global_mkr)` — Z-velocity of the CM in the same frame. The fourth argument specifies the reference frame for the velocity measurement; using the ground marker gives velocity in the global frame.  
- `trigger = 0.0` — Contact activates when `DZ < 0.0` (CM below floor).  
- `penetration = 0.0 - DZ = -DZ` — positive depth when CM is below Z = 0.  
- `K = 1.0E5`, `e = 1.5` — Hertz-type stiffness: force grows as `1e5 × depth^1.5`.  
- `C = 50.0`, `d = 0.1` — Damping ramps from 0 to 50 N·s/mm over the first 0.1 mm of penetration, preventing an instantaneous damping spike at first contact.

**Force equation (while penetrating):**

$$F = K \cdot (-\text{DZ})^{e} - C \cdot \text{STEP}(-\text{DZ},\, 0,\, 0,\, d,\, 1) \cdot V_Z$$

$$F = 10^5 \cdot (-\text{DZ})^{1.5} - 50 \cdot \text{STEP}(-\text{DZ},\, 0,\, 0,\, 0.1,\, 1) \cdot V_Z$$

This force is applied in the +Z direction (upward), preventing the body from passing through the floor.

---

## Complete CMD Implementation

A `force_vector` is used so that the contact force is guaranteed to act in the global +Z direction, regardless of the body's XY position.

```cmd
! ============================================================
! One-sided floor contact force (floor at Z = 0)
! ============================================================

! Reference marker at the world origin on the ground part.
! Assumes .model.ground.global_mkr already exists (e.g., at 0,0,0
! with default orientation so its Z-axis = global Z).
! If it does not exist, create it:
marker create &
    marker_name = .model.ground.global_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Apply the contact force as a vector force so the direction
! is fixed to global +Z (upward, away from the floor).
force create direct force_vector &
    force_vector_name = .model.floor_contact &
    i_marker_name     = .model.body.cm &
    j_part_name       = .model.ground &
    ref_marker_name   = .model.ground.global_mkr &
    function_x        = "0.0" &
    function_y        = "0.0" &
    function_z        = "IMPACT(DZ(.model.body.cm, .model.ground.global_mkr, &
                                   .model.ground.global_mkr), &
                                VZ(.model.body.cm, .model.ground.global_mkr, &
                                   .model.ground.global_mkr, .model.ground.global_mkr), &
                                0.0, 1.0E5, 1.5, 50.0, 0.1)"
```

### Key design choices

| Choice | Rationale |
|--------|-----------|
| `force_vector` with `function_z` | Guarantees the repulsive force is always in global +Z regardless of the body's translational position. A `single_component_force` would apply force along the I-to-J line, which may not be vertical if the body drifts in XY. |
| `j_part_name = .model.ground` | Adams auto-creates a floating marker on the ground part, no manual J marker management needed. |
| `ref_marker_name = .model.ground.global_mkr` | Defines the coordinate frame for `function_x/y/z` — global_mkr at the origin with default orientation aligns Z with global Z (upward). |
| `i_marker_name = .model.body.cm` | Adams auto-creates `.body.cm` when mass is set. If the contact point should be the bottom of the body rather than the CM, create a separate marker at the bottom and substitute it here (update the IMPACT arguments to match). |
| `trigger = 0.0` | Floor is at Z = 0 in the model. If the floor is at a different elevation, change the trigger to that Z value and place `global_mkr` at that elevation. |

---

## Notes on Units

The parameters assume **mm-kg-s** units (Adams defaults when `length = mm`, `force = newton`, `mass = kg`, `time = sec`):

| Quantity | Units |
|----------|-------|
| K = 1.0E5 | N / mm^1.5 |
| C = 50 | N·s / mm |
| d = 0.1 | mm |
| DZ | mm |
| Force output | N |

If using MKS (m-kg-s), scale accordingly: K would be in N/m^1.5, C in N·s/m, and d in m.

---

## IMPACT Argument Mapping

```
IMPACT(
  DZ(.model.body.cm, .model.ground.global_mkr, .model.ground.global_mkr),  ! displacement variable
  VZ(.model.body.cm, .model.ground.global_mkr,                              ! velocity variable
     .model.ground.global_mkr, .model.ground.global_mkr),
  0.0,     ! trigger — Z = 0 is the floor
  1.0E5,   ! K — contact stiffness
  1.5,     ! e — stiffness exponent (Hertz)
  50.0,    ! C — max damping coefficient
  0.1      ! d — damping ramp-up distance (mm)
)
```
