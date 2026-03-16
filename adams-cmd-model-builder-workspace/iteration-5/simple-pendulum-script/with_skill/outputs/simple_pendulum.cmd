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
!       ├── cm           (auto-created by Adams when mass_properties is set)
!       ├── pin_mkr      (upper end of link, at part origin / joint location)
!       ├── tip_mkr      (lower end, 200 mm below pin in local -Y)
!       └── rod_mkr      (cylinder geometry reference, Z oriented toward tip)
! ============================================================

! --- 1. Model and units ---
model create model_name = pendulum

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
!     Part origin is placed at the pivot point (global origin).
!     Locating the part origin at the joint simplifies the initial-condition rotation.
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Set mass/inertia properties ---
!     CM marker must be created first at the midpoint of the rod (local -Y direction).
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

!     For a uniform thin rod of length L = 200 mm, mass m = 1 kg, along the Y-axis:
!       Ixx = Izz = (1/12) * m * L^2 = (1/12) * 1 * 200^2 = 3333.3 kg*mm^2
!       Iyy = 0 (moment about the rod axis itself, zero for a thin rod)
!     Use a small nonzero Iyy to avoid numerical issues (thin-rod approximation).
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.3 &
    iyy                   = 1.0 &
    izz                   = 3333.3 &
    center_of_mass_marker = .pendulum.link.cm

! --- 5. Markers on the link ---
! Pin marker at the top of the link (coincident with pivot_mkr when link is at 0 deg)
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker at the bottom of the link (200 mm below pin in local -Y direction)
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Revolute joint at the pivot (rotation about global Z axis) ---
!     I marker on the moving part, J marker on ground.
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 7. Set initial orientation: release from 45 degrees ---
!     Body-313 Euler angles (psi=0, theta=0, phi=45D) rotates the link 45 deg about Z.
!     Because the part origin is at the pivot, this rotates the link about the pin.
!     The tip moves from (0, -200, 0) to (141.4, -141.4, 0) in global coordinates.
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 8. Gravity in the -Y direction ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 9. Visualization geometry ---

! Ellipsoid at the tip to represent the pendulum bob
geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.bob_ellips &
    center_marker  = .pendulum.link.tip_mkr &
    x_scale_factor = 12.0 &
    y_scale_factor = 12.0 &
    z_scale_factor = 12.0

! Cylinder for the rod body.
! The cylinder extends along the Z-axis of its center_marker. We need a marker
! whose Z-axis points from the pin toward the tip (in the -Y direction).
! Body-313 Euler orientation = (0D, 90D, 0D):
!   Step 1: rotate about Z by psi=0D  -> no change, Z=(0,0,1)
!   Step 2: rotate about body X by theta=90D -> Z becomes (0,-1,0) = -Y direction
!   Step 3: rotate about new Z by phi=0D -> no change
! Result: Z axis of rod_mkr points in -Y, so the cylinder extends pin -> tip.
marker create &
    marker_name = .pendulum.link.rod_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D

geometry create shape cylinder &
    cylinder_name = .pendulum.link.rod_cyl &
    center_marker = .pendulum.link.rod_mkr &
    length        = 200.0 &
    radius        = 4.0 &
    angle_extent  = 360.0D

! --- 10. Transient simulation ---
!     Runs 2.0 seconds at 1000 steps/s output frequency.
!     initial_static = no: release from the IC without a static solve first.
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
