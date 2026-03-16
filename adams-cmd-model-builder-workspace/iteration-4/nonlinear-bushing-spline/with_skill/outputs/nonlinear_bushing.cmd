! =============================================================
! Adams CMD Script: Nonlinear Rubber Mount (Chassis / Subframe)
! =============================================================

! --- 1. Model ---
model create &
    model_name = .rubber_mount_model

! --- 2. Units ---
defaults units &
    length = mm &
    angle  = degrees &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 3. Parts ---
part create rigid_body name_and_position &
    part_name   = .rubber_mount_model.chassis &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body name_and_position &
    part_name   = .rubber_mount_model.subframe &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Mass Properties ---
part modify rigid_body mass_properties &
    part_name = .rubber_mount_model.chassis &
    mass      = 10.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

part modify rigid_body mass_properties &
    part_name = .rubber_mount_model.subframe &
    mass      = 10.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

! --- 5. Markers ---
! Ground base marker (J side of fixed joint)
marker create &
    marker_name = .rubber_mount_model.ground.base_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis reference marker (I side of fixed joint)
marker create &
    marker_name = .rubber_mount_model.chassis.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Chassis mount marker (J reference frame for GFORCE)
marker create &
    marker_name = .rubber_mount_model.chassis.mount_j_mkr &
    location    = 0.0, 0.0, 50.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Subframe mount marker (I marker for GFORCE)
marker create &
    marker_name = .rubber_mount_model.subframe.mount_i_mkr &
    location    = 0.0, 0.0, 50.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Data Elements ---
! Nonlinear X-direction force-displacement spline
data_element create spline &
    spline_name = .rubber_mount_model.x_stiffness &
    x           = -10.0, -5.0, 0.0, 5.0, 10.0 &
    y           = -8000.0, -3000.0, 0.0, 3000.0, 8000.0

! --- 7. Constraints ---
! Fix chassis to ground
constraint create joint fixed &
    joint_name    = .rubber_mount_model.fix_chassis &
    i_marker_name = .rubber_mount_model.chassis.ref_mkr &
    j_marker_name = .rubber_mount_model.ground.base_mkr

! --- 8. Forces ---
! Rubber mount: nonlinear X, linear Y/Z translation, linear rotational stiffness
force create direct general_force &
    general_force_name = .rubber_mount_model.rubber_mount &
    i_marker_name      = .rubber_mount_model.subframe.mount_i_mkr &
    j_part_name        = .rubber_mount_model.chassis &
    ref_marker_name    = .rubber_mount_model.chassis.mount_j_mkr &
    x_force_function   = "AKISPL(DX(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr), 0, .rubber_mount_model.x_stiffness, 0)" &
    y_force_function   = "-5000.0 * DY(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr)" &
    z_force_function   = "-5000.0 * DZ(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr)" &
    x_torque_function  = "(-200.0 / 1D) * AX(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr)" &
    y_torque_function  = "(-200.0 / 1D) * AY(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr)" &
    z_torque_function  = "(-200.0 / 1D) * AZ(.rubber_mount_model.subframe.mount_i_mkr, .rubber_mount_model.chassis.mount_j_mkr)"
