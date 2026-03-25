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
!    x  = relative X displacement of subframe w.r.t. chassis (mm)
!    y  = spring force (N) — same sign as displacement (hardening)
!    The GFORCE applies -(spline value) as restoring force on subframe.
! ============================================================
data_element create spline &
    spline_name = .rubber_mount.x_force_spline &
    x = -10.0, -5.0, 0.0, 5.0, 10.0 &
    y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0

! ============================================================
! 4. Ground reference marker (origin)
! ============================================================
marker create &
    marker_name = .rubber_mount.ground.global_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! 5. CHASSIS — Rigid part fixed to ground
!    Mass = 10 kg, Ixx = Iyy = Izz = 1000 kg·mm²
!    CM at origin; mount point at origin.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .rubber_mount.chassis &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .rubber_mount.chassis.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .rubber_mount.chassis &
    mass                  = 10.0 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 1000.0 &
    center_of_mass_marker = .rubber_mount.chassis.cm

! Marker for the fixed joint (I-side, on chassis)
marker create &
    marker_name = .rubber_mount.chassis.fix_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! J-marker at the bushing location — chassis side of the rubber mount
marker create &
    marker_name = .rubber_mount.chassis.bush_j &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis geometry (visual)
geometry create shape ellipsoid &
    ellipsoid_name = .rubber_mount.chassis.chassis_ellips &
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
! 6. SUBFRAME — Rigid part connected to chassis via rubber mount
!    Mass = 10 kg, Ixx = Iyy = Izz = 1000 kg·mm²
!    Initially coincident with chassis; mount at origin.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .rubber_mount.subframe &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .rubber_mount.subframe.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .rubber_mount.subframe &
    mass                  = 10.0 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 1000.0 &
    center_of_mass_marker = .rubber_mount.subframe.cm

! I-marker at the bushing location — subframe side of the rubber mount
marker create &
    marker_name = .rubber_mount.subframe.bush_i &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Subframe geometry (visual)
geometry create shape ellipsoid &
    ellipsoid_name = .rubber_mount.subframe.subframe_ellips &
    center_marker  = .rubber_mount.subframe.cm &
    x_scale_factor = 90.0 &
    y_scale_factor = 20.0 &
    z_scale_factor = 60.0

! ============================================================
! 7. RUBBER MOUNT — GFORCE implementing all 6 DOF
!
!   I    = .rubber_mount.subframe.bush_i  (action side, on subframe)
!   J    = .rubber_mount.chassis.bush_j   (reaction side, on chassis)
!   RMID = .rubber_mount.chassis.bush_j   (defines force/torque axes)
!
!   Relative displacements resolved in chassis (J) frame:
!     DX, DY, DZ in mm
!
!   Relative rotations (Euler angles, in radians) from Adams AX/AY/AZ:
!     AX, AY, AZ in radians
!
!   X: nonlinear — restoring force from AKISPL spline lookup
!   Y: linear 5000 N/mm restoring force
!   Z: linear 5000 N/mm restoring force
!   Rx, Ry, Rz: 200 N·mm/deg = 200 / (1 degree in radians) N·mm/rad
!               = 200 / 1D N·mm/rad  (1D = pi/180 in Adams)
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

! ============================================================
! 8. Simulation — 1 second transient, 100 steps
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 100 &
    model_name      = .rubber_mount &
    initial_static  = no
