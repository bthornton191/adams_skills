!-----------------------------------------------------------------
! Simple Pendulum - Adams/View CMD Script
!
! Description:
!   Single rigid link pendulum, 200 mm length, 1 kg mass.
!   Pinned at top end to ground by a revolute joint.
!   Gravity acts in -Y direction (g = 9806.65 mm/s^2).
!   Released from rest at 45 degrees from vertical.
!
! Coordinate system:
!   Y-axis: vertical (up)
!   Gravity: -Y direction
!   Pendulum swings in the XY plane, rotating about the Z-axis
!
! Initial configuration (45 deg from vertical, displaced toward +X):
!   Pivot location (world):  (0, 0, 0) mm
!   Link direction vector:   (sin45, -cos45, 0) = (0.7071, -0.7071, 0)
!   CM location (world):     (70.711, -70.711, 0) mm
!   Tip location (world):    (141.421, -141.421, 0) mm
!
! Mass properties (uniform thin rod, axis along local X):
!   Mass:  1 kg
!   I_yy = I_zz = m * L^2 / 12 = 1 * 200^2 / 12 = 3333.33 kg*mm^2
!   I_xx  ~ 0 (along rod axis)
!-----------------------------------------------------------------

model create &
   model_name = PENDULUM

!-----------------------------------------------------------------
! Units
!-----------------------------------------------------------------
defaults units &
   length = mm &
   mass = kg &
   force = newton &
   time = sec

!-----------------------------------------------------------------
! Gravity: -Y direction
! Standard gravity = 9.80665 m/s^2 = 9806.65 mm/s^2
!-----------------------------------------------------------------
force create body gravitational &
   gravity_field_name = .PENDULUM.gravity &
   x_component_gravity = 0.0 &
   y_component_gravity = -9806.65 &
   z_component_gravity = 0.0

!-----------------------------------------------------------------
! PENDULUM LINK - Rigid body
!
! The part frame origin is placed at the initial CM position in
! world coordinates: (70.711, -70.711, 0) mm.
!
! The part frame is rotated -45 degrees about the world Z-axis so
! that the local X-axis aligns with the link direction:
!   R_z(-45) * [1,0,0] = (cos(-45), sin(-45), 0) = (0.7071, -0.7071, 0)
!
! With this orientation, a marker at local position (-100, 0, 0)
! maps to world position (0, 0, 0) -- the pivot point.
!   World = CM_world + R_z(-45)*[-100,0,0]
!         = (70.711,-70.711,0) + (-70.711, 70.711, 0) = (0, 0, 0)  [check]
!-----------------------------------------------------------------
part create rigid_body name_and_position &
   part_name = .PENDULUM.LINK &
   adams_id = 2 &
   location = 70.711, -70.711, 0.0 &
   orientation = -45.0, 0.0, 0.0

!--- Mass properties ---
! Uniform thin rod of length L = 200 mm, mass m = 1 kg
!   I_xx (along rod)         ~  1.0    kg*mm^2  (small, rod axis)
!   I_yy (perpendicular)     = 3333.33 kg*mm^2  (= m*L^2/12)
!   I_zz (perpendicular)     = 3333.33 kg*mm^2  (= m*L^2/12)
! The pendulum rotates about world Z; with local Z = world Z at t=0,
! I_zz = 3333.33 kg*mm^2 is the governing planar inertia.
part create rigid_body mass_properties &
   part_name = .PENDULUM.LINK &
   mass = 1.0 &
   ixx = 1.0 &
   iyy = 3333.33 &
   izz = 3333.33 &
   ixy = 0.0 &
   izx = 0.0 &
   iyz = 0.0

!--- Geometry: rectangular box representing the link ---
! Dimensions: 200 mm (local X) x 10 mm (local Y) x 10 mm (local Z)
! Centered at the CM (part origin)
geometry create shape box &
   box_name = .PENDULUM.LINK.LINK_BOX &
   center_marker = .PENDULUM.LINK.cm &
   x_side_length = 200.0 &
   y_side_length = 10.0 &
   z_side_length = 10.0

!-----------------------------------------------------------------
! MARKERS for the revolute joint
!-----------------------------------------------------------------

! Ground pivot marker: at world origin, axes aligned with world frame.
! Z-axis = world Z = rotation axis of the joint.
marker create &
   marker_name = .PENDULUM.ground.GRND_PIVOT &
   adams_id = 1 &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! Link pivot marker: at the top (pivot) end of the link.
! In the part's local frame, the pivot end is 100 mm behind the CM
! along the local X-axis, i.e., at local position (-100, 0, 0).
! At the initial configuration this resolves to world (0, 0, 0).
! Orientation (0,0,0) in local frame => local Z = part local Z = world Z,
! which matches GRND_PIVOT's Z-axis for consistency with the joint.
marker create &
   marker_name = .PENDULUM.LINK.LINK_PIVOT &
   adams_id = 3 &
   location = -100.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

!-----------------------------------------------------------------
! REVOLUTE JOINT
!
! Joins the link to ground at the pivot point (world origin).
! The joint Z-axis (shared Z of both markers) defines the rotation axis.
! Removes 5 DOFs (3 translations + 2 rotations), leaving 1 rotational DOF.
! The link is free to rotate about the world Z-axis.
!-----------------------------------------------------------------
constraint create joint revolute &
   joint_name = .PENDULUM.REV_JOINT &
   adams_id = 1 &
   i_marker_name = .PENDULUM.LINK.LINK_PIVOT &
   j_marker_name = .PENDULUM.ground.GRND_PIVOT

!-----------------------------------------------------------------
! SIMULATION SETTINGS
! Duration: 5 seconds, 500 output steps (dt = 0.01 s)
! No initial static equilibrium (model starts from specified IC)
!-----------------------------------------------------------------
simulation single_run transient &
   sim_name = .PENDULUM.sim1 &
   initial_static = no &
   end_time = 5.0 &
   number_of_steps = 500

!-----------------------------------------------------------------
! END OF PENDULUM MODEL
!-----------------------------------------------------------------
