! ============================================================
! Crane Model — Adams CMD script
!
! Three rigid parts: tower, boom, payload
! Revolute joints at tower base and tower top, spherical at boom tip
! Single-component force with STEP5 ramps and VZ damping on payload
!
! Model structure:
!   .crane
!   ├── ground
!   │   └── origin
!   ├── tower
!   │   ├── cm
!   │   ├── mkr_base
!   │   └── mkr_top
!   ├── boom
!   │   ├── cm
!   │   ├── mkr_boom_base    (eval + loc_global)
!   │   ├── mkr_boom_tip     (eval + loc_global + ori_along_axis)
!   │   ├── mkr_tower_conn
!   │   └── mkr_geom
!   └── payload
!       ├── cm
!       └── mkr_boom_conn
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

! --- 3. Ground markers ---
marker create &
    marker_name = .crane.ground.origin &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Create parts ---
! Tower — CM at (0, 0, 500)
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

! Boom — CM at (400, 0, 1000)
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

! Payload — CM at (800, 0, 800)
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

! --- 5. Markers on parts ---

! Tower: base (global 0,0,0) and top (global 0,0,1000)
marker create &
    marker_name = .crane.tower.mkr_base &
    location    = 0.0, 0.0, -500.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .crane.tower.mkr_top &
    location    = 0.0, 0.0, 500.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Boom: markers at local offsets from CM using eval + loc_global
! eval expressions must stay on a single line (Rule 16)
marker create &
    marker_name = .crane.boom.mkr_boom_base &
    location = (eval(loc_global({-200, 0, 0}, .crane.boom.cm)))

marker create &
    marker_name = .crane.boom.mkr_boom_tip &
    location = (eval(loc_global({200, 0, 0}, .crane.boom.cm))) &
    orientation = (eval(ori_along_axis(.crane.boom.cm, .crane.payload.cm, "z")))

! Boom: marker at tower-top connection (global 0, 0, 1000 = local -400, 0, 0)
marker create &
    marker_name = .crane.boom.mkr_tower_conn &
    location    = -400.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Boom: geometry center marker with z-axis along boom (+x global)
! orientation = 90D, 90D, 0D maps local z to global +x
marker create &
    marker_name = .crane.boom.mkr_geom &
    location    = -200.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Payload: marker at boom-tip location (global 600, 0, 1000 = local -200, 0, 200)
marker create &
    marker_name = .crane.payload.mkr_boom_conn &
    location    = -200.0, 0.0, 200.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Geometry ---
! Cylinder on tower: base to top, length = 1000 mm along z
geometry create shape cylinder &
    cylinder_name = .crane.tower.cyl_body &
    center_marker = .crane.tower.mkr_base &
    angle_extent  = 360.0D &
    length        = 1000.0 &
    radius        = 40.0

! Cylinder on boom: along boom axis, length = 400 mm
geometry create shape cylinder &
    cylinder_name = .crane.boom.cyl_body &
    center_marker = .crane.boom.mkr_geom &
    angle_extent  = 360.0D &
    length        = 400.0 &
    radius        = 25.0

! Ellipsoid on payload
geometry create shape ellipsoid &
    ellipsoid_name = .crane.payload.ellip_body &
    center_marker  = .crane.payload.cm &
    x_scale_factor = 50.0 &
    y_scale_factor = 50.0 &
    z_scale_factor = 50.0

! --- 7. Constraints ---
! Revolute: tower to ground at tower base
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
    i_marker_name = .crane.payload.mkr_boom_conn &
    j_marker_name = .crane.boom.mkr_boom_tip

! --- 8. Forces ---
! Single-component force on payload with STEP5 ramps and VZ damping
! Function split across lines using comma-separated quoted strings
force create direct single_component_force &
    single_component_force_name = .crane.force_payload &
    i_marker_name               = .crane.payload.cm &
    action_only                 = on &
    function = "STEP5(TIME, 0.0, 0.0, 0.5, -500.0)", &
               " + STEP5(TIME, 1.0, 0.0, 1.5, 500.0)", &
               " - 2.0 * VZ(.crane.payload.cm, .crane.ground.origin, .crane.ground.origin, .crane.ground.origin)"

! --- 9. Simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 3.0 &
    number_of_steps = 3000 &
    model_name      = .crane &
    initial_static  = no
