! ============================================================
! Four-Bar Linkage — Adams/View CMD Script
! ============================================================
!
! Planar crank-rocker four-bar linkage mechanism.
!
! Mechanism geometry (initial configuration, crank at 90 deg):
!   A = (  0.000,   0.000, 0)  — crank pivot on ground
!   B = (  0.000, 100.000, 0)  — crank tip / coupler pin
!   C = (233.734, 188.702, 0)  — coupler / rocker pin
!   D = (300.000,   0.000, 0)  — rocker pivot on ground
!
! Link properties:
!   Crank   (A–B): length = 100 mm, mass = 0.5 kg
!   Coupler (B–C): length = 250 mm, mass = 0.5 kg
!   Rocker  (D–C): length = 200 mm, mass = 0.5 kg
!   Ground  (A–D): length = 300 mm (fixed)
!
! Grashof check: s + l = 100 + 300 = 400 <= p + q = 250 + 200 = 450
!   => Crank-rocker mechanism; crank makes full continuous rotations.
!
! Joints: 4 revolute joints (at A, B, C, D)
! Driver: crank rotates at constant 360 deg/s (1 rev/s)
! Simulation: 0 to 2 s, dt_output = 0.001 s (2000 output steps)
! Units: MMKS (mm, kg, N, s)
!
! Inertia: uniform slender rods, Izz_cm = m * L^2 / 12
!   Crank:    0.5 * 100^2 / 12 =  416.667 kg·mm^2
!   Coupler:  0.5 * 250^2 / 12 = 2604.167 kg·mm^2
!   Rocker:   0.5 * 200^2 / 12 = 1666.667 kg·mm^2
!
! Initial position derivation:
!   With crank vertical, B = (0, 100, 0).
!   Solve |BC|=250, |DC|=200  =>  C = (233.734, 188.702, 0)
! ============================================================

defaults units &
   length = mm &
   mass   = kg &
   force  = newton &
   time   = sec

! ============================================================
! Create model
! ============================================================

model create &
   model_name = four_bar

! ============================================================
! Ground markers (fixed pivot points A and D)
! ============================================================

marker create &
   marker_name  = .four_bar.ground.GRND_A &
   location     = 0.0, 0.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

marker create &
   marker_name  = .four_bar.ground.GRND_D &
   location     = 300.0, 0.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! ============================================================
! CRANK  (A -> B)
!   CM at midpoint: (0, 50, 0)
! ============================================================

part create rigid_body name_and_position &
   part_name   = .four_bar.crank &
   location    = 0.0, 50.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
   part_name = .four_bar.crank &
   mass      = 0.5 &
   ixx       = 416.667 &
   iyy       = 0.0 &
   izz       = 416.667 &
   ixy       = 0.0 &
   iyz       = 0.0 &
   izx       = 0.0

! Marker at A (crank–ground revolute joint)
marker create &
   marker_name  = .four_bar.crank.CRANK_A &
   location     = 0.0, 0.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! Marker at B (crank–coupler revolute joint)
marker create &
   marker_name  = .four_bar.crank.CRANK_B &
   location     = 0.0, 100.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! ============================================================
! COUPLER  (B -> C)
!   CM at midpoint: (116.867, 144.351, 0)
! ============================================================

part create rigid_body name_and_position &
   part_name   = .four_bar.coupler &
   location    = 116.867, 144.351, 0.0 &
   orientation = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
   part_name = .four_bar.coupler &
   mass      = 0.5 &
   ixx       = 2604.167 &
   iyy       = 0.0 &
   izz       = 2604.167 &
   ixy       = 0.0 &
   iyz       = 0.0 &
   izx       = 0.0

! Marker at B (coupler–crank revolute joint)
marker create &
   marker_name  = .four_bar.coupler.COUPLER_B &
   location     = 0.0, 100.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! Marker at C (coupler–rocker revolute joint)
marker create &
   marker_name  = .four_bar.coupler.COUPLER_C &
   location     = 233.734, 188.702, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! ============================================================
! ROCKER  (D -> C)
!   CM at midpoint: (266.867, 94.351, 0)
! ============================================================

part create rigid_body name_and_position &
   part_name   = .four_bar.rocker &
   location    = 266.867, 94.351, 0.0 &
   orientation = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
   part_name = .four_bar.rocker &
   mass      = 0.5 &
   ixx       = 1666.667 &
   iyy       = 0.0 &
   izz       = 1666.667 &
   ixy       = 0.0 &
   iyz       = 0.0 &
   izx       = 0.0

! Marker at D (rocker–ground revolute joint)
marker create &
   marker_name  = .four_bar.rocker.ROCKER_D &
   location     = 300.0, 0.0, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! Marker at C (rocker–coupler revolute joint)
marker create &
   marker_name  = .four_bar.rocker.ROCKER_C &
   location     = 233.734, 188.702, 0.0 &
   orientation  = 0.0, 0.0, 0.0

! ============================================================
! Revolute Joints
!   Each revolute joint removes 5 DOF, leaving rotation about Z.
! ============================================================

! J_A: Crank pinned to ground at A
constraint create joint revolute &
   joint_name      = .four_bar.JNT_A &
   i_marker_name   = .four_bar.crank.CRANK_A &
   j_marker_name   = .four_bar.ground.GRND_A

! J_B: Coupler pinned to crank at B
constraint create joint revolute &
   joint_name      = .four_bar.JNT_B &
   i_marker_name   = .four_bar.coupler.COUPLER_B &
   j_marker_name   = .four_bar.crank.CRANK_B

! J_C: Rocker pinned to coupler at C
constraint create joint revolute &
   joint_name      = .four_bar.JNT_C &
   i_marker_name   = .four_bar.rocker.ROCKER_C &
   j_marker_name   = .four_bar.coupler.COUPLER_C

! J_D: Rocker pinned to ground at D
constraint create joint revolute &
   joint_name      = .four_bar.JNT_D &
   i_marker_name   = .four_bar.rocker.ROCKER_D &
   j_marker_name   = .four_bar.ground.GRND_D

! ============================================================
! Crank Driver — constant 360 deg/s
!
!   function specifies angular displacement (radians) vs time.
!   "360.0D" uses Adams degree-to-radian conversion: 360 * pi/180 = 2*pi
!   displacement(t) = 2*pi * t  rad
!   velocity        = 2*pi rad/s = 360 deg/s  (one revolution per second)
! ============================================================

motion create joint_motion &
   joint_motion_name = .four_bar.MOTION_CRANK &
   joint_name        = .four_bar.JNT_A &
   type_of_freedom   = rotational &
   function          = "360.0D * time"

! ============================================================
! Simulation — 2 s total, 0.001 s output step (2000 steps)
! ============================================================

simulation single_run transient &
   sim_name       = .four_bar.Last_Run &
   time_duration  = 2.0 &
   number_of_steps = 2000 &
   initial_static = no
