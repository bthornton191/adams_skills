! ============================================================
! Simple Pendulum
!
! A single 200 mm rigid link (1 kg) pinned to ground at its
! top end by a revolute joint. Gravity acts in -Y direction.
! Released from 45 degrees.
!
! Model structure:
!   .pendulum
!   +-- ground
!   |   +-- pivot_mkr        (pin point on ground, at global origin)
!   +-- link
!       +-- cm               (explicitly created at mid-link, 100 mm below pin)
!       +-- pin_mkr          (upper end, at part origin = global origin)
!       +-- tip_mkr          (lower end, 200 mm below pin in part -Y)
! ============================================================

! --- 1. Model and units ---
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (-Y direction) ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground pivot marker at global origin ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Create link part with origin at the pin (upper end) ---
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Create CM marker explicitly at mid-link ---
!     Must exist BEFORE mass_properties so it can be passed
!     as center_of_mass_marker (Rule 10: CM != part origin here).
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Set mass / inertia (CM at mid-link via center_of_mass_marker) ---
!     Uniform rod, L = 200 mm, m = 1 kg.
!     Ixx = Izz = (1/12)*m*L^2 = 3333.33 kg.mm^2
!     Iyy set equal to Ixx to keep the inertia tensor positive-definite.
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.33 &
    iyy                   = 3333.33 &
    izz                   = 3333.33 &
    center_of_mass_marker = .pendulum.link.cm

! --- 7. Additional markers on the link ---

! Pin marker: at part origin (coincides with pivot_mkr)
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker: 200 mm below pin in local -Y
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Revolute joint at pivot ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 9. 45-degree initial condition ---
!     Rotate 45 deg CCW about Z through the part origin (= pin).
!     Part origin does not move, so pin_mkr stays at (0,0,0).
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 10. Visualization geometry ---

! Rod: link bar connecting pin to tip
geometry create shape link &
    link_name = .pendulum.link.shape_rod &
    i_marker  = .pendulum.link.pin_mkr &
    j_marker  = .pendulum.link.tip_mkr &
    width     = 8.0 &
    depth     = 4.0

! Bob: ellipsoid at tip
geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.ellips_bob &
    center_marker  = .pendulum.link.tip_mkr &
    x_scale_factor = 12.0 &
    y_scale_factor = 12.0 &
    z_scale_factor = 12.0

! --- 11. Run transient simulation (3 seconds) ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 3.0 &
    number_of_steps = 300 &
    model_name      = .pendulum &
    initial_static  = no

! ============================================================
! End of pendulum.cmd
! ============================================================
