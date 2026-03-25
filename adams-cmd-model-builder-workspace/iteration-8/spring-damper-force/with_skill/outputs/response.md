# Creating a Spring-Damper Force in Adams CMD

Use the `force create element_like translational_spring_damper` command. You need two markers — one on each part — that define the line of action of the spring.

## Required Setup

Before creating the spring-damper, create one marker on each part at the spring attachment points:

```cmd
! Marker on Part A (e.g., ground)
marker create &
    marker_name = .model.ground.spring_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Marker on Part B (the moving part)
marker create &
    marker_name = .model.body.spring_i_mkr &
    location    = 0.0, 0.0, 250.0 &
    orientation = 0.0D, 0.0D, 0.0D
```

## Spring-Damper Command

```cmd
force create element_like translational_spring_damper &
    spring_damper_name      = .model.spring_main &
    i_marker_name           = .model.body.spring_i_mkr &
    j_marker_name           = .model.ground.spring_j_mkr &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0
```

## Parameter Notes

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | `5000.0` | Spring stiffness in N/mm |
| `damping` | `100.0` | Damping coefficient in N·s/mm |
| `displacement_at_preload` | `250.0` | Free (natural) length in mm — the distance at which preload force = 0 |
| `preload` | `0.0` | Force applied at the free length (zero = no preload) |

## Key Rules

- **Use `translational_spring_damper`**, not `spring_damper` — the full keyword is required in scripts.
- **Free length is `displacement_at_preload`**, not `length` — the parameter `length` does not exist on this command.
- The spring force is computed as: `F = −K × (d − d₀) − C × ḋ`, where `d` is the current distance between markers and `d₀` is `displacement_at_preload`.
- The I and J markers define the line of action; Adams measures the scalar distance between them regardless of their orientation.
- Units must be consistent with your model defaults. If you set `defaults units length = mm force = newton`, then stiffness is N/mm and damping is N·s/mm.

## Complete Minimal Example

```cmd
model create model_name = spring_model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .spring_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! Ground attachment marker
marker create &
    marker_name = .spring_model.ground.spring_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Moving part
part create rigid_body name_and_position &
    part_name   = .spring_model.body &
    location    = 0.0, 0.0, 250.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .spring_model.body &
    mass      = 1.0 &
    ixx       = 100.0 &
    iyy       = 100.0 &
    izz       = 100.0

! Spring attachment marker on moving part
marker create &
    marker_name = .spring_model.body.spring_i_mkr &
    location    = 0.0, 0.0, 250.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry for the moving part
geometry create shape cylinder &
    cylinder_name = .spring_model.body.cyl &
    center_marker = .spring_model.body.cm &
    angle_extent  = 360.0D &
    length        = 20.0 &
    radius        = 10.0 &
    side_count    = 16

! Spring-damper force
force create element_like translational_spring_damper &
    spring_damper_name      = .spring_model.spring_main &
    i_marker_name           = .spring_model.body.spring_i_mkr &
    j_marker_name           = .spring_model.ground.spring_j_mkr &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0

! Run simulation
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .spring_model &
    initial_static  = no
```
