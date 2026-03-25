# Creating a Spring-Damper Force Between Two Parts in Adams CMD

## Command

Use `force create element_like translational_spring_damper` to create a 1-DOF spring-damper that acts along the line of sight between two markers.

### Key Parameter Notes

- **`displacement_at_preload`** sets the free (natural) length — the distance between markers at which internal force is zero. Use `250.0` for a 250 mm free length.
- **`stiffness`** = 5000.0 (N/mm)
- **`damping`** = 100.0 (N·s/mm)
- **`preload`** = 0.0 means no pre-compression/pre-tension force at the free length.
- The force law is: `F = -K × (d - L0) - C × (ḋ)`, where `d` is the current distance between markers and `L0` is `displacement_at_preload`.

---

## Minimal Example

The spring connects a ground attachment point to a moving part. One marker is placed on ground, one on the moving part.

```cmd
! ============================================================
! Model Setup
! ============================================================
model create model_name = spring_demo

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .spring_demo.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! Ground marker — top of spring attachment (at origin)
! ============================================================
marker create &
    marker_name = .spring_demo.ground.spring_top &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! Moving part — start 250 mm below ground (at free length)
! ============================================================
part create rigid_body name_and_position &
    part_name   = .spring_demo.mass_block &
    location    = 0.0, -250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .spring_demo.mass_block &
    mass      = 5.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

! Geometry for visual inspection
geometry create shape cylinder &
    cylinder_name    = .spring_demo.mass_block.cyl &
    center_marker    = .spring_demo.mass_block.cm &
    angle_extent     = 360.0D &
    length           = 40.0 &
    radius           = 20.0 &
    side_count       = 16

! ============================================================
! Marker on the moving part — bottom of spring attachment
! ============================================================
marker create &
    marker_name = .spring_demo.mass_block.spring_bot &
    location    = 0.0, 0.0, 0.0 &   ! (0,0,0) in part-local = part origin
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! Spring-Damper Force
! ============================================================
force create element_like translational_spring_damper &
    spring_damper_name      = .spring_demo.spring_main &
    i_marker_name           = .spring_demo.mass_block.spring_bot &
    j_marker_name           = .spring_demo.ground.spring_top &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0

! ============================================================
! Run simulation (2 seconds, 500 steps)
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 500 &
    model_name      = .spring_demo &
    initial_static  = no
```

---

## Key Points

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | `5000.0` | Spring rate: 5000 N/mm |
| `damping` | `100.0` | Damping coefficient: 100 N·s/mm |
| `displacement_at_preload` | `250.0` | Free length: no force when markers are 250 mm apart |
| `preload` | `0.0` | Zero pre-load at the free length |

- The I marker (`spring_bot`) is on the **moving part**; the J marker (`spring_top`) is on **ground**.
- The spring force automatically acts along the line connecting the two markers — no special orientation is needed.
- If the part starts at exactly the free length (250 mm separation), the spring begins relaxed and motion is driven purely by gravity.
- **Do NOT use** `spring_damper` (the short form) — the full keyword `translational_spring_damper` is required in scripts.
- **Do NOT use** `length =` — the free length parameter is `displacement_at_preload`, not `length`.
