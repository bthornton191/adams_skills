! Corrected pendulum model
! Bugs fixed:
!   1. model cre -> model create (abbreviated keyword)
!   2. part cre rig nam -> part create rigid_body name_and_position (abbreviated keywords)
!   3. part create rigid_body mass_properties -> part modify rigid_body mass_properties (cannot call part create twice)
!   4. Removed adams_id = 3 (never specify manually)
!   5. Added explicit .cm marker creation before part modify (required by Adams 2023.2)
!   6. pendulum.link.pin_mkr -> .pendulum.link.pin_mkr (missing leading dot)
!   7. i_marker_name = pendulum.link.pin_mkr -> .pendulum.link.pin_mkr (missing leading dot in constraint)
!   8. force create element_like spring_damper -> force create element_like translational_spring_damper
!   9. Removed invalid length = 200.0 parameter (use displacement_at_preload instead)
!  10. sim trans ... -> simulation single_run transient (abbreviated and wrong command)

model create model_name = .pendulum

defaults units &
    length = mm &
    mass = kg

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
    location    = 0.0, 0.0, 0.0

part modify rigid_body mass_properties &
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
    spring_damper_name = .pendulum.return_spring &
    i_marker_name      = .pendulum.link.tip_mkr &
    j_marker_name      = .pendulum.ground.wall_j &
    stiffness          = 10.0 &
    damping            = 0.1

simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
