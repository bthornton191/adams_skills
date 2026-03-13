! ==============================================================
! Simple Pendulum Model — Adams/View Command File
!
! Model properties:
!   Link length  : 200 mm (uniform slender rod)
!   Link mass    : 1 kg
!   Pivot point  : Global origin (0, 0, 0) — pinned to ground
!   Joint type   : Revolute (rotation about global Z-axis)
!   Gravity      : −Y direction, 9806.65 mm/s²
!   Initial angle: 45° from vertical (−Y axis), tilted toward +X
!
! Units: mm, kg, N, s, deg
!
! Initial global positions at 45° release angle:
!   Pivot end (top) : (  0.000,   0.000, 0)
!   Centre of mass  : ( 70.711, -70.711, 0)
!   Free end (bot)  : (141.421, -141.421, 0)
! ==============================================================


! --------------------------------------------------------------
! 1. Create model and set working units
! --------------------------------------------------------------
model create  &
   model_name = simple_pendulum

defaults units  &
   length = mm  &
   angle = deg  &
   force = newton  &
   mass = kg  &
   time = sec


! --------------------------------------------------------------
! 2. Gravity  (9806.65 mm/s² in the −Y direction)
! --------------------------------------------------------------
force create body gravitational  &
   model_name = .simple_pendulum  &
   x_component_gravity = 0.0  &
   y_component_gravity = -9806.65  &
   z_component_gravity = 0.0


! --------------------------------------------------------------
! 3. Pendulum link part
!
!    The CM is placed at the 45° initial position:
!      x = (L/2)·sin(45°) =  70.711 mm
!      y = (L/2)·cos(45°) = −70.711 mm  (below pivot)
!
!    Orientation: body X-axis points along the link
!    (from pivot toward free end).
!    A rotation of −45° about the global Z-axis maps global X
!    onto the direction (sin 45°, −cos 45°, 0) = link direction
!    at 45° from −Y vertical.
!    → Body 3-1-3 Euler angles: (psi = −45°, theta = 0°, phi = 0°)
! --------------------------------------------------------------
part create rigid_body name_and_position  &
   part_name = .simple_pendulum.link  &
   location = 70.711, -70.711, 0.0  &
   orientation = -45.0, 0.0, 0.0

! Inertia of a uniform slender rod about its CM (L = 200 mm, m = 1 kg):
!   Ixx  (along rod — body X-axis)    ≈ 0  →  set to 1.0 kg·mm² to
!                                               avoid a zero-inertia warning
!   Iyy = Izz (perpendicular to rod)  = (1/12)·m·L²
!                                     = (1/12)·1·200²
!                                     = 3333.33 kg·mm²
!
! The pendulum rotates about the global/body Z-axis, so Izz governs
! the dynamics.  Parallel-axis check: Izz_pivot = Izz_cm + m·d²
!   = 3333.33 + 1·100² = 13 333.33 kg·mm²  =  (1/3)·m·L²  ✓
part modify rigid_body mass_properties  &
   part_name = .simple_pendulum.link  &
   mass = 1.0  &
   center_of_mass_marker = .simple_pendulum.link.cm  &
   ixx = 1.0  &
   iyy = 3333.333  &
   izz = 3333.333  &
   ixy = 0.0  &
   izx = 0.0  &
   iyz = 0.0


! --------------------------------------------------------------
! 4. Markers
!    All locations are given in global (ground) coordinates
!    at the 45° initial configuration.
! --------------------------------------------------------------

! I-marker on the link at the pivot end — also used for the joint
marker create  &
   marker_name = .simple_pendulum.link.pivot_I  &
   part_name = .simple_pendulum.link  &
   location = 0.0, 0.0, 0.0  &
   orientation = 0.0, 0.0, 0.0

! Marker on the link at the free (bottom) end — for geometry
marker create  &
   marker_name = .simple_pendulum.link.free_end  &
   part_name = .simple_pendulum.link  &
   location = 141.421, -141.421, 0.0  &
   orientation = 0.0, 0.0, 0.0

! J-marker on ground at the pivot point
marker create  &
   marker_name = .simple_pendulum.ground.pivot_J  &
   part_name = .simple_pendulum.ground  &
   location = 0.0, 0.0, 0.0  &
   orientation = 0.0, 0.0, 0.0


! --------------------------------------------------------------
! 5. Link geometry  (rectangular cross-section: 10 mm × 10 mm)
! --------------------------------------------------------------
geometry create shape link  &
   part_name = .simple_pendulum.link  &
   link_name = .simple_pendulum.link.geom  &
   i_marker_name = .simple_pendulum.link.pivot_I  &
   j_marker_name = .simple_pendulum.link.free_end  &
   width = 10.0  &
   depth = 10.0


! --------------------------------------------------------------
! 6. Revolute joint
!    Constrains the link to rotate about the global Z-axis at
!    the pivot point.  Both markers have Z aligned with global Z
!    so the joint axis is correctly defined.
! --------------------------------------------------------------
constraint create joint revolute  &
   joint_name = .simple_pendulum.rev_joint  &
   i_marker_name = .simple_pendulum.link.pivot_I  &
   j_marker_name = .simple_pendulum.ground.pivot_J


! --------------------------------------------------------------
! 7. Transient simulation  (5 s, 500 output steps)
!    Remove or comment this block to build the model only.
! --------------------------------------------------------------
simulation single_run transient  &
   sim_name = .simple_pendulum.last_run  &
   time_duration = 5.0  &
   number_of_steps = 500  &
   model_name = .simple_pendulum
