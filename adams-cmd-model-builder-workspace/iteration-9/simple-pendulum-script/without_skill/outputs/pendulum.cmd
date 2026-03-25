! Simple Pendulum
! Single rigid link, 200 mm, 1 kg, pinned at top, gravity -Y, released from 45 deg.

! --- 1. Model and units ---
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground pivot marker ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Link part ---
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. CM marker at mid-link (100 mm below pin) ---
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Mass properties ---
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.33 &
    iyy                   = 3333.33 &
    izz                   = 3333.33 &
    center_of_mass_marker = .pendulum.link.cm

! --- 7. Link markers ---
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Revolute joint ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 9. Initial condition: 45 degrees ---
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 10. Run simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 3.0 &
    number_of_steps = 300 &
    model_name      = .pendulum &
    initial_static  = no
