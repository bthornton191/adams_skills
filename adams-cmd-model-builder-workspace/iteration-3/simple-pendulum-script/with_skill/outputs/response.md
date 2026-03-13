# Simple Pendulum — Adams CMD Script

Here is a complete `.cmd` script that builds the simple pendulum model in Adams View.

## Design Decisions

- **Pivot at origin** `(0, 0, 0)` — the ground marker and the link's pin marker are both placed here.
- **Tip marker at** `(0, -200, 0)` — 200 mm below the pivot in the -Y direction.
- **CM marker** — Adams automatically creates a `cm` marker on each part at its local origin. This is referenced in `part modify rigid_body mass_properties`.
- **Moment of inertia** — For a uniform rod about its centre of mass: $I = \tfrac{1}{12}mL^2 = \tfrac{1}{12}(1.0)(200^2) \approx 3333\ \text{kg·mm}^2$.
- **Initial condition** — 45 degrees is applied via a second `part modify rigid_body name_and_position` call (orientation only), which is the correct way to set an initial angle without re-creating the part.
- **Gravity** — Standard Adams gravity magnitude of 9806.65 mm/s² (≡ 9.80665 m/s²), acting in the -Y direction.

## Script

```cmd
! Simple Pendulum Model
! A single rigid link (200 mm, 1 kg) pinned at its top end to ground.
! Gravity acts in the -Y direction. Released from 45 degrees.

! --- 1. Model and units ---
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Ground marker at the pivot point ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 3. Create the link part ---
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Set mass properties ---
! Moment of inertia for uniform rod about CM: I = (1/12) * m * L^2
! = (1/12) * 1.0 * 200^2 = 3333.33 kg*mm^2
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.33 &
    iyy                   = 3333.33 &
    izz                   = 0.0

! --- 5. Markers on the link ---
! Pin marker at the top end (coincident with pivot)
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker at the bottom end
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Revolute joint at the pivot ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 7. Initial angle (45 degrees from vertical, rotation about Z axis) ---
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 8. Gravity in -Y direction ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0
```

## Key Rules Applied

| Rule | Applied |
|---|---|
| `part create` called only once per part | ✔ — `part modify` used for mass and initial orientation |
| No `adams_id` specified | ✔ |
| All keywords spelled out in full | ✔ |
| Dot-path object names | ✔ — e.g. `.pendulum.link.pin_mkr` |
| Angles use `D` suffix | ✔ — `45.0D`, `0.0D` |
| Build order respected | ✔ — model → parts → mass props → markers → constraints → initial conditions → forces |
