! ============================================================
! Simple Pendulum — corrected Adams CMD script
! ============================================================
! Bugs fixed:
!   1. 'model cre' -> 'model create' (invalid abbreviation)
!   2. 'model_name = .pendulum' -> 'model_name = pendulum' (no dot at creation)
!   3. 'part cre rig nam' -> 'part create rigid_body name_and_position' (all tokens wrong)
!   4. 'part create rigid_body mass_properties' -> 'part modify rigid_body mass_properties'
!      (part already created; cannot call 'part create' twice on the same part)
!   5. adams_id removed from mass_properties modify (IDs are assigned at creation only)
!   6. '.pendulum.link.cm' marker created explicitly before being referenced
!   7. 'pendulum.link.pin_mkr' -> '.pendulum.link.pin_mkr' (missing leading dot — two occurrences)
!   8. 'spring_damper' -> 'translational_spring_damper' (correct element sub-type)
!   9. 'length = 200.0' -> 'displacement_at_preload = 200.0' ('length' is not valid)
!  10. 'sim trans end_time = 2.0 step_size = 0.001' ->
!      'simulation single_run transient' with 'number_of_steps' replacing invalid 'step_size',
!      and required parameters 'type', 'model_name', 'initial_static' added
! ============================================================

! --- Model ---
model create model_name = pendulum

! --- Units ---
defaults units &
    length = mm &
    angle  = degrees &
    time   = sec &
    mass   = kg &
    force  = newton

! --- Ground markers ---
marker create &
    marker_name = .pendulum.ground.pivot_j &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.ground.wall_j &
    location    = 0.0, -200.0, 0.0

! --- Create link part with location ---
part create rigid_body name_and_position &
    part_name = .pendulum.link &
    location  = 0.0, 0.0, 0.0

! --- Create cm marker explicitly before referencing it in mass_properties ---
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0

! --- Set mass properties (modify, not create — part already exists) ---
part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.0 &
    iyy                   = 3333.0 &
    izz                   = 100.0

! --- Link markers ---
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0

! --- Revolute joint ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_j

! --- Gravity ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- Spring-damper ---
force create element_like translational_spring_damper &
    spring_damper_name      = .pendulum.return_spring &
    i_marker_name           = .pendulum.link.tip_mkr &
    j_marker_name           = .pendulum.ground.wall_j &
    stiffness               = 10.0 &
    damping                 = 0.1 &
    displacement_at_preload = 200.0

! --- Simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
