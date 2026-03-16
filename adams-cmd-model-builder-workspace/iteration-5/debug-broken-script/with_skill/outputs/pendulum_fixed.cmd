! ============================================================
! Simple Pendulum — fixed Adams CMD script
! ============================================================

! --- 1. Model ---
! Bug 1 fixed: 'model cre' → 'model create model_name ='
model create model_name = pendulum

! --- 2. Units ---
! Bug 2 fixed: 'millimeter' → 'mm'
! Bug 3 fixed: 'second'     → 'sec'
! Bug 4 fixed: 'kilogram'   → 'kg'
defaults units &
    length = mm &
    angle  = degrees &
    time   = sec &
    mass   = kg &
    force  = newton

! --- 3. Create the link part ---
! Bug 5 fixed: 'part cre rig nam' → 'part create rigid_body name_and_position'
! Bug 6 fixed: location changed from 0.0, -100.0, 0.0 → 0.0, 0.0, 0.0
!              so that the pin marker coincides with the ground pivot marker
! Bug 7 fixed: orientation angle values now use 'D' suffix for degrees
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 45.0D

! --- 4. Mass properties ---
! Bug 8 fixed:  'part create rigid_body mass_properties' → 'part modify rigid_body mass_properties'
!               (calling 'part create' a second time on the same part errors)
! Bug 9 fixed:  removed 'adams_id = 5' (Adams auto-assigns IDs; manual IDs are error-prone)
! Bug 10 fixed: corrected 'center_of_mass_marker = pendulum.link.cm'
!               Must create .cm marker explicitly first, then pass it.
marker create &
    marker_name = .pendulum.link.cm &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .pendulum.link &
    mass                  = 1.0 &
    ixx                   = 3333.3 &
    iyy                   = 1.0 &
    izz                   = 3333.3 &
    center_of_mass_marker = .pendulum.link.cm

! --- 5. Markers ---
! Bug 7 (continued): orientation values use 'D' suffix
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Revolute joint ---
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 7. Spring-damper ---
! Bug 11 fixed: 'spring_damper' → 'translational_spring_damper'
! Bug 12 fixed: 'length = 200.0' → 'displacement_at_preload = 200.0'
!               ('length' is not a valid parameter; free length is set via displacement_at_preload)
force create element_like translational_spring_damper &
    spring_damper_name      = .pendulum.gravity_spring &
    i_marker_name           = .pendulum.link.pin_mkr &
    j_marker_name           = .pendulum.ground.pivot_mkr &
    stiffness               = 0.0 &
    damping                 = 0.0 &
    displacement_at_preload = 200.0

! --- 8. Gravity ---
! Bug 13 fixed: 'gravity create' → 'force create body gravitational'
!               removed invalid parameters 'model_name' and 'direction = gravity'
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 9. Simulation ---
! Bug 14 fixed: 'sim trans end_time = 2.0 step_size = 0.001'
!               → 'simulation single_run transient' (full keyword, not abbreviation)
!               'step_size' is not a valid parameter; use 'number_of_steps'
!               (2.0 s / 0.001 s step = 2000 steps)
!               required parameters 'type', 'model_name', and 'initial_static' added
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
