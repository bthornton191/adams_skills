!----------------------------------------------------------------------
! Four-Bar Linkage Mechanism - Adams View CMD Script
!
! Links:
!   Crank  : 100 mm, 0.5 kg  (A to B)
!   Coupler: 250 mm, 0.5 kg  (B to C)
!   Rocker : 200 mm, 0.5 kg  (D to C)
!   Ground : 300 mm          (A to D)
!
! Initial Configuration (crank horizontal):
!   A = (  0.00,   0.00, 0) - crank / ground pivot (origin)
!   B = (100.00,   0.00, 0) - crank tip / coupler pin
!   C = (256.25, 195.16, 0) - coupler / rocker pin  [closure eqns]
!   D = (300.00,   0.00, 0) - rocker / ground pivot
!
! Grashof check: 100 + 300 = 400 <= 250 + 200 = 450  (crank-rocker)
!
! Input Motion : 360 deg/s constant crank speed
! Simulation   : 2.0 s dynamic, 0.001 s output step
!----------------------------------------------------------------------

model create &
    model_name = four_bar

defaults units &
    length = mm &
    angle = deg &
    force = newton &
    mass = kg &
    time = sec

!--- Gravity (-Y direction, mm/s^2) ---
force create body gravitational &
    field_name = .four_bar.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

!======================================================================
! GROUND REFERENCE MARKERS
!======================================================================

! Crank ground pivot at origin (A)
marker create &
    marker_name = .four_bar.ground.MAR_A &
    location = 0.0, 0.0, 0.0

! Rocker ground pivot 300 mm to the right (D)
marker create &
    marker_name = .four_bar.ground.MAR_D &
    location = 300.0, 0.0, 0.0

!======================================================================
! CRANK  (A -> B)
!   Length = 100 mm
!   Mass   = 0.5 kg
!   CM     = midpoint (50, 0, 0)
!   Izz    = m*L^2/12 = 0.5*100^2/12 = 416.67 kg*mm^2
!======================================================================

part create rigid_body name_and_position &
    part_name = .four_bar.crank &
    location = 0.0, 0.0, 0.0

marker create &
    marker_name = .four_bar.crank.cm &
    location = 50.0, 0.0, 0.0

part modify rigid_body mass_properties &
    part_name = .four_bar.crank &
    mass = 0.5 &
    center_of_mass_marker = .four_bar.crank.cm &
    ixx = 0.001 &
    iyy = 416.67 &
    izz = 416.67 &
    ixy = 0.0 &
    izx = 0.0 &
    iyz = 0.0

! Pivot marker at A (coincides with ground.MAR_A)
marker create &
    marker_name = .four_bar.crank.MAR_A &
    location = 0.0, 0.0, 0.0

! Tip marker at B
marker create &
    marker_name = .four_bar.crank.MAR_B &
    location = 100.0, 0.0, 0.0

!======================================================================
! COUPLER  (B -> C)
!   Length = 250 mm
!   Mass   = 0.5 kg
!   CM     = midpoint (178.125, 97.58, 0)
!   Izz    = m*L^2/12 = 0.5*250^2/12 = 2604.17 kg*mm^2
!======================================================================

part create rigid_body name_and_position &
    part_name = .four_bar.coupler &
    location = 0.0, 0.0, 0.0

marker create &
    marker_name = .four_bar.coupler.cm &
    location = 178.125, 97.58, 0.0

part modify rigid_body mass_properties &
    part_name = .four_bar.coupler &
    mass = 0.5 &
    center_of_mass_marker = .four_bar.coupler.cm &
    ixx = 0.001 &
    iyy = 2604.17 &
    izz = 2604.17 &
    ixy = 0.0 &
    izx = 0.0 &
    iyz = 0.0

! Pin marker at B (matches crank.MAR_B)
marker create &
    marker_name = .four_bar.coupler.MAR_B &
    location = 100.0, 0.0, 0.0

! Pin marker at C
marker create &
    marker_name = .four_bar.coupler.MAR_C &
    location = 256.25, 195.16, 0.0

!======================================================================
! ROCKER  (D -> C)
!   Length = 200 mm
!   Mass   = 0.5 kg
!   CM     = midpoint (278.125, 97.58, 0)
!   Izz    = m*L^2/12 = 0.5*200^2/12 = 1666.67 kg*mm^2
!======================================================================

part create rigid_body name_and_position &
    part_name = .four_bar.rocker &
    location = 0.0, 0.0, 0.0

marker create &
    marker_name = .four_bar.rocker.cm &
    location = 278.125, 97.58, 0.0

part modify rigid_body mass_properties &
    part_name = .four_bar.rocker &
    mass = 0.5 &
    center_of_mass_marker = .four_bar.rocker.cm &
    ixx = 0.001 &
    iyy = 1666.67 &
    izz = 1666.67 &
    ixy = 0.0 &
    izx = 0.0 &
    iyz = 0.0

! Ground pivot marker at D (matches ground.MAR_D)
marker create &
    marker_name = .four_bar.rocker.MAR_D &
    location = 300.0, 0.0, 0.0

! Coupler pin marker at C (matches coupler.MAR_C)
marker create &
    marker_name = .four_bar.rocker.MAR_C &
    location = 256.25, 195.16, 0.0

!======================================================================
! REVOLUTE JOINTS
!======================================================================

! Joint A: ground <-> crank  (at origin)
constraint create joint revolute &
    joint_name = .four_bar.JNT_A &
    i_marker_name = .four_bar.crank.MAR_A &
    j_marker_name = .four_bar.ground.MAR_A

! Joint B: crank <-> coupler  (at crank tip)
constraint create joint revolute &
    joint_name = .four_bar.JNT_B &
    i_marker_name = .four_bar.crank.MAR_B &
    j_marker_name = .four_bar.coupler.MAR_B

! Joint C: coupler <-> rocker  (floating pin)
constraint create joint revolute &
    joint_name = .four_bar.JNT_C &
    i_marker_name = .four_bar.coupler.MAR_C &
    j_marker_name = .four_bar.rocker.MAR_C

! Joint D: rocker <-> ground  (at 300 mm)
constraint create joint revolute &
    joint_name = .four_bar.JNT_D &
    i_marker_name = .four_bar.rocker.MAR_D &
    j_marker_name = .four_bar.ground.MAR_D

!======================================================================
! CRANK INPUT MOTION
!   360 deg/s constant -- expressed as displacement = 360d * time
!======================================================================

motion create &
    motion_name = .four_bar.MOT_crank &
    joint_name = .four_bar.JNT_A &
    type_of_freedom = rotational &
    function = "360.0d * time"

!======================================================================
! DYNAMIC SIMULATION
!   Duration : 2.0 s
!   Step size: 0.001 s  (2000 output steps)
!======================================================================

simulation single &
    sim_name = .four_bar.SIM_4bar &
    initial_static = no &
    end_time = 2.0 &
    step_size = 0.001 &
    type = dynamic
