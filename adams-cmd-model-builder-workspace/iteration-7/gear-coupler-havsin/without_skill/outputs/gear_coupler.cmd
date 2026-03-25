! ==============================================================
! gear_coupler.cmd
! Two-shaft gear system — 3:1 speed ratio, opposite directions
! Input shaft: haversine velocity ramp 0 → 120 deg/s over 0.5 s
! Units: mm, newton, kg, sec
! ==============================================================

! 1. Create model
model create &
    model_name = .model

! 2. Set units
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! 3. Gravity (-Y direction)
force create body gravitational &
    gravity_field_name  = .model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ----------------------------------------------------------
! Ground markers (fixed joint reference frames)
! Revolute joints rotate about the Z axis (default orientation)
! ----------------------------------------------------------
marker create &
    marker_name = .model.ground.input_pivot &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .model.ground.output_pivot &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ----------------------------------------------------------
! Input shaft
! 0.5 kg, Ixx = Iyy = 1000 kg·mm², Izz = 50 kg·mm²
! ----------------------------------------------------------
part create rigid_body name_and_position &
    part_name   = .model.input_shaft &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .model.input_shaft.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .model.input_shaft &
    mass                  = 0.5 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 50.0 &
    center_of_mass_marker = .model.input_shaft.cm

! Joint attachment marker (coincident with input_pivot)
marker create &
    marker_name = .model.input_shaft.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry base marker — offset -25 mm in Z so cylinder is centred on joint
marker create &
    marker_name = .model.input_shaft.geom_mkr &
    location    = 0.0, 0.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cylinder extending 50 mm along +Z (shaft visualisation)
geometry create shape cylinder &
    cylinder_name = .model.input_shaft.cyl_shaft &
    center_marker = .model.input_shaft.geom_mkr &
    angle_extent  = 360.0D &
    length        = 50.0 &
    radius        = 10.0

! ----------------------------------------------------------
! Output shaft
! 0.5 kg, Ixx = Iyy = 1000 kg·mm², Izz = 50 kg·mm²
! ----------------------------------------------------------
part create rigid_body name_and_position &
    part_name   = .model.output_shaft &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .model.output_shaft.cm &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .model.output_shaft &
    mass                  = 0.5 &
    ixx                   = 1000.0 &
    iyy                   = 1000.0 &
    izz                   = 50.0 &
    center_of_mass_marker = .model.output_shaft.cm

! Joint attachment marker (coincident with output_pivot)
marker create &
    marker_name = .model.output_shaft.pin_mkr &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry base marker — offset -25 mm in Z so cylinder is centred on joint
marker create &
    marker_name = .model.output_shaft.geom_mkr &
    location    = 0.0, 150.0, -25.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Cylinder extending 50 mm along +Z (shaft visualisation)
geometry create shape cylinder &
    cylinder_name = .model.output_shaft.cyl_shaft &
    center_marker = .model.output_shaft.geom_mkr &
    angle_extent  = 360.0D &
    length        = 50.0 &
    radius        = 10.0

! ----------------------------------------------------------
! Revolute joints — both on the Z axis (default orientation)
! ----------------------------------------------------------
constraint create joint revolute &
    joint_name    = .model.rev_input &
    i_marker_name = .model.input_shaft.pin_mkr &
    j_marker_name = .model.ground.input_pivot

constraint create joint revolute &
    joint_name    = .model.rev_output &
    i_marker_name = .model.output_shaft.pin_mkr &
    j_marker_name = .model.ground.output_pivot

! ----------------------------------------------------------
! Gear coupler: 3:1 speed ratio, opposite rotation directions
!
! Constraint: motion_multipliers[1]*ω_input + motion_multipliers[2]*ω_output = 0
!             1.0*ω_input + (-0.333)*ω_output = 0
!
! The negative sign on the second multiplier encodes opposite-direction
! rotation. The magnitude ratio |1.0 / 0.333| ≈ 3 encodes the 3:1 ratio
! so that the input shaft rotates 3× faster than the output shaft.
! ----------------------------------------------------------
constraint create complex_joint coupler &
    coupler_name       = .model.coupler_gear &
    joint_name         = .model.rev_input, .model.rev_output &
    type_of_freedom    = rot_rot &
    motion_multipliers = 1.0, -0.333

! ----------------------------------------------------------
! Motion generator on input joint
! Haversine ramp: angular velocity 0 → 120 deg/s over 0–0.5 s, hold thereafter
!
! HAVSIN(x, x0, x1, h0, h1)
!   x  = TIME (independent variable)
!   x0 = 0.0  (start of transition)
!   x1 = 0.5  (end of transition)
!   h0 = 0.0  (value at x0 = 0 deg/s)
!   h1 = 120D (value at x1 = 120 deg/s)
! Returns h0 for TIME < 0, smooth haversine blend for 0 ≤ TIME ≤ 0.5,
! and h1 = 120 deg/s for TIME > 0.5 — naturally holds at 120 deg/s.
! ----------------------------------------------------------
constraint create motion_generator &
    motion_name     = .model.motion_drive &
    joint_name      = .model.rev_input &
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
    model_name      = .model &
    initial_static  = no
