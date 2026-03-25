! ============================================================
! Simple Pendulum
!
! A single 200 mm rigid link pinned to ground at the top.
! Released from 45 degrees and allowed to swing freely under gravity.
! Gravity acts in the -Y direction.
!
! Model topology:
!   .pendulum
!   ├── ground
!   │   └── pivot_mkr    (pin point on ground, at origin)
!   └── link
!       ├── cm           (centre of mass, at midpoint of rod)
!       ├── pin_mkr      (upper end of link, at part origin / joint location)
!       ├── tip_mkr      (lower end, 200 mm below pin in local -Y)
!       └── rod_mkr      (cylinder geometry reference, Z oriented toward tip)
! ============================================================

! --- 1. Model and units ---
model create &
    model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Ground marker at the pivot ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 3. Create the link part ---
!     Part origin placed at the pivot point (global origin).
!     This simplifies the initial-condition rotation about the pin.
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. CM marker at the midpoint of the rod (local -Y direction) ---
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Set mass/inertia properties (via part modify, not part create) ---
!     For a uniform thin rod of length L = 200 mm, mass m = 1 kg:
!       Ixx = Izz = (1/12) * m * L^2 = (1/12) * 1 * 200^2 = 3333.3 kg*mm^2
!       Iyy is set to a small non-zero value (thin-rod approximation)
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.3 &
    iyy                   = 1.0 &
    izz                   = 3333.3 &
    center_of_mass_marker = .pendulum.link.cm

! --- 6. Pin marker at the top of the link (coincident with pivot_mkr at 0 deg) ---
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 7. Tip marker at the bottom of the link (200 mm below pin in local -Y) ---
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Revolute joint at the pivot (rotation about global Z axis) ---
!     I marker on the moving part, J marker on ground.
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 9. Set initial orientation: release from 45 degrees ---
!     Body-313 Euler angles (psi=0, theta=0, phi=45D) rotates the link 45 deg about Z.
!     Because the part origin is at the pivot, this rotates the link about the pin.
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 10. Gravity in the -Y direction ---
!     In mm-kg-N units, g = 9806.65 mm/s^2
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 11. Visualization geometry ---

! Marker for cylinder orientation.
! Body-313 Euler orientation = (0D, 90D, 0D) makes the cylinder Z-axis
! point in the global -Y direction, so the cylinder runs pin -> tip.
marker create &
    marker_name = .pendulum.link.rod_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D

! Cylinder for the rod body
geometry create shape cylinder &
    cylinder_name = .pendulum.link.rod_cyl &
    center_marker = .pendulum.link.rod_mkr &
    length        = 200.0 &
    radius        = 4.0 &
    angle_extent  = 360.0D

! Sphere at the pivot end
geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.pivot_ellips &
    center_marker  = .pendulum.link.pin_mkr &
    x_scale_factor = 12.0 &
    y_scale_factor = 12.0 &
    z_scale_factor = 12.0

! --- 12. Transient simulation ---
!     2.0 seconds at 1000 output steps; released from IC without static solve.
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
