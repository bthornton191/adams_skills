! ============================================================
! Four-Bar Linkage — Adams CMD script
!
! Topology (Grashof crank-rocker):
!   Ground link : 300 mm  (O2 to O4 — fixed to ground)
!   Crank  (2)  : 100 mm, 0.5 kg  (pinned to ground at O2)
!   Coupler(3)  : 250 mm, 0.5 kg  (connects A on crank to B on rocker)
!   Rocker (4)  : 200 mm, 0.5 kg  (pinned to ground at O4)
!
! Initial configuration: crank horizontal, pointing in +X direction
!   O2 = (   0.000,   0.000, 0 )  crank ground pivot
!   A  = ( 100.000,   0.000, 0 )  crank free end / coupler end 1
!   B  = ( 256.250, 195.156, 0 )  rocker free end / coupler end 2
!   O4 = ( 300.000,   0.000, 0 )  rocker ground pivot
!
! Grashof check: s + l = 100 + 300 = 400 <= p + q = 200 + 250 = 450  PASS
! (Crank is the shortest link adjacent to ground => crank-rocker)
!
! B derivation:
!   dist(A, B) = 250 => (x-100)^2 + y^2 = 62500
!   dist(O4,B) = 200 => (x-300)^2 + y^2 = 40000
!   Subtract:  400x - 80000 = 22500  =>  x = 256.25
!              y = sqrt(40000 - 43.75^2) = 195.156
!
! Drive:    crank at constant 360 deg/s (one full revolution per second)
! Simulate: 2 s, step size 0.001 s  =>  2000 output steps
! ============================================================

! --- 1. Model and units ---
model create model_name = four_bar

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (y = -9806.65 mm/s^2) ---
force create body gravitational &
    gravity_field_name  = .four_bar.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! --- 3. Ground markers (fixed pivot locations) ---
! ============================================================

! O2: crank pivot at origin
marker create &
    marker_name = .four_bar.ground.crank_pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! O4: rocker pivot 300 mm to the right of origin
marker create &
    marker_name = .four_bar.ground.rocker_pivot_mkr &
    location    = 300.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! --- 4. Crank (link 2) ---
!   O2 = (0, 0, 0),  A = (100, 0, 0)
!   Part origin placed at CM = midpoint = (50, 0, 0)
!   Izz = m*L^2/12 = 0.5*100^2/12 = 416.667 kg*mm^2
!   CM marker pre-created at part origin so Adams finds it at verification.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .four_bar.crank &
    location    = 50.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pre-create .cm at the part origin (global 50, 0, 0)
marker create &
    marker_name = .four_bar.crank.cm &
    location    = 50.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .four_bar.crank &
    mass                  = 0.5 &
    ixx                   = 416.667 &
    iyy                   = 416.667 &
    izz                   = 416.667 &
    center_of_mass_marker = .four_bar.crank.cm

! Pin marker at O2 (ground pivot end)
marker create &
    marker_name = .four_bar.crank.pin_ground_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pin marker at A (coupler connection end)
marker create &
    marker_name = .four_bar.crank.pin_coupler_mkr &
    location    = 100.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Crank geometry: bar connecting O2 to A
geometry create shape link &
    link_name = .four_bar.crank.shape_body &
    i_marker  = .four_bar.crank.pin_ground_mkr &
    j_marker  = .four_bar.crank.pin_coupler_mkr &
    width     = 15.0 &
    depth     = 8.0

! ============================================================
! --- 5. Coupler (link 3) ---
!   A = (100, 0, 0),  B = (256.25, 195.156, 0)
!   Part origin placed at CM = midpoint = (178.125, 97.578, 0)
!   Izz = m*L^2/12 = 0.5*250^2/12 = 2604.167 kg*mm^2
!   CM marker pre-created at part origin so Adams finds it at verification.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .four_bar.coupler &
    location    = 178.125, 97.578, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pre-create .cm at the part origin (global 178.125, 97.578, 0)
marker create &
    marker_name = .four_bar.coupler.cm &
    location    = 178.125, 97.578, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .four_bar.coupler &
    mass                  = 0.5 &
    ixx                   = 2604.167 &
    iyy                   = 2604.167 &
    izz                   = 2604.167 &
    center_of_mass_marker = .four_bar.coupler.cm

! Pin marker at A (crank connection end)
marker create &
    marker_name = .four_bar.coupler.pin_crank_mkr &
    location    = 100.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pin marker at B (rocker connection end)
marker create &
    marker_name = .four_bar.coupler.pin_rocker_mkr &
    location    = 256.25, 195.156, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Coupler geometry: bar connecting A to B
geometry create shape link &
    link_name = .four_bar.coupler.shape_body &
    i_marker  = .four_bar.coupler.pin_crank_mkr &
    j_marker  = .four_bar.coupler.pin_rocker_mkr &
    width     = 15.0 &
    depth     = 8.0

! ============================================================
! --- 6. Rocker (link 4) ---
!   O4 = (300, 0, 0),  B = (256.25, 195.156, 0)
!   Part origin placed at CM = midpoint = (278.125, 97.578, 0)
!   Izz = m*L^2/12 = 0.5*200^2/12 = 1666.667 kg*mm^2
!   CM marker pre-created at part origin so Adams finds it at verification.
! ============================================================
part create rigid_body name_and_position &
    part_name   = .four_bar.rocker &
    location    = 278.125, 97.578, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pre-create .cm at the part origin (global 278.125, 97.578, 0)
marker create &
    marker_name = .four_bar.rocker.cm &
    location    = 278.125, 97.578, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .four_bar.rocker &
    mass                  = 0.5 &
    ixx                   = 1666.667 &
    iyy                   = 1666.667 &
    izz                   = 1666.667 &
    center_of_mass_marker = .four_bar.rocker.cm

! Pin marker at O4 (ground pivot end)
marker create &
    marker_name = .four_bar.rocker.pin_ground_mkr &
    location    = 300.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Pin marker at B (coupler connection end)
marker create &
    marker_name = .four_bar.rocker.pin_coupler_mkr &
    location    = 256.25, 195.156, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Rocker geometry: bar connecting B to O4
geometry create shape link &
    link_name = .four_bar.rocker.shape_body &
    i_marker  = .four_bar.rocker.pin_coupler_mkr &
    j_marker  = .four_bar.rocker.pin_ground_mkr &
    width     = 15.0 &
    depth     = 8.0

! ============================================================
! --- 7. Revolute joints ---
! All joints rotate about the global Z-axis (default orientation).
! ============================================================

! J1: crank pinned to ground at O2
constraint create joint revolute &
    joint_name    = .four_bar.rev_crank_ground &
    i_marker_name = .four_bar.crank.pin_ground_mkr &
    j_marker_name = .four_bar.ground.crank_pivot_mkr

! J2: coupler pinned to crank at A
constraint create joint revolute &
    joint_name    = .four_bar.rev_crank_coupler &
    i_marker_name = .four_bar.coupler.pin_crank_mkr &
    j_marker_name = .four_bar.crank.pin_coupler_mkr

! J3: rocker pinned to coupler at B
constraint create joint revolute &
    joint_name    = .four_bar.rev_coupler_rocker &
    i_marker_name = .four_bar.rocker.pin_coupler_mkr &
    j_marker_name = .four_bar.coupler.pin_rocker_mkr

! J4: rocker pinned to ground at O4
constraint create joint revolute &
    joint_name    = .four_bar.rev_rocker_ground &
    i_marker_name = .four_bar.rocker.pin_ground_mkr &
    j_marker_name = .four_bar.ground.rocker_pivot_mkr

! ============================================================
! --- 8. Crank drive motion ---
!   Constant angular velocity: 360 deg/s = 2*PI rad/s
! ============================================================
constraint create motion_generator &
    motion_name     = .four_bar.motion_crank &
    joint_name      = .four_bar.rev_crank_ground &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "360D"

! ============================================================
! --- 9. Transient simulation ---
!   Duration:  2 s
!   Step size: 0.001 s  =>  2000 output steps
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .four_bar &
    initial_static  = no

! ============================================================
! End of four_bar.cmd
! ============================================================
