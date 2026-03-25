! ============================================================
! Rubber Mount Model: Chassis to Subframe
! Nonlinear X stiffness via spline + AKISPL in GFORCE
! Linear Y/Z translational stiffness (5000 N/mm)
! Rotational stiffness 200 N·mm/deg about all axes
! ============================================================

! --- 1. Model and units ---
model create &
    model_name = .rubber_mount

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity ---
force create body gravitational &
    gravity_field_name  = .rubber_mount.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Spline: X force-displacement table ---
data_element create spline &
    spline_name = .rubber_mount.x_force_spline &
    x = -10.0, -5.0, 0.0, 5.0, 10.0 &
    y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0

! --- 4. Ground reference marker ---
marker create &
    marker_name = .rubber_mount.ground.global_ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Chassis: rigid part fixed to ground ---
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

marker create &
    marker_name = .rubber_mount.chassis.fix_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis-side bushing reference marker (J-side of force)
marker create &
    marker_name = .rubber_mount.chassis.bush_j &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Fix chassis to ground
constraint create joint fixed &
    joint_name    = .rubber_mount.chassis_ground_fix &
    i_marker_name = .rubber_mount.chassis.fix_mkr &
    j_marker_name = .rubber_mount.ground.global_ref

! --- 6. Subframe: rigid part free to move ---
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

! Subframe-side bushing marker (I-side of force)
marker create &
    marker_name = .rubber_mount.subframe.bush_i &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 7. Rubber mount: GFORCE implementing all 6 DOF ---
!   X:  nonlinear via AKISPL spline lookup
!   Y,Z: linear at 5000 N/mm
!   Rx,Ry,Rz: rotational at 200 N·mm/deg
!             (1D converts degrees to radians; AX/AY/AZ return radians)
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

! --- 8. Transient simulation (1 second) ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 100 &
    model_name      = .rubber_mount &
    initial_static  = no

! ============================================================
! End of bushing.cmd
! ============================================================
