model create model_name = geom_test

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

part create rigid_body name_and_position &
    part_name = .geom_test.block &
    location  = 0.0, 0.0, 0.0

part modify rigid_body mass_properties &
    part_name = .geom_test.block &
    mass      = 1.0 &
    ixx       = 100.0 &
    iyy       = 100.0 &
    izz       = 100.0

marker create &
    marker_name = .geom_test.block.geom_mkr &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .geom_test.block.geom_mkr2 &
    location    = 50.0, 0.0, 0.0

! Test 1: cylinder without part_name
geometry create shape cylinder &
    cylinder_name = .geom_test.block.cyl1 &
    center_marker = .geom_test.block.geom_mkr &
    length        = 50.0 &
    radius        = 10.0 &
    angle_extent  = 360.0D

! Test 2: ellipsoid without part_name
geometry create shape ellipsoid &
    ellipsoid_name = .geom_test.block.ellips1 &
    center_marker  = .geom_test.block.geom_mkr &
    x_scale_factor = 10.0 &
    y_scale_factor = 10.0 &
    z_scale_factor = 10.0

! Test 3: box without part_name (EXPECTED FAIL - test replacement)
geometry create shape frustum &
    frustum_name  = .geom_test.block.frus1 &
    center_marker = .geom_test.block.geom_mkr &
    length        = 30.0 &
    bottom_radius = 15.0 &
    top_radius    = 10.0 &
    angle_extent  = 360.0D

! Test 4: link with i_marker / j_marker (no _name suffix)
geometry create shape link &
    link_name = .geom_test.block.link1 &
    i_marker  = .geom_test.block.geom_mkr &
    j_marker  = .geom_test.block.geom_mkr2 &
    width     = 10.0 &
    depth     = 5.0

