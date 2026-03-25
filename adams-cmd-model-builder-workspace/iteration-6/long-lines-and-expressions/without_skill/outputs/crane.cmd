!
! ===================================================================
! Adams CMD Script - Crane Model
! Three rigid parts: tower, boom, payload
! Revolute + spherical joints, single-component force, geometry
! ===================================================================
!
defaults model &
   model_name = crane

model create &
   model_name = .crane

defaults units &
   length = mm &
   mass = kg &
   time = second &
   force = newton

! ===================================================================
! GROUND part markers
! ===================================================================
!
marker create &
   marker_name = .crane.ground.origin &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

marker create &
   marker_name = .crane.ground.mkr_jnt_tower &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! ===================================================================
! PART: tower   (5 kg, Ixx=Iyy=10000, Izz=500 kg*mm^2)
!               CM at 0, 0, 500
! ===================================================================
!
part create rigid_body name_and_position &
   part_name = .crane.tower &
   adams_id = 2 &
   location = 0.0, 0.0, 500.0 &
   orientation = 0.0d, 0.0d, 0.0d

marker create &
   marker_name = .crane.tower.cm &
   location = 0.0, 0.0, 500.0 &
   orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties &
   part_name = .crane.tower &
   mass = 5.0 &
   center_of_mass_marker = .crane.tower.cm &
   ixx = 1.0E+04 &
   iyy = 1.0E+04 &
   izz = 500.0

! Tower base marker (revolute with ground, rotation about Z)
marker create &
   marker_name = .crane.tower.mkr_tower_base &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0d, 0.0d, 0.0d

! Tower top marker (revolute with boom, rotation about Y for luffing)
marker create &
   marker_name = .crane.tower.mkr_tower_top &
   location = 0.0, 0.0, 1000.0 &
   orientation = 0.0d, -90.0d, 0.0d

! ===================================================================
! PART: boom    (3 kg, Ixx=Iyy=8000, Izz=300 kg*mm^2)
!               CM at 400, 0, 1000
! ===================================================================
!
part create rigid_body name_and_position &
   part_name = .crane.boom &
   adams_id = 3 &
   location = 400.0, 0.0, 1000.0 &
   orientation = 0.0d, 0.0d, 0.0d

marker create &
   marker_name = .crane.boom.cm &
   location = 400.0, 0.0, 1000.0 &
   orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties &
   part_name = .crane.boom &
   mass = 3.0 &
   center_of_mass_marker = .crane.boom.cm &
   ixx = 8000.0 &
   iyy = 8000.0 &
   izz = 300.0

! Boom-side joint marker for boom-tower revolute (z along Y)
marker create &
   marker_name = .crane.boom.mkr_jnt_tower &
   location = 0.0, 0.0, 1000.0 &
   orientation = 0.0d, -90.0d, 0.0d

! ===================================================================
! PART: payload (10 kg, Ixx=Iyy=Izz=100 kg*mm^2)
!               CM at 800, 0, 800
! ===================================================================
!
part create rigid_body name_and_position &
   part_name = .crane.payload &
   adams_id = 4 &
   location = 800.0, 0.0, 800.0 &
   orientation = 0.0d, 0.0d, 0.0d

marker create &
   marker_name = .crane.payload.cm &
   location = 800.0, 0.0, 800.0 &
   orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties &
   part_name = .crane.payload &
   mass = 10.0 &
   center_of_mass_marker = .crane.payload.cm &
   ixx = 100.0 &
   iyy = 100.0 &
   izz = 100.0

! ===================================================================
! Boom eval markers (loc_global + ori_along_axis)
! ===================================================================
!
! mkr_boom_base at local {-200, 0, 0} from boom CM
marker create &
   marker_name = .crane.boom.mkr_boom_base &
   location = (eval(loc_global({-200, 0, 0}, .crane.boom.cm))) &
   orientation = 0.0d, 0.0d, 0.0d

! mkr_boom_tip at local {200, 0, 0} from boom CM
marker create &
   marker_name = .crane.boom.mkr_boom_tip &
   location = (eval(loc_global({200, 0, 0}, .crane.boom.cm)))

! Orient mkr_boom_tip z-axis toward payload CM
marker modify &
   marker_name = .crane.boom.mkr_boom_tip &
   orientation = &
   (eval(ori_along_axis(.crane.payload.cm, .crane.boom.mkr_boom_tip, "z")))

! ===================================================================
! Payload joint marker at boom-tip location for spherical joint
! ===================================================================
!
marker create &
   marker_name = .crane.payload.mkr_jnt_boom &
   location = 600.0, 0.0, 1000.0 &
   orientation = 0.0d, 0.0d, 0.0d

! ===================================================================
! JOINTS
! ===================================================================
!
! Revolute: tower to ground at tower base (rotation about Z)
constraint create joint revolute &
   joint_name = .crane.jnt_tower_ground &
   adams_id = 1 &
   i_marker_name = .crane.tower.mkr_tower_base &
   j_marker_name = .crane.ground.mkr_jnt_tower

! Revolute: boom to tower at tower top (rotation about Y)
constraint create joint revolute &
   joint_name = .crane.jnt_boom_tower &
   adams_id = 2 &
   i_marker_name = .crane.boom.mkr_jnt_tower &
   j_marker_name = .crane.tower.mkr_tower_top

! Spherical: payload to boom at boom tip
constraint create joint spherical &
   joint_name = .crane.jnt_payload_boom &
   adams_id = 3 &
   i_marker_name = .crane.payload.mkr_jnt_boom &
   j_marker_name = .crane.boom.mkr_boom_tip

! ===================================================================
! FORCE: single-component translational force on payload
! Expression split across continuation lines.
! ===================================================================
!
force create single_component_force &
   single_component_force_name = .crane.frc_payload &
   adams_id = 1 &
   type_of_freedom = translational &
   i_marker_name = .crane.payload.cm &
   j_marker_name = .crane.ground.origin &
   action_only = on &
   function = "STEP5(TIME,0,0,0.5,-500) + &
   STEP5(TIME,1,0,1.5,500) - &
   2.0*VZ(.crane.payload.cm,.crane.ground.origin,.crane.ground.origin,.crane.ground.origin)"

! ===================================================================
! GEOMETRY
! ===================================================================
!
! Cylinder on tower (base to top, length 1000 mm)
geometry create shape cylinder &
   cylinder_name = .crane.tower.geom_cyl &
   adams_id = 1 &
   center_marker = .crane.tower.mkr_tower_base &
   angle_extent = 360.0 &
   length = 1000.0 &
   radius = 50.0 &
   side_count_for_body = 20 &
   segment_count_for_ends = 20

! Geometry marker for boom cylinder (z along boom axis = global +X)
! Euler 313: 90d, 90d, 0d  ->  z maps to global X
marker create &
   marker_name = .crane.boom.mkr_geom_cyl &
   location = (eval(loc_global({-200, 0, 0}, .crane.boom.cm))) &
   orientation = 90.0d, 90.0d, 0.0d

! Cylinder on boom (length 400 mm)
geometry create shape cylinder &
   cylinder_name = .crane.boom.geom_cyl &
   adams_id = 2 &
   center_marker = .crane.boom.mkr_geom_cyl &
   angle_extent = 360.0 &
   length = 400.0 &
   radius = 30.0 &
   side_count_for_body = 20 &
   segment_count_for_ends = 20

! Ellipsoid on payload (100 mm semi-axes)
geometry create shape ellipsoid &
   ellipsoid_name = .crane.payload.geom_ell &
   adams_id = 3 &
   center_marker = .crane.payload.cm &
   x_scale_factor = 100.0 &
   y_scale_factor = 100.0 &
   z_scale_factor = 100.0

! ===================================================================
! SIMULATION  -  3 s, 3000 steps
! ===================================================================
!
simulation single_run transient &
   end_time = 3.0 &
   number_of_steps = 3000
