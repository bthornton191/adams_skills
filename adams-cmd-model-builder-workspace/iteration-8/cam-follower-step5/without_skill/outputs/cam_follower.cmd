! ============================================================
! Cam-Follower Mechanism — Adams CMD Script
!
! Cam:      1.0 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground at origin
! Follower: 0.5 kg, Ixx=Iyy=50 kg·mm², Izz=10 kg·mm²
!           constrained to translate along global X axis only
!
! Push force (single-component, +X direction):
!   STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0)
!     Smooth quintic ramp: 0 N at DX=0 mm to 500 N at DX=20 mm, holds 500 N beyond
!   + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
!     Velocity-dependent damping coefficient 2.0 N·s/mm
!
! Geometry:
!   Cam:      cylinder, r=40 mm, l=30 mm (centred at origin)
!   Follower: cylinder, r=10 mm, l=60 mm (rod extending in +X)
!
! Simulation: 1 second, 1000 output steps
!
! Orientation convention (ZXZ Body-313 Euler angles):
!   (psi=90D, theta=90D, phi=0D) aligns local z-axis with global +X.
!   Required for translational joint markers (sliding is along local z-axis).
! ============================================================

! --- 1. Create model ---
model create model_name = model

! --- 2. Set units (mm, kg, newton, second) ---
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 3. Gravity (-Y direction, mm-kg-s: 9806.65 mm/s²) ---
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
! orientation = (90D, 90D, 0D): ZXZ Euler gives local z-axis -> global +X.
! Translational joint slides along the local z-axis of these markers.
marker create &
    marker_name = .model.ground.trans_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! J-marker for single_component_force direction.
! Placed 1000 mm in the global +X direction so the I->J unit vector
! always equals (1, 0, 0) while the follower translates along X.
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

! Center-of-mass marker (must exist before setting mass properties)
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
    ixy                   = 0.0 &
    izx                   = 0.0 &
    iyz                   = 0.0 &
    center_of_mass_marker = .model.cam.cm

! Reference marker — DX/VX measurement origin for the force expression,
! and I-marker for the fixed joint. Coincident with cam origin.
marker create &
    marker_name = .model.cam.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry marker — cylinder starts at z=-15 mm so the 30 mm disk
! is centred on the cam origin (spans z=-15 to z=+15).
marker create &
    marker_name = .model.cam.geom_mkr &
    location    = 0.0, 0.0, -15.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! FOLLOWER PART  —  0.5 kg, Ixx=Iyy=50, Izz=10 kg·mm²
! ============================================================

part create rigid_body name_and_position &
    part_name   = .model.follower &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Center-of-mass marker (must exist before setting mass properties)
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
    ixy                   = 0.0 &
    izx                   = 0.0 &
    iyz                   = 0.0 &
    center_of_mass_marker = .model.follower.cm

! Tip marker — force application point and DX/VX measurement marker.
! Coincident with cam.ref_mkr at t=0 so DX starts at 0 mm.
marker create &
    marker_name = .model.follower.tip_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Translational joint I-marker.
! orientation = (90D, 90D, 0D): local z-axis -> global +X.
marker create &
    marker_name = .model.follower.trans_i_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Geometry marker for follower cylinder rod (z-axis -> +X).
marker create &
    marker_name = .model.follower.geom_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! ============================================================
! GEOMETRY
! ============================================================

! Cam: cylinder disk, r=40 mm, l=30 mm (centred at origin via geom_mkr at z=-15)
geometry create shape cylinder &
    cylinder_name = .model.cam.cam_cyl &
    center_marker = .model.cam.geom_mkr &
    length        = 30.0 &
    radius        = 40.0 &
    angle_extent  = 360.0D

! Follower: cylinder rod, r=10 mm, l=60 mm, extends in +X from follower origin
geometry create shape cylinder &
    cylinder_name = .model.follower.follower_cyl &
    center_marker = .model.follower.geom_mkr &
    length        = 60.0 &
    radius        = 10.0 &
    angle_extent  = 360.0D

! ============================================================
! CONSTRAINTS
! ============================================================

! Fixed joint: cam welded to ground (removes all 6 DOF)
constraint create joint fixed &
    joint_name    = .model.cam_ground_fix &
    i_marker_name = .model.cam.ref_mkr &
    j_marker_name = .model.ground.origin_mkr

! Translational joint: follower slides along global X (5 DOF removed)
constraint create joint translational &
    joint_name    = .model.follower_trans &
    i_marker_name = .model.follower.trans_i_mkr &
    j_marker_name = .model.ground.trans_j_mkr

! ============================================================
! FORCES
! ============================================================

! Single-component force pushing follower in +X direction.
! The I->J unit vector (tip_mkr -> force_j_mkr) is always (1,0,0)
! because the follower is constrained to X-only motion and
! force_j_mkr is fixed at (1000, 0, 0).
!
! Force function:
!   STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0)
!       Quintic ramp: 0 N at DX=0 mm -> 500 N at DX=20 mm -> 500 N beyond 20 mm
!   + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
!       Velocity-dependent damping, coefficient = 2.0 N·s/mm
force create direct single_component_force &
    single_component_force_name = .model.cam_push_force &
    i_marker_name               = .model.follower.tip_mkr &
    j_marker_name               = .model.ground.force_j_mkr &
    action_only                 = off &
    function                    = "STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0) + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)"

! ============================================================
! SIMULATION
! ============================================================

simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 1000 &
    model_name      = .model &
    initial_static  = no

! ============================================================
! End of cam_follower.cmd
! ============================================================
