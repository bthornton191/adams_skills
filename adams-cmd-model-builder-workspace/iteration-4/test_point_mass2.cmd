! Test point mass complete workflow
model create model_name = test_pm

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .test_pm.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

marker create &
    marker_name = .test_pm.ground.ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Mass 1 at origin - to be fixed to ground
part create point_mass name_and_position &
    point_mass_name = .test_pm.ball1 &
    location        = 0.0, 0.0, 0.0

part modify point_mass mass_properties &
    point_mass_name = .test_pm.ball1 &
    mass            = 0.25

marker create &
    marker_name = .test_pm.ball1.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Mass 2 at 50mm - connected to mass1 by spring-damper
part create point_mass name_and_position &
    point_mass_name = .test_pm.ball2 &
    location        = 50.0, 0.0, 0.0

part modify point_mass mass_properties &
    point_mass_name = .test_pm.ball2 &
    mass            = 0.25

marker create &
    marker_name = .test_pm.ball2.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Use atpoint joint primitive to fix ball1 to ground
constraint create joint primitive atpoint &
    joint_name    = .test_pm.fix_ball1 &
    i_marker_name = .test_pm.ball1.ref_mkr &
    j_marker_name = .test_pm.ground.ref

! Connect ball1 to ball2 with spring-damper
force create element_like translational_spring_damper &
    spring_damper_name      = .test_pm.spring_1_2 &
    i_marker_name           = .test_pm.ball1.ref_mkr &
    j_marker_name           = .test_pm.ball2.ref_mkr &
    stiffness               = 100.0 &
    damping                 = 1.0 &
    displacement_at_preload = 50.0

simulation single_run transient &
    type            = auto_select &
    end_time        = 0.1 &
    number_of_steps = 100 &
    model_name      = .test_pm &
    initial_static  = no
