model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

marker create &
    marker_name = .pendulum.ground.pivot_j &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.ground.wall_j &
    location    = 0.0, -200.0, 0.0

part create rigid_body name_and_position &
    part_name = .pendulum.link &
    location  = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0

part create rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.0 &
    iyy                   = 3333.0 &
    izz                   = 100.0

marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0

constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_j

force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

force create element_like translational_spring_damper &
    spring_damper_name      = .pendulum.return_spring &
    i_marker_name           = .pendulum.link.tip_mkr &
    j_marker_name           = .pendulum.ground.wall_j &
    stiffness               = 10.0 &
    damping                 = 0.1 &
    displacement_at_preload = 200.0

simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000
