! ============================================================
! Adams CMD Script: Two-Shaft Gear System with 3:1 Gear Ratio
!
! Two shafts spin about parallel Z-axis revolute joints fixed
! to ground. A coupler constraint links them 3:1 (input 3x
! faster, opposite directions). A haversine ramp motion ramps
! the input from 0 to 120 deg/s over the first 0.5 s.
!
! Parts / joints
!   shaft_input  — 0.5 kg | Ixx=Iyy=1000, Izz=50 kg·mm²
!   shaft_output — 0.5 kg | Ixx=Iyy=1000, Izz=50 kg·mm²
!   rev_input    — revolute to ground at (0, 0, 0)
!   rev_output   — revolute to ground at (0, 150, 0)
!   gear_coupler — 3:1 ratio, opposite directions
!   motion_input — HAVSIN velocity ramp 0→120 deg/s / 0→0.5 s
! ============================================================

! --- 1. Model and units ---
model create model_name = model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! ============================================================
! --- 2. Ground markers (fixed pivot locations) ---
! ============================================================

! Input shaft pivot — at origin
marker create &
    marker_name = .model.ground.input_pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Output shaft pivot — 150 mm along Y
marker create &
    marker_name = .model.ground.output_pivot_mkr &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! --- 3. Input shaft ---
!   CM at origin; rotates about Z through that point.
!   Inertia: Ixx=Iyy=1000, Izz=50 kg·mm²  (slender shaft)
! ============================================================
part create rigid_body name_and_position &
    part_name   = .model.shaft_input &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .model.shaft_input &
    mass      = 0.5 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 50.0

! Joint attachment marker on input shaft (co-located with joint)
marker create &
    marker_name = .model.shaft_input.rev_conn_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! --- 4. Output shaft ---
!   CM at (0, 150, 0); rotates about Z through that point.
!   Inertia: Ixx=Iyy=1000, Izz=50 kg·mm²
! ============================================================
part create rigid_body name_and_position &
    part_name   = .model.shaft_output &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .model.shaft_output &
    mass      = 0.5 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 50.0

! Joint attachment marker on output shaft
marker create &
    marker_name = .model.shaft_output.rev_conn_mkr &
    location    = 0.0, 150.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! --- 5. Revolute joints — both rotate about global Z axis ---
!   Default marker orientation (0,0,0) => local Z = global Z
! ============================================================

! Input shaft pinned to ground at origin
constraint create joint revolute &
    joint_name    = .model.rev_input &
    i_marker_name = .model.shaft_input.rev_conn_mkr &
    j_marker_name = .model.ground.input_pivot_mkr

! Output shaft pinned to ground at y = 150 mm
constraint create joint revolute &
    joint_name    = .model.rev_output &
    i_marker_name = .model.shaft_output.rev_conn_mkr &
    j_marker_name = .model.ground.output_pivot_mkr

! ============================================================
! --- 6. Gear coupler — 3:1 ratio, opposite directions ---
!
!   Coupler enforces:  scale_1 * ω_input  +  scale_2 * ω_output = 0
!   Choosing scale_1 = 1.0, scale_2 = 3.0:
!       1.0 * ω_input + 3.0 * ω_output = 0
!   =>  ω_input = −3 * ω_output
!   => input rotates 3x faster, in the opposite direction.  ✓
! ============================================================
constraint create coupler &
    coupler_name           = .model.gear_coupler &
    joint_name             = .model.rev_input, .model.rev_output &
    type_of_freedom        = rotational, rotational &
    scale_of_joint_freedom = 1.0, 3.0

! ============================================================
! --- 7. Motion on input shaft ---
!
!   Angular velocity profile (deg/s):
!     0   → 0.5 s : haversine ramp from 0 to 120 deg/s  (HAVSIN)
!     0.5 → 2.0 s : holds at 120 deg/s
!
!   HAVSIN(x, x0, h0, x1, h1)
!     x : independent variable (TIME)
!     x0: start of transition  = 0
!     h0: value at x0          = 0       (0 deg/s)
!     x1: end of transition    = 0.5     (s)
!     h1: value at x1          = 120D    (120 deg/s)
!   Returns h0 for x<x0, smooth haversine blend for x0≤x≤x1,
!   and h1 for x>x1 — naturally holds at 120 deg/s.
! ============================================================
constraint create motion_generator &
    motion_name     = .model.motion_input &
    joint_name      = .model.rev_input &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "HAVSIN(TIME, 0, 0, 0.5, 120D)"

! ============================================================
! --- 8. Cylinder geometry --- (radius 20 mm, length 100 mm)
!   Each shaft is centred at its CM marker and oriented along Z.
! ============================================================

! Input shaft cylinder
geometry create shape cylinder &
    geometry_name          = .model.shaft_input.cyl_shape &
    part_name              = .model.shaft_input &
    center_marker          = .model.shaft_input.cm &
    angle_extent           = 360.0 &
    length                 = 100.0 &
    radius                 = 20.0 &
    side_count_for_body    = 20 &
    segment_count_for_ends = 2

! Output shaft cylinder
geometry create shape cylinder &
    geometry_name          = .model.shaft_output.cyl_shape &
    part_name              = .model.shaft_output &
    center_marker          = .model.shaft_output.cm &
    angle_extent           = 360.0 &
    length                 = 100.0 &
    radius                 = 20.0 &
    side_count_for_body    = 20 &
    segment_count_for_ends = 2

! ============================================================
! --- 9. Transient simulation — 2 seconds ---
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .model &
    initial_static  = no

! ============================================================
! End of gear_coupler.cmd
! ============================================================
