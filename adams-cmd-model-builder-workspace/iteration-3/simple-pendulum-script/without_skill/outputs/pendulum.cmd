! ==============================================================
! Adams/View CMD Script: Simple Pendulum
! ==============================================================
!
! A single rigid link pinned to ground at its top end.
! Released from rest at 45 degrees from vertical.
!
! Specifications:
!   Link length   : 200 mm
!   Link mass     : 1 kg
!   Gravity       : -Y direction, 9806.65 mm/s^2
!   Joint type    : Revolute (pin joint at top of link)
!   Release angle : 45 degrees from vertical (no initial velocity)
!
! Derived quantities (uniform slender rod):
!   CM location   : midpoint, 100 mm below pivot
!   Izz (about CM): m * L^2 / 12 = 1 * (200^2) / 12 = 3333.33 kg*mm^2
!
!   Initial CM global position (45 deg from downward vertical):
!       X =  100 * sin(45 deg) =  70.711 mm
!       Y = -100 * cos(45 deg) = -70.711 mm
!
! ==============================================================

! --- Create model ---
model create &
   model_name = pendulum

! --- Default units: mm, kg, N, s ---
defaults units &
   length = mm &
   mass   = kg &
   time   = sec &
   force  = newton

! --- Gravity: -Y direction ---
environment set gravity &
   gravity_x = 0.0 &
   gravity_y = -9806.65 &
   gravity_z = 0.0

! ==============================================================
! Ground Markers
! ==============================================================

! Pivot point on ground at world origin
marker create &
   marker_name = .pendulum.ground.pivot_ground &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ==============================================================
! Pendulum Link (Part 2)
! ==============================================================

! Create the rigid part; locate reference frame at initial CM position
! Part is initially rotated 45 degrees about Z-axis (from -Y towards +X)
part create rigid_body name_and_position &
   part_name   = .pendulum.link &
   adams_id    = 2 &
   location    = 70.711, -70.711, 0.0 &
   orientation = 0.0, 0.0, 45.0

! Set mass properties (uniform slender rod)
!   Ixx = 0 (along rod axis - negligible for slender rod)
!   Iyy = m*L^2/12 (bending perpendicular to rod, in XY plane)
!   Izz = m*L^2/12 (bending perpendicular to rod, in XZ plane)
part create rigid_body mass_properties &
   part_name = .pendulum.link &
   mass      = 1.0 &
   ixx       = 0.0 &
   iyy       = 3333.33 &
   izz       = 3333.33 &
   ixy       = 0.0 &
   ixz       = 0.0 &
   iyz       = 0.0

! --- Markers on pendulum link ---

! CM marker: at part reference origin (initial CM global coords)
marker create &
   marker_name = .pendulum.link.cm_marker &
   location    = 70.711, -70.711, 0.0

! Top-of-link (pivot) marker: 100 mm above CM in body frame
! At 45 deg the pivot is back at the world origin (0, 0, 0)
marker create &
   marker_name = .pendulum.link.pivot_link &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 45.0

! Bottom-of-link marker: 100 mm below CM in body frame (for geometry/reference)
marker create &
   marker_name = .pendulum.link.bottom &
   location    = 141.421, -141.421, 0.0 &
   orientation = 0.0, 0.0, 45.0

! ==============================================================
! Revolute Joint: top of pendulum to ground
! Rotation axis = Z-axis (out of plane)
! ==============================================================

constraint create joint revolute &
   joint_name    = .pendulum.pin_joint &
   i_marker_name = .pendulum.link.pivot_link &
   j_marker_name = .pendulum.ground.pivot_ground

! ==============================================================
! Visual Geometry (cylinder representing the link)
! ==============================================================

geometry create shape cylinder &
   cylinder_name   = .pendulum.link.rod_geometry &
   center_marker   = .pendulum.link.cm_marker &
   angle_extent    = 360.0 &
   length          = 200.0 &
   radius          = 5.0 &
   side_count_for_perimeter = 12

! ==============================================================
! Simulation: 5 seconds, 10 ms steps
! ==============================================================

simulation single_run &
   sim_script_name = .pendulum.DefaultSimulationScript &
   initial_static  = no &
   type            = dynamic &
   duration        = 5.0 &
   number_of_steps = 500
