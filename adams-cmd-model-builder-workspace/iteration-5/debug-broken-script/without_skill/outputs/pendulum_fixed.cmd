model create pendulum

defaults units &
    length = millimeter &
    angle = degrees &
    time = second &
    mass = kilogram &
    force = newton

part create rigid_body name = .pendulum.link &
    location = 0.0, -100.0, 0.0 &
    orientation = 0.0, 0.0, 45.0

part create rigid_body mass_properties &
    part_name = .pendulum.link &
    mass = 1.0 &
    ixx = 3333.3 &
    iyy = 0.0 &
    izz = 3333.3 &
    center_of_mass_marker = .pendulum.link.cm

marker create &
    marker_name = .pendulum.link.pin_mkr &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

constraint create joint revolute &
    joint_name = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

gravity create &
    model_name = .pendulum &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

simulation single_run transient &
    end_time = 2.0 &
    step_size = 0.001
