! ============================================================
! Rubber Mount Model — Chassis to Subframe
! Nonlinear X-direction stiffness via spline + AKISPL GFORCE
! Linear Y/Z translational stiffness (5000 N/mm) via GFORCE
! Uniform rotational stiffness (200 N·mm/deg) via GFORCE
! ============================================================

! ============================================================
! 1. Model and units
! ============================================================
model create &
    model_name = .rubber_mount

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! ============================================================
! 2. Gravity (Y-down, mm-kg-s)
! ============================================================
force create body gravitational &
    gravity_field_name  = .rubber_mount.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! 3. Spline: Nonlinear X-direction force-displacement table
!    x = relative X displacement of subframe w.r.t. chassis (mm)
!    y = spring force (N) — same sign as displacement
!    The GFORCE applies -(spline value) as restoring force on subframe.
! ============================================================
data_element create spline &
    spline_name = .rubber_mount.x_force_spline &
    x = -10.0, -5.0, 0.0, 5.0, 10.0 &
    y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0

! ============================================================
! 4. Ground reference marker (global origin)
! ============================================================
marker create &
    marker_name = .rubber_mount.ground.global_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! 5. CHASSIS — Rigid part fixed to ground
!    Mass = 10 kg, Ixx = Iyy = Izz = 1000 kg·mm²
!    Located at origin; mount point also at origin.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .rubber_mount.chassis &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Create the CM marker explicitly so Adams can use it for mass properties.
! The special name 'cm' is Adams' default CM marker for a rigid body.
marker create &
    marker_name = .rubber_mount.chassis.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Set mass properties — Adams uses the existing .cm marker as the CM.
! Do NOT pass center_of_mass_marker; the pre-created .cm is used automatically.
part modify rigid_body mass_properties &
    part_name = .rubber_mount.chassis &
    mass      = 10.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

! Marker for fixed joint (on chassis, I-side)
marker create &
    marker_name = .rubber_mount.chassis.fix_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! J marker of rubber mount — chassis side (defines bushing local frame)
marker create &
    marker_name = .rubber_mount.chassis.bush_j &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis geometry (ellipsoid, 200x50x150 mm envelope)
geometry create shape ellipsoid &
    ellipsoid_name = .rubber_mount.chassis.chassis_geo &
    center_marker  = .rubber_mount.chassis.cm &
    x_scale_factor = 100.0 &
    y_scale_factor = 25.0 &
    z_scale_factor = 75.0

! Fix chassis rigidly to ground
constraint create joint fixed &
    joint_name    = .rubber_mount.chassis_ground_fix &
    i_marker_name = .rubber_mount.chassis.fix_mkr &
    j_marker_name = .rubber_mount.ground.global_ref

! ============================================================
! 6. SUBFRAME — Rigid part free to move, connected via rubber mount
!    Mass = 10 kg, Ixx = Iyy = Izz = 1000 kg·mm²
!    Initially coincident with chassis mount point.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .rubber_mount.subframe &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Create the CM marker explicitly so Adams can use it for mass properties.
marker create &
    marker_name = .rubber_mount.subframe.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Set mass properties — Adams uses the existing .cm marker as the CM.
! Do NOT pass center_of_mass_marker; the pre-created .cm is used automatically.
part modify rigid_body mass_properties &
    part_name = .rubber_mount.subframe &
    mass      = 10.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

! I marker of rubber mount — subframe side
marker create &
    marker_name = .rubber_mount.subframe.bush_i &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Subframe geometry (ellipsoid, 180x40x120 mm envelope)
geometry create shape ellipsoid &
    ellipsoid_name = .rubber_mount.subframe.subframe_geo &
    center_marker  = .rubber_mount.subframe.cm &
    x_scale_factor = 90.0 &
    y_scale_factor = 20.0 &
    z_scale_factor = 60.0

! ============================================================
! 7. RUBBER MOUNT — General Force implementing all 6 DOF
!
!  The Adams bushing element only accepts constant numeric stiffness.
!  A GFORCE is used so the X direction can use an AKISPL spline
!  while Y/Z and rotational directions remain linear.
!
!  Force convention (action on subframe.bush_i, reaction on chassis):
!    X:  restoring = -AKISPL(DX, 0, spline, 0)
!    Y:  restoring = -5000 * DY           (5000 N/mm)
!    Z:  restoring = -5000 * DZ           (5000 N/mm)
!    Rx: restoring = (-200 / 1D) * AX     (200 N·mm/deg; 1D = pi/180 rad)
!    Ry: restoring = (-200 / 1D) * AY
!    Rz: restoring = (-200 / 1D) * AZ
! ============================================================
force create direct general_force &
    general_force_name = .rubber_mount.rubber_mount_gforce &
    i_marker_name      = .rubber_mount.subframe.bush_i &
    j_part_name        = .rubber_mount.chassis &
    ref_marker_name    = .rubber_mount.chassis.bush_j &
    x_force_function   = "-AKISPL(DX(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j, .rubber_mount.chassis.bush_j), 0, .rubber_mount.x_force_spline, 0)" &
    y_force_function   = "-5000.0 * DY(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j, .rubber_mount.chassis.bush_j)" &
    z_force_function   = "-5000.0 * DZ(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j, .rubber_mount.chassis.bush_j)" &
    x_torque_function  = "(-200.0 / 1D) * AX(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j)" &
    y_torque_function  = "(-200.0 / 1D) * AY(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j)" &
    z_torque_function  = "(-200.0 / 1D) * AZ(.rubber_mount.subframe.bush_i, .rubber_mount.chassis.bush_j)"
