! ============================================================
! Crane Model — Adams CMD script
!
! Three rigid parts: tower, boom, payload
!   tower   CM at (0, 0, 500)     5 kg
!   boom    CM at (400, 0, 1000)  3 kg
!   payload CM at (800, 0, 800)  10 kg
!
! Joints:
!   revolute  : tower base <-> ground origin
!   revolute  : boom.mkr_tower_conn <-> tower.mkr_top
!   spherical : payload.mkr_payload_hang <-> boom.mkr_boom_tip
!
! Special markers (eval lines may exceed 80 chars — Rule 16):
!   .crane.boom.mkr_boom_tip        — loc_global + ori_along_axis
!   .crane.payload.mkr_payload_hang — loc_relative_to + ori_along_axis
!
! All part origins placed at CM location.
! .cm markers are created explicitly before mass_properties.
! ============================================================

! --- 1. Model and units ---
model create model_name = crane

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity (Z is vertical, ground at Z = 0) ---
force create body gravitational &
    gravity_field_name  = .crane.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = 0.0 &
    z_component_gravity = -9806.65

! --- 3. Ground reference marker ---
marker create &
    marker_name = .crane.ground.origin &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Parts — all created first so eval markers can reference .cm ---

! Tower: part origin = CM at global (0, 0, 500)
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

! Boom: part origin = CM at global (400, 0, 1000)
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

! Payload: part origin = CM at global (800, 0, 800)
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

! --- 5. Additional markers ---

! Tower base: local (0, 0, -500) = global (0, 0, 0)
marker create &
    marker_name = .crane.tower.mkr_base &
    location    = 0.0, 0.0, -500.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tower top: local (0, 0, 500) = global (0, 0, 1000)
marker create &
    marker_name = .crane.tower.mkr_top &
    location    = 0.0, 0.0, 500.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Boom-tower connection: local (-400, 0, 0) = global (0, 0, 1000)
marker create &
    marker_name = .crane.boom.mkr_tower_conn &
    location    = -400.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Boom tip: local {200, 0, 0} from boom CM = global (600, 0, 1000)
! z-axis oriented from .crane.boom.cm toward .crane.payload.cm
! Rule 16: eval expression cannot span lines; line may exceed 80 chars.
marker create &
    marker_name = .crane.boom.mkr_boom_tip &
    location    = (eval(loc_global({200, 0, 0}, .crane.boom.cm))) &
    orientation = (eval(ori_along_axis(.crane.boom.cm, .crane.payload.cm, "z")))

! Geometry marker at boom left end; z-axis along global +X
! orientation 90D, 90D, 0D aligns local z with global +X
marker create &
    marker_name = .crane.boom.mkr_geom &
    location    = -400.0, 0.0, 0.0 &
    orientation = 90.0D, 90.0D, 0.0D

! Payload hang marker: {0, 0, 150} offset from mkr_boom_tip in
! mkr_boom_tip local frame. z-axis from mkr_boom_tip to payload.cm.
! Rule 16: eval expression cannot span lines; line may exceed 80 chars.
marker create &
    marker_name = .crane.payload.mkr_payload_hang &
    location    = (eval(loc_relative_to({0, 0, 150}, .crane.boom.mkr_boom_tip))) &
    orientation = (eval(ori_along_axis(.crane.boom.mkr_boom_tip, .crane.payload.cm, "z")))

! --- 6. Geometry ---

! Tower cylinder: from base marker along Z, length 1000 mm, r = 40 mm
geometry create shape cylinder &
    cylinder_name = .crane.tower.cyl_body &
    center_marker = .crane.tower.mkr_base &
    angle_extent  = 360.0D &
    length        = 1000.0 &
    radius        = 40.0

! Boom cylinder: from mkr_geom along +X, length 600 mm, r = 25 mm
geometry create shape cylinder &
    cylinder_name = .crane.boom.cyl_body &
    center_marker = .crane.boom.mkr_geom &
    angle_extent  = 360.0D &
    length        = 600.0 &
    radius        = 25.0

! Payload ellipsoid at CM, semi-axes 50 mm
geometry create shape ellipsoid &
    ellipsoid_name = .crane.payload.ellip_body &
    center_marker  = .crane.payload.cm &
    x_scale_factor = 50.0 &
    y_scale_factor = 50.0 &
    z_scale_factor = 50.0

! --- 7. Constraints ---

! Revolute: tower rotates about Z at tower base / ground origin
constraint create joint revolute &
    joint_name    = .crane.jnt_tower_ground &
    i_marker_name = .crane.tower.mkr_base &
    j_marker_name = .crane.ground.origin

! Revolute: boom to tower at tower top
constraint create joint revolute &
    joint_name    = .crane.jnt_boom_tower &
    i_marker_name = .crane.boom.mkr_tower_conn &
    j_marker_name = .crane.tower.mkr_top

! Spherical: payload to boom tip
constraint create joint spherical &
    joint_name    = .crane.jnt_payload_boom &
    i_marker_name = .crane.payload.mkr_payload_hang &
    j_marker_name = .crane.boom.mkr_boom_tip

! --- 8. Single-component force on payload ---
! STEP5 push-down (0.0-0.5 s), STEP5 push-up (1.0-1.5 s),
! VZ velocity damping, IMPACT ground contact at Z = 0.
! FUNCTION= split into comma-separated quoted strings (Rule 16).
force create direct single_component_force &
    single_component_force_name = .crane.frc_payload &
    i_marker_name               = .crane.payload.cm &
    j_marker_name               = .crane.ground.origin &
    action_only                 = on &
    function = "STEP5(TIME, 0.0, 0.0, 0.5, -500.0)", &
               " + STEP5(TIME, 1.0, 0.0, 1.5, 500.0)", &
               " - 2.0 * VZ(.crane.payload.cm,", &
               " .crane.ground.origin,", &
               " .crane.ground.origin,", &
               " .crane.ground.origin)", &
               " + IMPACT(DZ(.crane.payload.cm,", &
               " .crane.ground.origin,", &
               " .crane.ground.origin),", &
               " VZ(.crane.payload.cm,", &
               " .crane.ground.origin,", &
               " .crane.ground.origin,", &
               " .crane.ground.origin),", &
               " 0.0, 1.0E5, 1.5, 50.0, 0.1)"

! --- 9. Simulation: 3 seconds, 3000 steps ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 3.0 &
    number_of_steps = 3000 &
    model_name      = .crane &
    initial_static  = no
