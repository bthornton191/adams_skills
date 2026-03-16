! ============================================================
! simple_pendulum.cmd
! Adams/View Command Script
!
! Simple Pendulum Model
!   - Single rigid link, length = 200 mm, mass = 1 kg
!   - Revolute joint to ground at top end (origin)
!   - Gravity in the -Y direction (9806.65 mm/s^2)
!   - Initial angle = 45 degrees from vertical (-Y axis)
!   - Released from rest (zero initial velocity)
! ============================================================

defaults units &
   length = mm &
   angle = deg &
   force = newton &
   mass = kg &
   time = sec

! Create model
model create &
   model_name = SIMPLE_PENDULUM

! ------------------------------------------------------------
! Gravity: -Y direction
! In mm-kg-N units, g = 9806.65 mm/s^2
! ------------------------------------------------------------
force gravity &
   model_name = SIMPLE_PENDULUM &
   x_gravity = 0.0 &
   y_gravity = -9806.65 &
   z_gravity = 0.0

! ============================================================
! Ground pivot marker at the origin
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.ground.GROUND_PIVOT &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Pendulum link
!
! The pin is at the origin. At 45 degrees from the vertical
! (-Y axis), the CM of the link (mid-point) is located at:
!
!   x_cm =  (L/2) * sin(45 deg) = 100 * 0.70711 =  70.7107 mm
!   y_cm = -(L/2) * cos(45 deg) = 100 * 0.70711 = -70.7107 mm
!
! Moment of inertia of a uniform slender rod about its CM:
!   I_perp = (1/12) * m * L^2
!           = (1/12) * 1.0 kg * (200 mm)^2
!           = 3333.33 kg*mm^2
!
! The pendulum swings in the X-Y plane (rotates about Z), so
! Izz is the governing term. Ixx and Iyy are set equal to Izz
! for simplicity (they do not affect this planar motion).
! ============================================================
part create rigid_body name_and_position &
   part_name = .SIMPLE_PENDULUM.LINK &
   location = 70.7107, -70.7107, 0.0 &
   orientation = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
   part_name = .SIMPLE_PENDULUM.LINK &
   mass = 1.0 &
   center_of_mass_marker = .SIMPLE_PENDULUM.LINK.cm &
   ixx = 3333.333 &
   iyy = 3333.333 &
   izz = 3333.333 &
   ixy = 0.0 &
   izx = 0.0 &
   iyz = 0.0

! ============================================================
! Marker on link at the pivot (top end, coincident with origin)
! This marker constrains the link to ground via the revolute
! joint. At this initial position it sits at the global origin.
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.LINK.LINK_PIVOT &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Marker on link at the free tip (bottom end)
!
!   x_tip =  L * sin(45 deg) = 200 * 0.70711 = 141.4214 mm
!   y_tip = -L * cos(45 deg) = 200 * 0.70711 = -141.4214 mm
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.LINK.LINK_TIP &
   location = 141.4214, -141.4214, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Revolute joint: LINK pivot pinned to GROUND pivot
!
! The revolute joint removes 5 DOF (3 translational + 2
! rotational), leaving 1 rotational DOF about the joint Z-axis.
! Because the marker Z-axes align with the global Z, the
! pendulum swings freely in the X-Y plane.
! ============================================================
constraint create joint revolute &
   joint_name = .SIMPLE_PENDULUM.REVOLUTE_JOINT &
   i_marker_name = .SIMPLE_PENDULUM.LINK.LINK_PIVOT &
   j_marker_name = .SIMPLE_PENDULUM.ground.GROUND_PIVOT

! ============================================================
! Transient simulation: 5 seconds, 500 output steps
! No initial static equilibrium (released from 45 deg at rest)
! ============================================================
simulation single_run transient &
   model_name = .SIMPLE_PENDULUM &
   sim_name = .SIMPLE_PENDULUM.ANALYSIS_1 &
   time_duration = 5.0 &
   number_of_steps = 500 &
   initial_static = no
