! ============================================================
! Adams/View CMD Script: Cam-Follower Mechanism
! ============================================================
!
! Cam:      1.0 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground at origin
! Follower: 0.5 kg, Ixx=Iyy=50 kg·mm², Izz=10 kg·mm²
!           constrained to translate along global X axis
!
! Push force: STEP5(DX, 0, 0, 20, 500) - 2.0*VX  [N]
!   - Ramps smoothly 0→500 N as DX goes 0→20 mm, saturates at 500 N
!   - Damping: 2.0 N·s/mm × translational velocity in X
!
! Geometry: Cylinder on cam (r=30 mm, l=20 mm)
!           Box on follower (40 mm × 20 mm × 20 mm)
!
! Simulation: 1 second, 1000 output steps
!
! NOTE: STEP5(DX=0,...) evaluates to 0 N, so the follower requires
!       a small initial velocity or displacement to kick-start motion.
!       Give .model.follower an initial X-velocity of ~1 mm/s before
!       running, or change the force to include a time-based ramp.
! ============================================================

model create &
   model_name = .model

defaults units &
   length = mm &
   mass   = kg &
   force  = newton &
   time   = second

! ============================================================
! CAM PART  –  1 kg, fixed to ground at origin
! ============================================================

part create rigid_body name_and_position &
   part_name   = .model.cam &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Center-of-mass marker
marker create &
   marker_name = .model.cam.cm &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Reference marker used in force/displacement expressions
marker create &
   marker_name = .model.cam.ref_mkr &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! I-marker for fixed joint to ground
marker create &
   marker_name = .model.cam.jfixed_I &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties &
   part_name             = .model.cam &
   mass                  = 1.0 &
   center_of_mass_marker = .model.cam.cm &
   ixx                   = 100.0 &
   iyy                   = 100.0 &
   izz                   = 100.0 &
   ixy                   = 0.0 &
   izx                   = 0.0 &
   iyz                   = 0.0

! ============================================================
! FOLLOWER PART  –  0.5 kg, translates along global X
! ============================================================

part create rigid_body name_and_position &
   part_name   = .model.follower &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Center-of-mass marker
marker create &
   marker_name = .model.follower.cm &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Tip marker – origin reference for DX / VX expressions
marker create &
   marker_name = .model.follower.tip_mkr &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Translational-joint I-marker: local Z axis aligned with global X
! ZXZ Euler angles (psi=90°, theta=90°, phi=0°) achieve this alignment:
!   R = Rz(90°)*Rx(90°)  →  col-3 (local Z) = [1,0,0] = global X  ✓
marker create &
   marker_name = .model.follower.jtrans_I &
   location    = 0.0, 0.0, 0.0 &
   orientation = 90.0d, 90.0d, 0.0d

! Force application marker – same orientation so force acts in global +X
marker create &
   marker_name = .model.follower.force_mkr &
   location    = 0.0, 0.0, 0.0 &
   orientation = 90.0d, 90.0d, 0.0d

part modify rigid_body mass_properties &
   part_name             = .model.follower &
   mass                  = 0.5 &
   center_of_mass_marker = .model.follower.cm &
   ixx                   = 50.0 &
   iyy                   = 50.0 &
   izz                   = 10.0 &
   ixy                   = 0.0 &
   izx                   = 0.0 &
   iyz                   = 0.0

! ============================================================
! GROUND MARKERS
! ============================================================

! J-marker for cam fixed joint
marker create &
   marker_name = .model.ground.jfixed_J &
   location    = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! J-marker for follower translational joint (same orientation as I-marker)
marker create &
   marker_name = .model.ground.jtrans_J &
   location    = 0.0, 0.0, 0.0 &
   orientation = 90.0d, 90.0d, 0.0d

! ============================================================
! CONSTRAINTS
! ============================================================

! Cam is welded to ground  (removes all 6 DOF)
constraint create joint fixed &
   joint_name    = .model.jt_cam_fixed &
   i_marker_name = .model.cam.jfixed_I &
   j_marker_name = .model.ground.jfixed_J

! Follower is constrained to translate only along global X (5 DOF removed)
constraint create joint translational &
   joint_name    = .model.jt_follower_trans &
   i_marker_name = .model.follower.jtrans_I &
   j_marker_name = .model.ground.jtrans_J

! ============================================================
! FORCES
! ============================================================

! Single-component translational force acting along local Z of force_mkr,
! which equals global X (see orientation comments above).
!
! Force expression:
!   STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0)
!       Smooth 5th-order step: 0 N at DX=0 mm → 500 N at DX=20 mm → 500 N beyond
!   - 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
!       Viscous damping coefficient 2.0 N·s/mm opposing +X motion
!
! action_only = on: reaction is absorbed by ground through cam (cam is fixed)

force create direct single_component_force &
   single_component_force_name = .model.push_force &
   type_of_freedom             = translational &
   i_marker_name               = .model.follower.force_mkr &
   j_marker_name               = .model.cam.ref_mkr &
   action_only                 = on &
   function = "STEP5(DX(.model.follower.tip_mkr,.model.cam.ref_mkr),0.0,0.0,20.0,500.0) - 2.0*VX(.model.follower.tip_mkr,.model.cam.ref_mkr)"

! ============================================================
! GEOMETRY
! ============================================================

! Cam: cylinder, axis along local Z (= global Z for default orientation)
!      radius = 30 mm, length = 20 mm
geometry create shape cylinder &
   cylinder_name           = .model.cam.geom_cyl &
   center_marker           = .model.cam.cm &
   angle_extent            = 360.0 &
   length                  = 20.0 &
   radius                  = 30.0 &
   side_count_for_graphics = 20

! Follower: box 40 mm (X) × 20 mm (Y) × 20 mm (Z)
!           corner_marker defines the minimum-corner vertex in local frame
geometry create shape box &
   box_name      = .model.follower.geom_box &
   corner_marker = .model.follower.cm &
   x_length      = 40.0 &
   y_length      = 20.0 &
   z_length      = 20.0

! ============================================================
! SIMULATION
! ============================================================

simulation single &
   model_name      = .model &
   end_time        = 1.0 &
   number_of_steps = 1000 &
   initial_static  = no
