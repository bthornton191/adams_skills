! ============================================================
! Simple Pendulum — Adams CMD Script
!
! A single 200 mm rigid link pinned to ground at its top end
! by a revolute joint. Mass = 1 kg. Gravity in -Y direction.
! Released from 45 degrees.
!
! Model structure:
!   .pendulum
!   ├── ground
!   │   └── pivot_mkr        (fixed pin point at origin)
!   └── link
!       ├── cm               (midpoint of rod, 100 mm below pin)
!       ├── pin_mkr          (upper end — coincides with pivot_mkr)
!       └── tip_mkr          (lower end — 200 mm below pin)
! ============================================================

! --- 1. Model and units ---
model create &
    model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity in -Y direction (9806.65 mm/s^2) ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground pivot marker at origin ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Create the link part (origin at pin / top end) ---
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. CM marker at midpoint of rod (100 mm below pin in local -Y) ---
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Set mass/inertia properties ---
! Uniform rod: I_cm = (1/12)*m*L^2 = (1/12)*1.0*200^2 = 3333.33 kg*mm^2
! Iyy (along rod axis) is 0 for a thin rod.
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.33 &
    iyy                   = 1.0 &
    izz                   = 3333.33 &
    center_of_mass_marker = .pendulum.link.cm

! --- 7. Pin marker at top of link (local origin, coincident with pivot) ---
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Tip marker at bottom of link (200 mm below pin in local -Y) ---
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 9. Revolute joint at pivot (rotates about Z axis) ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 10. Initial condition: release from 45 degrees ---
! Rotating the part 45 degrees about Z (with part origin at pin) tilts the link 45 deg.
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 11. Geometry (link rod + bob at tip) ---

! Marker for cylinder orientation: Z-axis pointing in -Y direction
marker create &
    marker_name = .pendulum.link.rod_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D

! Cylinder representing the rod body
geometry create shape cylinder &
    cylinder_name = .pendulum.link.rod_cyl &
    center_marker = .pendulum.link.rod_mkr &
    length        = 200.0 &
    radius        = 4.0 &
    angle_extent  = 360.0D

! Ellipsoid bob at the tip
geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.tip_bob &
    center_marker  = .pendulum.link.tip_mkr &
    x_scale_factor = 12.0 &
    y_scale_factor = 12.0 &
    z_scale_factor = 12.0

! Ellipsoid at the pivot (pin) end
geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.pin_ellips &
    center_marker  = .pendulum.link.pin_mkr &
    x_scale_factor = 8.0 &
    y_scale_factor = 8.0 &
    z_scale_factor = 8.0

! --- 12. Transient simulation ---
! 2.0 seconds; 1000 output steps; released from IC without static solve
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 1000 &
    model_name      = .pendulum &
    initial_static  = no
