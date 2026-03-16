! Test point mass with spherical joint + CM marker + simulation
model create model_name = test_pm3

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .test_pm3.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

marker create &
    marker_name = .test_pm3.ground.ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Mass 1 - to be fixed to ground
part create point_mass name_and_position &
    point_mass_name = .test_pm3.ball1 &
    location        = 0.0, 0.0, 0.0

marker create &
    marker_name = .test_pm3.ball1.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify point_mass mass_properties &
    point_mass_name       = .test_pm3.ball1 &
    mass                  = 0.25 &
    center_of_mass_marker = .test_pm3.ball1.cm

marker create &
    marker_name = .test_pm3.ball1.ref_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Fix ball1 to ground with spherical joint (removes 3 translations; OK for point mass)
constraint create joint spherical &
    joint_name    = .test_pm3.fix_ball1 &
    i_marker_name = .test_pm3.ball1.ref_mkr &
    j_marker_name = .test_pm3.ground.ref

simulation single_run transient &
    type            = auto_select &
    end_time        = 0.1 &
    number_of_steps = 10 &
    model_name      = .test_pm3 &
    initial_static  = no
