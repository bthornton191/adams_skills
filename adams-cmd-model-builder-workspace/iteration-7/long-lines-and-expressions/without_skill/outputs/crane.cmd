! ============================================================
! Crane Model -- Adams CMD script
!
! Three rigid parts: tower, boom, payload
! Revolute joints at tower base and tower top,
! spherical at boom tip
! Single-component force: STEP5 ramps, VZ damping, IMPACT floor
! ============================================================

! --- 1. Model and units ---
model create model_name = crane

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity ---
force create body gravitational &
    gravity_field_name  = .crane.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground marker ---
marker create &
    marker_name = .crane.ground.origin &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Tower part (5 kg, CM at global 0, 0, 500) ---
part create rigid_body name_and_position &
    part_name   = .crane.tower &
    location    = 0.0, 0.0, 500.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .crane.tower.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .crane.tower &
    mass                  = 5.0 &
    ixx                   = 10000.0 &
    iyy                   = 10000.0 &
    izz                   = 500.0 &
    center_of_mass_marker = .crane.tower.cm

! --- 5. Boom part (3 kg, CM at global 400, 0, 1000) ---
part create rigid_body name_and_position &
    part_name   = .crane.boom &
    location    = 400.0, 0.0, 1000.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .crane.boom.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .crane.boom &
    mass                  = 3.0 &
    ixx                   = 8000.0 &
    iyy                   = 8000.0 &
    izz                   = 300.0 &
    center_of_mass_marker = .crane.boom.cm

! --- 6. Payload part (10 kg, CM at global 800, 0, 800) ---
part create rigid_body name_and_position &
    part_name   = .crane.payload &
    location    = 800.0, 0.0, 800.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .crane.payload.cm &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name             = .crane.payload &
    mass                  = 10.0 &
    ixx                   = 100.0 &
    iyy                   = 100.0 &
    izz                   = 100.0 &
    center_of_mass_marker = .crane.payload.cm

! --- 7. Tower markers ---
! mkr_base: global (0,0,0) => local (0,0,-500) in tower frame
marker create &
    marker_name = .crane.tower.mkr_base &
    location    = 0.0, 0.0, -500.0 &
    orientation = 0.0D, 0.0D, 0.0D

! mkr_top: global (0,0,1000) => local (0,0,+500)
marker create &
    marker_name = .crane.tower.mkr_top &
    location    = 0.0, 0.0, 500.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 8. Boom markers ---
! mkr_tower_conn: at global (0,0,1000) => local (-400,0,0)
marker create &
    marker_name = .crane.boom.mkr_tower_conn &
    location    = -400.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Geometry marker: z along global +X for boom cylinder
! Euler 313 90D,90D,0D maps local-z to global +X
marker create &
    marker_name = .crane.boom.mkr_geom &
    location    = -200.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! mkr_boom_tip: local {200,0,0} from boom CM via eval+loc_global
! z-axis toward payload CM via eval+ori_along_axis
! (eval must stay on one line -- no & inside parentheses)
marker create &
    marker_name = .crane.boom.mkr_boom_tip &
    location = (eval(loc_global({200, 0, 0}, .crane.boom.cm))) &
    orientation = (eval(ori_along_axis(.crane.boom.cm, .crane.payload.cm, "z")))

! --- 9. Payload markers ---
! mkr_payload_hang: {0,0,150} from boom tip expressed in
! ground frame via eval+loc_relative_to
! z-axis toward payload CM via eval+ori_along_axis
! (eval must stay on one line -- no & inside parentheses)
marker create &
    marker_name = .crane.payload.mkr_payload_hang &
    location = (eval(loc_relative_to({0, 0, 150}, .crane.boom.mkr_boom_tip, .crane.ground.origin))) &
    orientation = (eval(ori_along_axis(.crane.boom.mkr_boom_tip, .crane.payload.cm, "z")))

! --- 10. Geometry ---
! Cylinder on tower (base to top, length 1000 mm, radius 40)
geometry create shape cylinder &
    cylinder_name = .crane.tower.cyl_body &
    center_marker = .crane.tower.mkr_base &
    angle_extent  = 360.0D &
    length        = 1000.0 &
    radius        = 40.0

! Cylinder on boom (length 400 mm, radius 25)
geometry create shape cylinder &
    cylinder_name = .crane.boom.cyl_body &
    center_marker = .crane.boom.mkr_geom &
    angle_extent  = 360.0D &
    length        = 400.0 &
    radius        = 25.0

! Ellipsoid on payload (50 mm semi-axes)
geometry create shape ellipsoid &
    ellipsoid_name = .crane.payload.ellip_body &
    center_marker  = .crane.payload.cm &
    x_scale_factor = 50.0 &
    y_scale_factor = 50.0 &
    z_scale_factor = 50.0

! --- 11. Joints ---
! Revolute: tower to ground at tower base (rotation about Z)
constraint create joint revolute &
    joint_name    = .crane.jnt_tower_ground &
    i_marker_name = .crane.tower.mkr_base &
    j_marker_name = .crane.ground.origin

! Revolute: boom to tower at tower top
constraint create joint revolute &
    joint_name    = .crane.jnt_boom_tower &
    i_marker_name = .crane.boom.mkr_tower_conn &
    j_marker_name = .crane.tower.mkr_top

! Spherical: payload to boom at boom tip
constraint create joint spherical &
    joint_name    = .crane.jnt_payload_boom &
    i_marker_name = .crane.payload.mkr_payload_hang &
    j_marker_name = .crane.boom.mkr_boom_tip

! --- 12. Force on payload ---
! FUNCTION split as comma-separated quoted strings;
! no & continuation inside double-quoted expressions
force create direct single_component_force &
    single_component_force_name = .crane.frc_payload &
    i_marker_name               = .crane.payload.cm &
    action_only                 = on &
    function = "STEP5(TIME, 0.0, 0.0, 0.5, -500.0)", &
               " + STEP5(TIME, 1.0, 0.0, 1.5, 500.0)", &
               " - 2.0 * VZ(.crane.payload.cm,", &
               " .crane.ground.origin, .crane.ground.origin,", &
               " .crane.ground.origin)", &
               " + IMPACT(DZ(.crane.payload.cm,", &
               " .crane.ground.origin, .crane.ground.origin),", &
               " VZ(.crane.payload.cm, .crane.ground.origin,", &
               " .crane.ground.origin, .crane.ground.origin),", &
               " 0.0, 1.0E5, 1.5, 50.0, 0.1)"

! --- 13. Simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 3.0 &
    number_of_steps = 3000 &
    model_name      = .crane &
    initial_static  = no
