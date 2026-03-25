# Creating a Spring-Damper Force in Adams CMD

In Adams/View CMD scripting, a translational spring-damper is created with the
`force create element translational_spring_damper` command.

## Minimal Example

```cmd
force create element translational_spring_damper &
    spring_damper_name = .model.spring_damper &
    i_marker_name      = .model.part1.spring_i &
    j_marker_name      = .model.part2.spring_j &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    free_length        = 250.0
```

### Parameter Notes

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | 5000.0 | Spring rate (N/mm, matching the model length units) |
| `damping` | 100.0 | Viscous damping coefficient (N·s/mm) |
| `free_length` | 250.0 | Natural (unloaded) length of the spring (mm) |

- The force acts **along the line joining the two markers** (the I–J axis).
- Adams computes the spring force as `F = k*(d - free_length) + c*d_dot`, where `d`
  is the current distance between markers and `d_dot` is its time derivative.
- A **positive force** means the spring is in compression (pushes the markers apart);
  negative means tension.

---

## Full Working Script

The script below builds a minimal two-body model with a vertical spring-damper
connecting `part1` (fixed) and `part2` (free to translate along Y). Units are
millimetres, Newtons, kilograms, and seconds.

```cmd
! ============================================================
! Spring-Damper Force Example
! Stiffness : 5000 N/mm
! Damping   : 100  N·s/mm
! Free length: 250 mm
! ============================================================

! --- 1. Model and units ---
model create model_name = spring_model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (-Y) ---
force create body gravitational &
    gravity_field_name  = .spring_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! Part 1 – fixed anchor at origin
! ============================================================
part create rigid_body name_and_position &
    part_name   = .spring_model.part1 &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .spring_model.part1 &
    mass      = 1.0 &
    ixx       = 1.0 &
    iyy       = 1.0 &
    izz       = 1.0

! Marker at top of spring (on part1, at global origin)
marker create &
    marker_name = .spring_model.part1.spring_i &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Fix part1 to ground with a fixed joint
constraint create joint fixed &
    joint_name    = .spring_model.ground_fix &
    i_marker_name = .spring_model.part1.spring_i &
    j_marker_name = .spring_model.ground.ground_mkr

! Ground reference marker (auto-created ground part)
marker create &
    marker_name = .spring_model.ground.ground_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! Part 2 – moving mass, 250 mm below part1 (natural length)
! ============================================================
part create rigid_body name_and_position &
    part_name   = .spring_model.part2 &
    location    = 0.0, -250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .spring_model.part2 &
    mass      = 5.0 &
    ixx       = 100.0 &
    iyy       = 100.0 &
    izz       = 100.0

! CM marker at part2 origin
marker create &
    marker_name = .spring_model.part2.cm &
    location    = 0.0, -250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Marker at top of part2 (spring attachment)
marker create &
    marker_name = .spring_model.part2.spring_j &
    location    = 0.0, -250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Constrain part2 to translate only along Y (translational joint along Y)
marker create &
    marker_name = .spring_model.part1.trans_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 0.0D, 0.0D

marker create &
    marker_name = .spring_model.part2.trans_ref &
    location    = 0.0, -250.0, 0.0 &
    orientation = 90.0D, 0.0D, 0.0D

constraint create joint translational &
    joint_name    = .spring_model.slider &
    i_marker_name = .spring_model.part2.trans_ref &
    j_marker_name = .spring_model.part1.trans_ref

! ============================================================
! Spring-Damper Force
! ============================================================
force create element translational_spring_damper &
    spring_damper_name = .spring_model.spring_damper &
    i_marker_name      = .spring_model.part1.spring_i &
    j_marker_name      = .spring_model.part2.spring_j &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    free_length        = 250.0

! ============================================================
! Simulation – 2 seconds, 200 steps
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .spring_model &
    initial_static  = no

! ============================================================
! End
! ============================================================
```

---

## Key Rules

1. **Marker alignment** – The two markers do not need to be co-axial in advance;
   Adams always measures the spring force along the instantaneous I–J vector.

2. **Units consistency** – If the model uses `mm`, the stiffness must be in N/mm and
   damping in N·s/mm. If the model uses `m`, convert accordingly.

3. **Free length at rest** – Place the J marker exactly `free_length` away from the
   I marker initially so the spring starts in its natural state (zero force).

4. **Nonlinear spring/damper** – To use a spline-based characteristic instead of
   constant coefficients, replace `stiffness` / `damping` with
   `stiffness_spline_name` / `damping_spline_name`.
