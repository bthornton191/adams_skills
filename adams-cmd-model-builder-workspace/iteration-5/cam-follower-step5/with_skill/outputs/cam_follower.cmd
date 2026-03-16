! ============================================================
! Cam-Follower Mechanism — Adams CMD Script
!
! A cam body fixed to ground at the origin, and a follower
! (0.5 kg rigid body) constrained to translate along the
! global X axis via a translational joint. A single-component
! force using STEP5 pushes the follower in +X, ramping from
! 0 N to 500 N as DX goes from 0 mm to 20 mm, then holding
! at 500 N. Velocity-dependent damping of 2.0 x VX is included.
! Simple geometry is added to both parts. Simulates 1 second.
!
! Orientation note:
!   Marker orientation (psi=90D, theta=90D, phi=0D) aligns
!   the local z-axis with the global +X axis (ZXZ Body-313
!   Euler angles). Used for translational joint markers and
!   follower cylinder geometry.
!
! Model hierarchy:
!   .model
!   ├── ground
!   │   ├── origin_mkr     (cam fixed joint J reference)
!   │   ├── trans_j_mkr    (translational joint J marker, z→+X global)
!   │   └── force_j_mkr    (force direction marker 1000 mm in +X)
!   ├── cam  (1 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground)
!   │   ├── cm             (auto-created by Adams on mass_properties)
!   │   ├── ref_mkr        (DX/VX reference; fixed joint I marker)
!   │   └── geom_mkr       (cylinder geometry start, at z=-15)
!   └── follower  (0.5 kg, Ixx=Iyy=50, Izz=10 kg·mm²)
!       ├── cm             (auto-created by Adams on mass_properties)
!       ├── tip_mkr        (force application point; DX/VX measurement)
!       ├── trans_i_mkr    (translational joint I marker, z→+X global)
!       └── geom_mkr       (cylinder geometry start, z→+X global)
! ============================================================

! --- 1. Create model ---
model create model_name = model

! --- 2. Set units (mm, newton, kg, second) ---
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 3. Gravity (-Y direction, mm-kg-s units) ---
force create body gravitational &
    gravity_field_name  = .model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 4. Ground markers ---

! J marker for the cam fixed joint (coincident with global origin)
marker create &
    marker_name = .model.ground.origin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! J marker for the translational joint.
! orientation = (90D, 90D, 0D): ZXZ Euler gives local z-axis → global +X.
! The translational joint allows sliding along the z-axis of this marker.
marker create &
    marker_name = .model.ground.trans_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! J marker for single_component_force direction.
! Placed 1000 mm in the global +X direction so the I→J unit vector
! is always (1,0,0) while the follower translates along X.
marker create &
    marker_name = .model.ground.force_j_mkr &
    location    = 1000.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Create cam part (1 kg, Ixx=Iyy=Izz=100 kg·mm²) ---
part create rigid_body name_and_position &
    part_name   = .model.cam &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! CM marker must be created before setting mass properties.
marker create &
    marker_name = .model.cam.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .model.cam &
    mass                  = 1.0 &
    ixx                   = 100.0 &
    iyy                   = 100.0 &
    izz                   = 100.0 &
    center_of_mass_marker = .model.cam.cm

! Cam reference marker — DX/VX origin for the force expression
! and I marker for the fixed joint. Coincident with cam part origin.
marker create &
    marker_name = .model.cam.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cam geometry marker — start of the cylinder (offset -15 mm in Z
! so the 30 mm cylinder is centred around the cam origin).
marker create &
    marker_name = .model.cam.geom_mkr &
    location    = 0.0, 0.0, -15.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Create follower part (0.5 kg, Ixx=Iyy=50, Izz=10 kg·mm²) ---
! Positioned at the origin so tip_mkr starts at the same X location
! as cam.ref_mkr, giving DX = 0 at t = 0.
part create rigid_body name_and_position &
    part_name   = .model.follower &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! CM marker must be created before setting mass properties.
marker create &
    marker_name = .model.follower.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .model.follower &
    mass                  = 0.5 &
    ixx                   = 50.0 &
    iyy                   = 50.0 &
    izz                   = 10.0 &
    center_of_mass_marker = .model.follower.cm

! Follower tip marker — force application point and DX/VX measurement.
! Global position (0,0,0) at t=0, coincident with cam.ref_mkr.
marker create &
    marker_name = .model.follower.tip_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Follower translational joint I marker.
! orientation = (90D, 90D, 0D): local z-axis → global +X.
! Must match the z-axis direction of the J marker (trans_j_mkr).
marker create &
    marker_name = .model.follower.trans_i_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Follower geometry marker — cylinder start, z-axis → +X global.
! The cylinder (rod shape) extends from (0,0,0) toward +X for 60 mm.
marker create &
    marker_name = .model.follower.geom_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! --- 7. Cam geometry ---
! Cylinder disk: 30 mm thick along Z, 40 mm radius. Represents the cam lobe.
! center_marker at geom_mkr (z = -15) so the disk spans z = -15 to +15.
geometry create shape cylinder &
    cylinder_name = .model.cam.cam_cyl &
    center_marker = .model.cam.geom_mkr &
    length        = 30.0 &
    radius        = 40.0 &
    angle_extent  = 360.0D

! --- 8. Follower geometry ---
! Cylinder rod: 60 mm long, 10 mm radius, extending in global +X.
! center_marker has z → +X (orientation 90D,90D,0D), so cylinder
! extends along +X from the follower position.
geometry create shape cylinder &
    cylinder_name = .model.follower.follower_cyl &
    center_marker = .model.follower.geom_mkr &
    length        = 60.0 &
    radius        = 10.0 &
    angle_extent  = 360.0D

! --- 9. Fixed joint: cam locked to ground ---
constraint create joint fixed &
    joint_name    = .model.cam_ground_fix &
    i_marker_name = .model.cam.ref_mkr &
    j_marker_name = .model.ground.origin_mkr

! --- 10. Translational joint: follower slides along global X ---
! Both I and J markers have their z-axes aligned with global +X.
! This removes all DOF except translation along X.
constraint create joint translational &
    joint_name    = .model.follower_trans &
    i_marker_name = .model.follower.trans_i_mkr &
    j_marker_name = .model.ground.trans_j_mkr

! --- 11. Cam-follower driving force ---
! Single-component force from follower.tip_mkr toward ground.force_j_mkr.
! Direction: the I→J unit vector is always (1,0,0) because the follower
! is constrained to X motion (y=z=0) and force_j_mkr is at (1000,0,0).
!
! FUNCTION breakdown:
!   STEP5(DX(...), 0.0, 0.0, 20.0, 500.0)
!     — quintic ramp: 0 N at DX=0 mm, 500 N at DX=20 mm, holds 500 N beyond
!   + 2.0 * VX(...)
!     — velocity-dependent term with coefficient 2.0 (N·s/mm)
force create direct single_component_force &
    single_component_force_name = .model.cam_push_force &
    i_marker_name               = .model.follower.tip_mkr &
    j_marker_name               = .model.ground.force_j_mkr &
    action_only                 = off &
    function                    = "STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0) + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)"

! --- 12. Transient simulation: 1 second, 1000 output steps ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 1000 &
    model_name      = .model &
    initial_static  = no

! ============================================================
! End of cam_follower.cmd
! ============================================================
