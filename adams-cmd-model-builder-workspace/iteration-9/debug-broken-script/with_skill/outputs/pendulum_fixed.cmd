! ============================================================
! Simple Pendulum with spring-damper (fixed)
! ============================================================

! --- 1. Model and units ---
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (-Y direction) ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground markers ---
marker create &
    marker_name = .pendulum.ground.pivot_j &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .pendulum.ground.wall_j &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Create link part ---
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Create .cm marker at mid-link (100 mm below pin) ---
!        Must exist BEFORE mass_properties (Rule 10)
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Set mass properties (modify, not create — Rule 9; no adams_id — Rule 8) ---
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.0 &
    iyy                   = 3333.0 &
    izz                   = 100.0

! --- 7. Additional markers on the link ---
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Geometry (Rule 15) ---
geometry create shape link &
    link_name = .pendulum.link.shape_rod &
    i_marker  = .pendulum.link.pin_mkr &
    j_marker  = .pendulum.link.tip_mkr &
    width     = 8.0 &
    depth     = 4.0

geometry create shape ellipsoid &
    ellipsoid_name = .pendulum.link.ellips_bob &
    center_marker  = .pendulum.link.tip_mkr &
    x_scale_factor = 12.0 &
    y_scale_factor = 12.0 &
    z_scale_factor = 12.0

! --- 9. Revolute joint at pivot ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_j

! --- 10. Spring-damper (translational_spring_damper; displacement_at_preload not length — Rule 13) ---
force create element_like translational_spring_damper &
    spring_damper_name      = .pendulum.return_spring &
    i_marker_name           = .pendulum.link.tip_mkr &
    j_marker_name           = .pendulum.ground.wall_j &
    stiffness               = 10.0 &
    damping                 = 0.1 &
    displacement_at_preload = 200.0

! --- 11. Simulation (simulation single_run transient — Rule 14) ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no

! ============================================================
! End of pendulum_fixed.cmd
! ============================================================
