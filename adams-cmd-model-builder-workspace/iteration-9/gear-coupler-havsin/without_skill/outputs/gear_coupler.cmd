! ==============================================================
! gear_coupler.cmd
! Two-shaft gear system — 3:1 speed ratio, opposite directions
! Input shaft: haversine velocity ramp 0 → 120 deg/s over 0.5 s
! Units: mm, newton, kg, sec
! ==============================================================

! 1. Create model
model create &
    model_name = .gear_coupler

! 2. Set units
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! 3. Gravity (-Y direction)
force create body gravitational &
    gravity_field_name  = .gear_coupler.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ----------------------------------------------------------
! Ground markers (fixed joint reference frames)
! Revolute joints rotate about the Z axis
! ----------------------------------------------------------
marker create &
    marker_name = .gear_coupler.ground.input_pivot &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.ground.output_pivot &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ----------------------------------------------------------
! Input shaft
! 0.5 kg, Ixx = Iyy = 1000 kg·mm², Izz = 50 kg·mm²
! ----------------------------------------------------------
part create rigid_body name_and_position &
    part_name   = .gear_coupler.input_shaft &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.input_shaft.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .gear_coupler.input_shaft &
    mass                  = 0.5 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 50.0 &
    center_of_mass_marker = .gear_coupler.input_shaft.cm

! Joint attachment marker
marker create &
    marker_name = .gear_coupler.input_shaft.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry base marker — offset -25 mm in Z so cylinder is centred on joint
marker create &
    marker_name = .gear_coupler.input_shaft.geom_mkr &
    location    = 0.0, 0.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cylinder geometry (50 mm long, 10 mm radius)
geometry create shape cylinder &
    cylinder_name = .gear_coupler.input_shaft.cyl_shaft &
    center_marker = .gear_coupler.input_shaft.geom_mkr &
    angle_extent  = 360.0D &
    length        = 50.0 &
    radius        = 10.0

! ----------------------------------------------------------
! Output shaft
! 0.5 kg, Ixx = Iyy = 1000 kg·mm², Izz = 50 kg·mm²
! ----------------------------------------------------------
part create rigid_body name_and_position &
    part_name   = .gear_coupler.output_shaft &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .gear_coupler.output_shaft.cm &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .gear_coupler.output_shaft &
    mass                  = 0.5 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 50.0 &
    center_of_mass_marker = .gear_coupler.output_shaft.cm

! Joint attachment marker (global coords: 0, 150, 0)
marker create &
    marker_name = .gear_coupler.output_shaft.pin_mkr &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry base marker — offset -25 mm in Z
marker create &
    marker_name = .gear_coupler.output_shaft.geom_mkr &
    location    = 0.0, 150.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cylinder geometry (50 mm long, 10 mm radius)
geometry create shape cylinder &
    cylinder_name = .gear_coupler.output_shaft.cyl_shaft &
    center_marker = .gear_coupler.output_shaft.geom_mkr &
    angle_extent  = 360.0D &
    length        = 50.0 &
    radius        = 10.0

! ----------------------------------------------------------
! Revolute joints — both on the Z axis
! ----------------------------------------------------------
constraint create joint revolute &
    joint_name    = .gear_coupler.rev_input &
    i_marker_name = .gear_coupler.input_shaft.pin_mkr &
    j_marker_name = .gear_coupler.ground.input_pivot

constraint create joint revolute &
    joint_name    = .gear_coupler.rev_output &
    i_marker_name = .gear_coupler.output_shaft.pin_mkr &
    j_marker_name = .gear_coupler.ground.output_pivot

! ----------------------------------------------------------
! Gear coupler: 3:1 speed ratio, opposite rotation directions
!
! Constraint: 1.0*ω_input + (-0.333)*ω_output = 0
! Negative sign → opposite directions
! |1.0 / 0.333| ≈ 3 → input rotates 3× faster than output
! ----------------------------------------------------------
constraint create complex_joint coupler &
    coupler_name       = .gear_coupler.coupler_gear &
    joint_name         = .gear_coupler.rev_input, .gear_coupler.rev_output &
    type_of_freedom    = rot_rot &
    motion_multipliers = 1.0, -0.333

! ----------------------------------------------------------
! Motion generator on input joint
! Haversine ramp: angular velocity 0 → 120 deg/s over 0–0.5 s, hold thereafter
!
! HAVSIN(x, x0, x1, h0, h1)
!   x  = TIME
!   x0 = 0.0, x1 = 0.5  (ramp interval)
!   h0 = 0.0, h1 = 120D  (start and end values)
!
! time_derivative = velocity → Adams integrates this to get position
! ----------------------------------------------------------
constraint create motion_generator &
    motion_name     = .gear_coupler.motion_drive &
    joint_name      = .gear_coupler.rev_input &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)"

! ----------------------------------------------------------
! Transient simulation — 2 seconds
! ----------------------------------------------------------
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .gear_coupler &
    initial_static  = no
