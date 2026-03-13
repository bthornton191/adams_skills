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
! Adams auto-creates .pendulum.link.cm when this runs.
! Do NOT pass center_of_mass_marker — .cm doesn't exist yet.
! Moment of inertia for uniform rod about CM: I = (1/12) * m * L^2
! = (1/12) * 1.0 * 200^2 = 3333.33 kg*mm^2
part modify rigid_body mass_properties &
    part_name = .pendulum.link &
    mass      = 1.0 &
    ixx       = 3333.33 &
    iyy       = 3333.33 &
    izz       = 0.0

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
