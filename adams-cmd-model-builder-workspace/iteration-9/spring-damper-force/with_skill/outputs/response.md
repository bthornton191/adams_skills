# Creating a Spring-Damper Force in Adams CMD

Use `force create element_like translational_spring_damper`. The free length is set via `displacement_at_preload` (not `length`).

## Syntax

```cmd
force create element_like translational_spring_damper &
    spring_damper_name      = .model.spring_1 &
    i_marker_name           = .model.part_a.spring_i_mkr &
    j_marker_name           = .model.part_b.spring_j_mkr &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0
```

## Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| `stiffness` | `5000.0` | N/mm |
| `damping` | `100.0` | N·s/mm |
| `displacement_at_preload` | `250.0` | Free length in mm — the distance at which preload force = 0 |
| `preload` | `0.0` | Initial preload force at the free length; set to 0 for no preload |

## Key Rules

- **Correct keyword** is `translational_spring_damper`, not `spring_damper`.
- **Free length** is `displacement_at_preload`, not `length`. Using `length = 250.0` will error.
- The I and J markers define the line of action. Place them on the two parts at the spring attachment points.
- Force equation: `F = −K × (d − d₀) − C × ḋ`, where `d₀` = `displacement_at_preload`.

## Complete Example

The example below creates two parts connected by the spring-damper, with part_b free to translate vertically.

```cmd
! --- Model and units ---
model create model_name = spring_model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- Gravity ---
force create body gravitational &
    gravity_field_name  = .spring_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- Ground anchor marker ---
marker create &
    marker_name = .spring_model.ground.spring_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- Moving part (part_b), positioned 250 mm above ground (free length) ---
part create rigid_body name_and_position &
    part_name   = .spring_model.part_b &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .spring_model.part_b.cm &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .spring_model.part_b &
    mass                  = 5.0 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 1000.0 &
    center_of_mass_marker = .spring_model.part_b.cm

! Spring attachment marker on part_b (at part origin = bottom of part)
marker create &
    marker_name = .spring_model.part_b.spring_i_mkr &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Translational joint to constrain lateral motion
constraint create joint translational &
    joint_name    = .spring_model.trans_1 &
    i_marker_name = .spring_model.part_b.spring_i_mkr &
    j_marker_name = .spring_model.ground.spring_j_mkr

! Geometry for part_b
geometry create shape cylinder &
    cylinder_name  = .spring_model.part_b.shape_cyl &
    center_marker  = .spring_model.part_b.cm &
    angle_extent   = 360.0 &
    length         = 50.0 &
    radius         = 20.0 &
    side_count_for_body = 16

! --- Spring-Damper force ---
!     stiffness = 5000 N/mm, damping = 100 N·s/mm, free length = 250 mm
force create element_like translational_spring_damper &
    spring_damper_name      = .spring_model.spring_1 &
    i_marker_name           = .spring_model.part_b.spring_i_mkr &
    j_marker_name           = .spring_model.ground.spring_j_mkr &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0

! --- Simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .spring_model &
    initial_static  = no
```
