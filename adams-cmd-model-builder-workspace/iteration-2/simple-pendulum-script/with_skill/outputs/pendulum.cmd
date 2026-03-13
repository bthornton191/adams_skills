! ============================================================
! Simple Pendulum — Adams CMD Script
!
! A single rigid link:
!   - Length : 200 mm
!   - Mass   : 1 kg
!   - Pinned to ground at the top end by a revolute joint
!   - Gravity: -Y direction  (9806.65 mm/s²)
!   - Released from 45 degrees from the vertical
!
! Model structure:
!   .pendulum
!   ├── ground
!   │   └── pivot_mkr        (fixed pin point at origin)
!   └── link
!       ├── cm               (centre of mass, 100 mm below pin)
!       ├── pin_mkr          (top end — coincides with pivot_mkr)
!       └── tip_mkr          (bottom end, 200 mm below pin)
! ============================================================

! ---------------------------------------------------------------------------
! 1. Model and units
! ---------------------------------------------------------------------------
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! ---------------------------------------------------------------------------
! 2. Ground: pivot marker at origin
! ---------------------------------------------------------------------------
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ---------------------------------------------------------------------------
! 3. Link part  (part origin placed at the pin location)
! ---------------------------------------------------------------------------
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Centre-of-mass marker — midpoint of the rod, 100 mm below pin along -Y
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pin marker at the top of the link (coincides with pivot_mkr on ground)
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker at the bottom of the link (200 mm below pin along -Y)
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ---------------------------------------------------------------------------
! 4. Mass properties
!    Uniform slender rod, L = 200 mm, m = 1 kg
!    Inertia about the centre of mass (cm marker):
!      ixx = izz = (1/12) * m * L²
!              = (1/12) * 1 * 200² = 3333.33 kg·mm²
!      iyy ≈ 0  (Y is the rod axis — negligible for a thin rod)
! ---------------------------------------------------------------------------
part create rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.33 &
    iyy                   = 0.0 &
    izz                   = 3333.33

! ---------------------------------------------------------------------------
! 5. Visualization geometry
! ---------------------------------------------------------------------------
! Rod — link shape drawn between pin and tip markers
geometry create shape link &
    link_name     = .pendulum.link.rod_shape &
    part_name     = .pendulum.link &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.link.tip_mkr &
    width         = 8.0 &
    depth         = 8.0

! Sphere at the tip to represent the pendulum bob
geometry create shape sphere &
    sphere_name   = .pendulum.link.sphere_bob &
    part_name     = .pendulum.link &
    center_marker = .pendulum.link.tip_mkr &
    radius        = 12.0

! ---------------------------------------------------------------------------
! 6. Revolute joint at the pivot
!    Rotation about the Z-axis of pivot_mkr (= global Z)
! ---------------------------------------------------------------------------
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! ---------------------------------------------------------------------------
! 7. Initial condition — release from 45 degrees
!    Body-313 Euler angles (PSI=0, THETA=0, PHI=45):
!    net effect is a 45° rotation about the global Z-axis.
!    The tip moves from (0, -200, 0) to (+141.4, -141.4, 0).
! ---------------------------------------------------------------------------
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! ---------------------------------------------------------------------------
! 8. Gravity  (g = 9806.65 mm/s² in -Y direction)
! ---------------------------------------------------------------------------
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! End of pendulum.cmd
!
! Suggested simulation settings:
!   simulate transient end_time = 2.0 step_size = 0.002
!
! Theoretical natural period:  T = 2π √(I_pivot / (m g L_cm))
!   where I_pivot = (1/3)*m*L² = (1/3)*1*200² = 13333.33 kg·mm²
!         L_cm    = 100 mm  (distance from pivot to CM)
!         T = 2π √(13333.33 / (1 * 9806.65 * 100))
!           ≈ 2π √(0.001359)
!           ≈ 2π * 0.03687
!           ≈ 0.897 s
! ============================================================
