! ============================================================
! Four-Bar Linkage Model
! ============================================================
! Links:
!   Crank  : 100 mm, 0.5 kg   (A-B)
!   Coupler: 250 mm, 0.5 kg   (B-C)
!   Rocker : 200 mm, 0.5 kg   (D-C)
! Ground pins:
!   A at world (0,0,0)
!   D at world (300,0,0)
! Joint locations:
!   A = (0,0,0)     B = (100,0,0)
!   D = (300,0,0)   C = (300,200,0)
! Crank driven at 360 deg/s (constant)
! ============================================================

! Create model
model create &
    model_name = four_bar

! Units
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! Gravity
force create body gravitational &
    gravity_field_name  = .four_bar.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! GROUND MARKERS
! ============================================================

marker create &
    marker_name = .four_bar.ground.mkr_a &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .four_bar.ground.mkr_d &
    location    = 300.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! CRANK  (100 mm, pinned A=0,0,0 to B=100,0,0)
! Part reference point at midpoint: world (50,0,0)
! pin_a local (-50,0,0) -> world (0,0,0)
! pin_b local ( 50,0,0) -> world (100,0,0)
! ============================================================

part create rigid_body name_and_position &
    part_name   = .four_bar.crank &
    location    = 50.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Izz = m * L^2 / 12 = 0.5 * 100^2 / 12 = 416.67 kg*mm^2
marker create &
    marker_name = .four_bar.crank.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body mass_properties &
    part_name             = .four_bar.crank &
    mass                  = 0.5 &
    center_of_mass_marker = .four_bar.crank.cm &
    ixx                   = 416.67 &
    iyy                   = 416.67 &
    izz                   = 416.67

marker create &
    marker_name = .four_bar.crank.pin_a &
    location    = -50.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .four_bar.crank.pin_b &
    location    = 50.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! ROCKER  (200 mm, pinned D=300,0,0 to C=300,200,0)
! Part reference point at midpoint: world (300,100,0)
! pin_d local (0,-100,0) -> world (300,0,0)
! pin_c local (0, 100,0) -> world (300,200,0)
! ============================================================

part create rigid_body name_and_position &
    part_name   = .four_bar.rocker &
    location    = 300.0, 100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Izz = m * L^2 / 12 = 0.5 * 200^2 / 12 = 1666.67 kg*mm^2
marker create &
    marker_name = .four_bar.rocker.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body mass_properties &
    part_name             = .four_bar.rocker &
    mass                  = 0.5 &
    center_of_mass_marker = .four_bar.rocker.cm &
    ixx                   = 1666.67 &
    iyy                   = 1666.67 &
    izz                   = 1666.67

marker create &
    marker_name = .four_bar.rocker.pin_d &
    location    = 0.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .four_bar.rocker.pin_c &
    location    = 0.0, 100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! COUPLER  (connects B=100,0,0 to C=300,200,0)
! Part reference point at midpoint: world (200,100,0)
! pin_b_mkr local (-100,-100,0) -> world (100,0,0)
! pin_c_mkr local ( 100, 100,0) -> world (300,200,0)
! Note: actual distance B-C = sqrt(200^2+200^2) ~ 283 mm;
!       Adams assembly resolves the initial configuration.
! Izz uses nominal 250 mm design length for inertia.
! ============================================================

part create rigid_body name_and_position &
    part_name   = .four_bar.coupler &
    location    = 200.0, 100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Izz = m * L^2 / 12 = 0.5 * 250^2 / 12 = 2604.17 kg*mm^2
marker create &
    marker_name = .four_bar.coupler.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body mass_properties &
    part_name             = .four_bar.coupler &
    mass                  = 0.5 &
    center_of_mass_marker = .four_bar.coupler.cm &
    ixx                   = 2604.17 &
    iyy                   = 2604.17 &
    izz                   = 2604.17

marker create &
    marker_name = .four_bar.coupler.pin_b_mkr &
    location    = -100.0, -100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .four_bar.coupler.pin_c_mkr &
    location    = 100.0, 100.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! REVOLUTE JOINTS
! ============================================================

! Joint A: crank pinned to ground at world (0,0,0)
constraint create joint revolute &
    joint_name    = .four_bar.rev_a &
    i_marker_name = .four_bar.crank.pin_a &
    j_marker_name = .four_bar.ground.mkr_a

! Joint B: crank free end connected to coupler at world (100,0,0)
constraint create joint revolute &
    joint_name    = .four_bar.rev_b &
    i_marker_name = .four_bar.crank.pin_b &
    j_marker_name = .four_bar.coupler.pin_b_mkr

! Joint C: rocker free end connected to coupler at world (300,200,0)
constraint create joint revolute &
    joint_name    = .four_bar.rev_c &
    i_marker_name = .four_bar.rocker.pin_c &
    j_marker_name = .four_bar.coupler.pin_c_mkr

! Joint D: rocker pinned to ground at world (300,0,0)
constraint create joint revolute &
    joint_name    = .four_bar.rev_d &
    i_marker_name = .four_bar.rocker.pin_d &
    j_marker_name = .four_bar.ground.mkr_d

! ============================================================
! MOTION: Drive crank at constant 360 deg/s
! function defines angular POSITION -> d(theta)/dt = 360 deg/s
! theta(t) = 360D * TIME  =>  angular velocity = 360 deg/s
! ============================================================

constraint create motion_generator &
    motion_name     = .four_bar.motion_crank &
    joint_name      = .four_bar.rev_a &
    type_of_freedom = rotational &
    function        = "360D * TIME"

! ============================================================
! SIMULATE: 2 seconds, 0.001 s step size (2000 output steps)
! ============================================================

simulation single_run transient &
    type           = auto_select &
    end_time       = 2.0 &
    number_of_steps = 2000 &
    model_name     = .four_bar &
    initial_static = no
