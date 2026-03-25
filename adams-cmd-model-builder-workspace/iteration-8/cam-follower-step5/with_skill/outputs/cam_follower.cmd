! ============================================================
! Cam-Follower Mechanism — Adams CMD Script
!
! Cam:      1.0 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground at origin
! Follower: 0.5 kg, Ixx=Iyy=50 kg·mm², Izz=10 kg·mm²
!           constrained to translate along global X axis only
!
! Push force (single-component force, +X direction):
!   STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0)
!     Quintic ramp: 0 N at DX=0 mm → 500 N at DX=20 mm, holds 500 N beyond
!   - 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
!     Velocity-dependent damping: opposes motion in +X
!
! Geometry:
!   Cam:      cylinder disc, r=40 mm, l=30 mm (centred at origin)
!   Follower: cylinder rod, r=10 mm, l=60 mm (extends in +X)
!
! Simulation: 1 second, 1000 output steps
!
! Orientation convention (ZXZ Body-313 Euler angles):
!   (psi=90D, theta=90D, phi=0D) aligns local z-axis with global +X.
!   Required for translational joint markers (joint slides along local z).
!
! Model hierarchy:
!   .model
!   ├── ground
!   │   ├── origin_mkr      (cam fixed joint J marker)
!   │   ├── trans_j_mkr     (translational joint J marker, z→global +X)
!   │   └── force_j_mkr     (SFORCE J marker, placed 1000 mm in +X)
!   ├── cam  (1 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground)
!   │   ├── cm              (CM marker at part origin for mass properties)
!   │   ├── ref_mkr         (DX/VX reference; also used as fixed joint I)
!   │   └── geom_mkr        (cylinder start, at z=-15 so disc spans ±15 mm)
!   └── follower  (0.5 kg, Ixx=Iyy=50, Izz=10 kg·mm²)
!       ├── cm              (CM marker at part origin for mass properties)
!       ├── tip_mkr         (force I-marker; DX/VX measurement)
!       ├── trans_i_mkr     (translational joint I marker, z→global +X)
!       └── geom_mkr        (cylinder start, z→global +X, rod extends in +X)
! ============================================================

! --- 1. Model and units ---
model create model_name = model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (-Y direction, mm-kg-s: 9806.65 mm/s²) ---
force create body gravitational &
    gravity_field_name  = .model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! GROUND MARKERS
! ============================================================

! J-marker for cam fixed joint (at global origin)
marker create &
    marker_name = .model.ground.origin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! J-marker for follower translational joint.
! orientation = (90D, 90D, 0D): ZXZ Euler gives local z-axis → global +X.
! Translational joint permits sliding along the local z-axis of this marker.
marker create &
    marker_name = .model.ground.trans_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! J-marker for single_component_force direction.
! Placed 1000 mm along global +X so the I→J unit vector is always (1,0,0)
! while the follower translates (follower constrained to X motion only).
marker create &
    marker_name = .model.ground.force_j_mkr &
    location    = 1000.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! CAM PART  —  1 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground
! ============================================================

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

! Reference marker — DX/VX origin for the force expression;
! also used as the I-marker for the cam fixed joint.
marker create &
    marker_name = .model.cam.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry marker — cylinder one end at z=-15 mm so the 30 mm disc
! is centred on the cam origin (spans z = -15 to z = +15 mm).
marker create &
    marker_name = .model.cam.geom_mkr &
    location    = 0.0, 0.0, -15.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cam body: short wide cylinder (disc in XY plane)
geometry create shape cylinder &
    cylinder_name = .model.cam.cam_cyl &
    center_marker = .model.cam.geom_mkr &
    angle_extent  = 360.0D &
    length        = 30.0 &
    radius        = 40.0

! ============================================================
! FOLLOWER PART  —  0.5 kg, Ixx=Iyy=50, Izz=10 kg·mm²
! Constrained to translate along global X via translational joint
! ============================================================

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

! Tip marker — force application point and DX/VX measurement.
! Starts coincident with cam.ref_mkr so DX = 0 at t = 0.
marker create &
    marker_name = .model.follower.tip_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Translational joint I-marker.
! orientation = (90D, 90D, 0D): local z-axis → global +X.
marker create &
    marker_name = .model.follower.trans_i_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Geometry marker for follower cylinder rod (z-axis → global +X).
! Cylinder extends from the follower origin 60 mm in the +X direction.
marker create &
    marker_name = .model.follower.geom_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Follower body: long thin cylinder along X axis
geometry create shape cylinder &
    cylinder_name = .model.follower.follower_cyl &
    center_marker = .model.follower.geom_mkr &
    angle_extent  = 360.0D &
    length        = 60.0 &
    radius        = 10.0

! ============================================================
! CONSTRAINTS
! ============================================================

! Fixed joint: cam rigidly attached to ground at origin (all 6 DOF removed)
constraint create joint fixed &
    joint_name    = .model.cam_ground_fix &
    i_marker_name = .model.cam.ref_mkr &
    j_marker_name = .model.ground.origin_mkr

! Translational joint: follower slides along global X axis only (1 DOF)
constraint create joint translational &
    joint_name    = .model.follower_trans &
    i_marker_name = .model.follower.trans_i_mkr &
    j_marker_name = .model.ground.trans_j_mkr

! ============================================================
! FORCES
! ============================================================

! Single-component force pushing follower in +X direction.
! I-marker (tip_mkr) is on the follower; J-marker (force_j_mkr) is on the
! ground at (1000,0,0). Because the follower can only move in X (y=z=0),
! the I→J unit vector is always exactly (1,0,0).
!
! Force function:
!   STEP5(DX, 0, 0, 20, 500):  quintic ramp 0→500 N as DX goes 0→20 mm
!   - 2.0 * VX:                velocity-dependent damping (opposes +X motion)
force create direct single_component_force &
    single_component_force_name = .model.cam_force &
    i_marker_name               = .model.follower.tip_mkr &
    j_marker_name               = .model.ground.force_j_mkr &
    action_only                 = off &
    function                    = "STEP5(DX(.model.follower.tip_mkr,.model.cam.ref_mkr),0.0,0.0,20.0,500.0)", &
                                  " - 2.0*VX(.model.follower.tip_mkr,.model.cam.ref_mkr)"

! ============================================================
! Simulation: 1 second transient run, 1000 output steps
! ============================================================

simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 1000 &
    model_name      = .model &
    initial_static  = no
