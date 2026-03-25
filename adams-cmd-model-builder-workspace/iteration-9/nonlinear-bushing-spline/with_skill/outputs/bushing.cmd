! ============================================================
! Rubber Mount Model — Chassis to Subframe
!
! Nonlinear X-direction stiffness via spline + AKISPL GFORCE
! Linear Y/Z translational stiffness (5000 N/mm) via GFORCE
! Uniform rotational stiffness (200 N·mm/deg about all axes) via GFORCE
!
! Both chassis and subframe: 10 kg, Ixx=Iyy=Izz=1000 kg·mm²
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
!    x-axis = relative X displacement of subframe w.r.t. chassis (mm)
!    y-axis = restoring force magnitude (N), same sign as displacement
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
!    Located at global origin.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .rubber_mount.chassis &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Rule 10: Create .cm marker BEFORE setting mass properties.
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

! Fixed-joint marker on chassis (grounded at origin)
marker create &
    marker_name = .rubber_mount.chassis.fix_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! J-side bushing marker on chassis (defines mount reference frame)
marker create &
    marker_name = .rubber_mount.chassis.bush_j &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis visualization geometry
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

! Rule 10: Create .cm marker BEFORE setting mass properties.
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

! I-side bushing marker on subframe
marker create &
    marker_name = .rubber_mount.subframe.bush_i &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Subframe visualization geometry
geometry create shape ellipsoid &
    ellipsoid_name = .rubber_mount.subframe.subframe_geo &
    center_marker  = .rubber_mount.subframe.cm &
    x_scale_factor = 90.0 &
    y_scale_factor = 20.0 &
    z_scale_factor = 60.0

! ============================================================
! 7. RUBBER MOUNT — General Force implementing all 6 DOF
!
!  A GFORCE is used so the X direction uses an AKISPL spline
!  lookup while Y/Z and rotational directions remain linear.
!
!  Force convention (restoring force acting on subframe):
!    Fx = -AKISPL(DX, 0, spline, 0)          [nonlinear, N]
!    Fy = -5000 * DY                           [linear 5000 N/mm]
!    Fz = -5000 * DZ                           [linear 5000 N/mm]
!    Tx = -(200/1D) * AX                       [200 N·mm/deg]
!    Ty = -(200/1D) * AY                       [200 N·mm/deg]
!    Tz = -(200/1D) * AZ                       [200 N·mm/deg]
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
! 8. Transient simulation (2 seconds, gravity drives motion)
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .rubber_mount &
    initial_static  = no

! ============================================================
! End of bushing.cmd
! ============================================================
