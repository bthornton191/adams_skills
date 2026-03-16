!-----------------------------------------------------------------------
! parametric_chain.cmd
! Adams/View CMD Script
!
! Creates a chain of 8 point masses (0.25 kg each) along the X axis,
! spaced 50 mm apart.  Adjacent masses are connected by spring-dampers
! (k=100 N/mm, c=1.0 N·s/mm, free_length=50 mm).  The first mass is
! fixed to ground.  Simulates for 2 seconds.
!
! Units: mm, N, kg, s
!-----------------------------------------------------------------------

model create &
  model_name=chain_model

defaults units &
  length=mm &
  force=newton &
  mass=kg &
  time=second

!--- Ground reference marker at origin (used by the fixed joint)
marker create &
  marker_name=ground.GROUND_REF &
  location=(0.0, 0.0, 0.0) &
  orientation=(0d, 0d, 0d)

!-----------------------------------------------------------------------
! Loop 1: Create 8 point masses along the X axis, 50 mm apart
!         mass_1 at x=0, mass_2 at x=50, ..., mass_8 at x=350
!-----------------------------------------------------------------------
for variable_name=ii start_value=1 end_value=8 increment=1

  ! Compute the X position for this mass into a scratch variable
  variable create variable_name=xpos &
    real_value=(EVAL((ii - 1) * 50.0))

  ! Create the point-mass part; Adams auto-creates the .cm marker
  part create rigid_body mass_only &
    part_name=(EVAL("mass_" // RTOI(ii))) &
    mass=0.25 &
    location=(EVAL(xpos), 0.0, 0.0)

end for

!-----------------------------------------------------------------------
! Fixed joint: pin mass_1 to ground at the origin
!-----------------------------------------------------------------------
constraint create joint fixed &
  joint_name=fixed_joint &
  i_marker_name=mass_1.cm &
  j_marker_name=ground.GROUND_REF

!-----------------------------------------------------------------------
! Loop 2: Create 7 spring-dampers connecting adjacent masses
!         spring_1 connects mass_1 to mass_2, ..., spring_7 to mass_8
!-----------------------------------------------------------------------
for variable_name=ii start_value=1 end_value=7 increment=1

  force create element_like spring_damper &
    spring_damper_name=(EVAL("spring_" // RTOI(ii))) &
    i_marker_name=(EVAL("mass_" // RTOI(ii)     // ".cm")) &
    j_marker_name=(EVAL("mass_" // RTOI(ii + 1) // ".cm")) &
    stiffness=100.0 &
    damping=1.0 &
    free_length=50.0

end for

!-----------------------------------------------------------------------
! Transient simulation: 2 seconds, 200 output steps
!-----------------------------------------------------------------------
simulation single_run &
  sim_type=transient &
  end_time=2.0 &
  number_of_steps=200 &
  initial_static=no
