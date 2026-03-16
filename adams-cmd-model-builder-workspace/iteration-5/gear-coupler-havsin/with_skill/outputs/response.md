# Gear Coupler — Two-Shaft System: Adams CMD Script

## Overview

This script builds a two-shaft gear system in Adams View. Two rigid shaft parts are each pinned to ground via revolute joints on the global Z axis. A gear coupler links them at a 3:1 speed ratio with opposite rotation directions, and a haversine motion generator drives the input shaft with a smooth velocity ramp from 0 to 120 deg/s over the first 0.5 seconds.

---

## Model Structure

| Element | Details |
|---|---|
| Model name | `.gear_coupler` |
| Units | mm, newton, kg, sec |
| Gravity | −Y, 9806.65 mm/s² |
| Input shaft location | Origin (0, 0, 0) |
| Output shaft location | (0, 150, 0) mm |
| Shaft mass | 0.5 kg each |
| Shaft inertia | Ixx = Iyy = 1000 kg·mm², Izz = 50 kg·mm² |
| Gear ratio | 3:1 (input 3× faster, opposite direction) |
| Simulation duration | 2.0 s, 2000 steps |

---

## Build Order

Following Core Rule 6 (model → parts → markers → geometry → data elements → constraints → forces/motions):

1. `model create` — create the model namespace
2. `defaults units` — set unit system
3. `force create body gravitational` — gravity
4. `marker create` on `ground` — fixed joint reference frames
5. `part create rigid_body name_and_position` × 2 — input and output shafts
6. `part modify rigid_body mass_properties` × 2 — mass and inertia (separate from create, per Core Rule 9)
7. `marker create` on each shaft — pin markers for joints, geometry base markers
8. `geometry create shape cylinder` × 2 — shaft visualisation
9. `constraint create joint revolute` × 2 — rev_input and rev_output
10. `constraint create complex_joint coupler` — gear coupling
11. `constraint create motion_generator` — haversine velocity drive
12. `simulation single_run transient` — run

---

## Key Design Decisions

### Part creation vs. modification (Core Rules 9 & 10)

Mass and inertia are set via `part modify rigid_body mass_properties`, never via a second `part create`. Adams auto-creates the `.cm` marker when mass is set; `center_of_mass_marker` is **not** passed to avoid the "cm does not exist" error.

### No `adams_id` (Core Rule 8)

No `adams_id` is specified on any command. Adams assigns identifiers automatically; adding them manually is error-prone.

### Revolute joint Z axis

Both revolute joints use the default marker orientation `0.0D, 0.0D, 0.0D`, which aligns the joint Z axis with the global Z axis. The revolute joint allows rotation about the J-marker Z axis, so both shafts spin about global Z.

### Gear coupler command

```cmd
constraint create complex_joint coupler &
    coupler_name       = .gear_coupler.coupler_gear &
    joint_name         = .gear_coupler.rev_input, .gear_coupler.rev_output &
    type_of_freedom    = rot_rot &
    motion_multipliers = 1.0, -0.333
```

- The full command is `constraint create complex_joint coupler` — the short form `constraint create coupler` is not valid.
- `type_of_freedom = rot_rot` specifies rotational–rotational coupling.
- `motion_multipliers = 1.0, -0.333` enforces:  
  `1.0 × ω_input + (−0.333) × ω_output = 0`  
  The negative second multiplier encodes opposite-direction rotation; the ratio |1.0 / 0.333| = 3 gives the 3:1 speed relationship.

### Motion generator — `time_derivative = velocity`

```cmd
constraint create motion_generator &
    motion_name     = .gear_coupler.motion_drive &
    joint_name      = .gear_coupler.rev_input &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)"
```

`time_derivative = velocity` **must** be specified explicitly. The HAVSIN expression returns an angular velocity value (deg/s); omitting this parameter causes Adams to interpret the output as angular displacement, producing wrong kinematics.

### HAVSIN argument order (differs from STEP)

| Function | Argument order |
|---|---|
| `HAVSIN` | `(x, Begin_At, End_At, Initial_Value, Final_Value)` |
| `STEP`   | `(x, x0, h0, x1, h1)` — value interleaved with boundary |

For the velocity ramp:
```
HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)
              ↑    ↑    ↑     ↑
           begin  end  init  final
```

- When `TIME ≤ 0.0 s` → 0 deg/s
- When `0.0 < TIME < 0.5 s` → haversine interpolation
- When `TIME ≥ 0.5 s` → 120 deg/s (held constant)

Using STEP argument order with HAVSIN (swapping begin/end with init/final) is a common mistake that produces an incorrect ramp profile.

### Geometry cylinders

Each shaft gets a `geometry create shape cylinder` with:
- `center_marker` offset −25 mm in Z, so the 50 mm cylinder is centred on the joint pivot
- `radius = 10.0 mm`, `angle_extent = 360.0D`, `side_count_for_perimeter = 16`

---

## Complete Script

```cmd
! ==============================================================
! gear_coupler.cmd
! Two-shaft gear system — 3:1 speed ratio, opposite directions
! Input shaft: haversine velocity ramp 0 → 120 deg/s over 0.5 s
! Units: mm, newton, kg, sec
! ==============================================================

model create &
    model_name = .gear_coupler

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .gear_coupler.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! Ground markers
marker create &
    marker_name = .gear_coupler.ground.input_pivot &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.ground.output_pivot &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Input shaft
part create rigid_body name_and_position &
    part_name   = .gear_coupler.input_shaft &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .gear_coupler.input_shaft &
    mass      = 0.5 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 50.0

marker create &
    marker_name = .gear_coupler.input_shaft.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.input_shaft.geom_mkr &
    location    = 0.0, 0.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

geometry create shape cylinder &
    cylinder_name            = .gear_coupler.input_shaft.cyl_shaft &
    part_name                = .gear_coupler.input_shaft &
    center_marker            = .gear_coupler.input_shaft.geom_mkr &
    angle_extent             = 360.0D &
    length                   = 50.0 &
    radius                   = 10.0 &
    side_count_for_perimeter = 16

! Output shaft
part create rigid_body name_and_position &
    part_name   = .gear_coupler.output_shaft &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .gear_coupler.output_shaft &
    mass      = 0.5 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 50.0

marker create &
    marker_name = .gear_coupler.output_shaft.pin_mkr &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.output_shaft.geom_mkr &
    location    = 0.0, 150.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

geometry create shape cylinder &
    cylinder_name            = .gear_coupler.output_shaft.cyl_shaft &
    part_name                = .gear_coupler.output_shaft &
    center_marker            = .gear_coupler.output_shaft.geom_mkr &
    angle_extent             = 360.0D &
    length                   = 50.0 &
    radius                   = 10.0 &
    side_count_for_perimeter = 16

! Revolute joints
constraint create joint revolute &
    joint_name    = .gear_coupler.rev_input &
    i_marker_name = .gear_coupler.input_shaft.pin_mkr &
    j_marker_name = .gear_coupler.ground.input_pivot

constraint create joint revolute &
    joint_name    = .gear_coupler.rev_output &
    i_marker_name = .gear_coupler.output_shaft.pin_mkr &
    j_marker_name = .gear_coupler.ground.output_pivot

! Gear coupler: 3:1, opposite directions
constraint create complex_joint coupler &
    coupler_name       = .gear_coupler.coupler_gear &
    joint_name         = .gear_coupler.rev_input, .gear_coupler.rev_output &
    type_of_freedom    = rot_rot &
    motion_multipliers = 1.0, -0.333

! Motion generator: haversine ramp 0→120 deg/s over 0.5 s
constraint create motion_generator &
    motion_name     = .gear_coupler.motion_drive &
    joint_name      = .gear_coupler.rev_input &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)"

! Simulate 2 seconds
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .gear_coupler &
    initial_static  = no
```
