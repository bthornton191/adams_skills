! Test point mass creation syntax
model create model_name = test_pm

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! Test: point_mass with no sub-command, just call it (auto-name)
part create point_mass name_and_position &
    point_mass_name = .test_pm.ball1 &
    location        = 50.0, 0.0, 0.0

part modify point_mass mass_properties &
    point_mass_name = .test_pm.ball1 &
    mass            = 0.25

marker create &
    marker_name = .test_pm.ball1.ref &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! End
