# Bug Analysis and Fixes

## Bugs Found

### Bug 1: Model name uses leading dot
**Line:** `model cre model_name = .pendulum`

The model name should not have a leading dot when creating it. The leading dot notation is used to reference existing objects in the Adams hierarchy, not when declaring new ones.

**Fix:** `model cre model_name = pendulum`

---

### Bug 2: Unit abbreviations are not valid Adams CMD keywords
**Line:** `defaults units length = mm mass = kg`

Adams CMD requires full unit names. `mm` and `kg` are not recognized unit identifiers. The correct names are `millimeter` and `kilogram`. Additionally, `length` and `mass` are separate parameters and the command is typically written as a single combined command using `units_name`, or each unit specified on its own line.

**Fix:**
```
defaults units &
    length = millimeter &
    mass   = kilogram
```

---

### Bug 3: Marker name missing leading dot
**Line:** `marker_name = pendulum.link.pin_mkr`

All fully qualified Adams object names must begin with a dot. Without the leading dot, Adams cannot resolve the path correctly.

**Fix:** `marker_name = .pendulum.link.pin_mkr`

---

### Bug 4: i_marker_name missing leading dot
**Line:** `i_marker_name = pendulum.link.pin_mkr`

Same issue as Bug 3 — the fully qualified name must start with a dot.

**Fix:** `i_marker_name = .pendulum.link.pin_mkr`

---

### Bug 5: Ground pin marker never created
**Line:** `j_marker_name = .pendulum.ground.pin_j_mkr`

The joint references `.pendulum.ground.pin_j_mkr` as the j-marker, but this marker is never defined anywhere in the script. A `marker create` command must be added to define this marker on the ground part before the joint is created.

**Fix:** Add the following before the constraint command:
```
marker create &
    marker_name = .pendulum.ground.pin_j_mkr &
    location    = 0.0, 0.0, 0.0
```

---

## Corrected Script

```
model create model_name = pendulum

defaults units &
    length = millimeter &
    mass   = kilogram

part create rigid_body name_and_position &
    part_name = .pendulum.link &
    location  = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
    part_name             = .pendulum.link &
    adams_id              = 3 &
    mass                  = 1.0 &
    center_of_mass_marker = .pendulum.link.cm &
    ixx                   = 3333.0 &
    iyy                   = 3333.0 &
    izz                   = 100.0

marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0

marker create &
    marker_name = .pendulum.ground.pin_j_mkr &
    location    = 0.0, 0.0, 0.0

constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pin_j_mkr
```
