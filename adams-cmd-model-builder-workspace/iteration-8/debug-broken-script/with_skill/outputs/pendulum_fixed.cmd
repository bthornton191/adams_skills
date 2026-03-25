! Corrected pendulum model
! Bugs fixed:
!   1. model cre -> model create (Rule 1: no abbreviations)
!   2. model_name = .pendulum -> pendulum (leading dot invalid at creation, Rule 2)
!   3. part cre rig nam -> part create rigid_body name_and_position (Rule 1)
!   4. part create mass_properties -> part modify mass_properties (Rule 9: only one part create)
!   5. Removed adams_id = 3 (Rule 8: never specify adams_id manually)
!   6. Explicitly create .cm marker before part modify; pass center_of_mass_marker
!      (Adams 2023.2 does not auto-create .cm — must pre-create and reference it)
!   7. marker_name = pendulum.link.pin_mkr -> .pendulum.link.pin_mkr (missing dot, Rule 2)
!   8. i_marker_name = pendulum.link.pin_mkr -> .pendulum.link.pin_mkr (missing dot, Rule 2)
!   9. spring_damper -> translational_spring_damper (Rule 13)
!  10. length = 200.0 -> displacement_at_preload = 200.0 (Rule 13)
!  11. sim trans ... -> simulation single_run transient ... (Rule 14)
!  12. Added link geometry on moving part (Rule 15)

model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

marker create &
    marker_name = .pendulum.ground.pivot_j &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.ground.wall_j &
    location    = 0.0, -200.0, 0.0

part create rigid_body name_and_position &
    part_name = .pendulum.link &
    location  = 0.0, 0.0, 0.0

! Adams 2023.2 requires an explicit .cm marker; it does not auto-create one.
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

geometry create shape link &
    link_name = .pendulum.link.shape_link &
    i_marker  = .pendulum.link.pin_mkr &
    j_marker  = .pendulum.link.tip_mkr &
    width     = 10.0 &
    depth     = 5.0

constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_j

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
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
