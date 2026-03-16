# Debug Report: Adams CMD Pendulum Script

---

## Summary

14 bugs were found and fixed across the model creation, unit definitions, mass properties, spring-damper force, gravity, and simulation commands.

---

## Bug List

### Bug 1 — Abbreviated `model` command
**Original:**
```cmd
model cre pendulum
```
**Fixed:**
```cmd
model create model_name = pendulum
```
**Explanation:** `cre` is an abbreviation of `create`. Adams CMD scripts must spell out all keywords in full — abbreviations work interactively but fail in scripts and macros. The `model_name =` keyword argument is also required.

---

### Bug 2 — Invalid unit name: `millimeter`
**Original:**
```cmd
length = millimeter
```
**Fixed:**
```cmd
length = mm
```
**Explanation:** The valid Adams unit token for millimetres is `mm`, not `millimeter`. Using a full word that Adams does not recognise leaves the length unit undefined.

---

### Bug 3 — Invalid unit name: `second`
**Original:**
```cmd
time = second
```
**Fixed:**
```cmd
time = sec
```
**Explanation:** The valid token is `sec`. Adams does not recognise `second` and will leave the time unit at its default.

---

### Bug 4 — Invalid unit name: `kilogram`
**Original:**
```cmd
mass = kilogram
```
**Fixed:**
```cmd
mass = kg
```
**Explanation:** The valid token is `kg`. `kilogram` is not a recognised Adams unit token.

---

### Bug 5 — Abbreviated `part create` sub-command
**Original:**
```cmd
part cre rig nam = .pendulum.link &
```
**Fixed:**
```cmd
part create rigid_body name_and_position &
    part_name = .pendulum.link &
```
**Explanation:** `cre`, `rig`, and `nam` are abbreviations. All keywords must be spelled out in full: `create`, `rigid_body`, `name_and_position`. The parameter keyword must also be `part_name =`, not `nam =`.

---

### Bug 6 — Incorrect part location misaligns pin marker with ground pivot
**Original:**
```cmd
location = 0.0, -100.0, 0.0
```
**Fixed:**
```cmd
location = 0.0, 0.0, 0.0
```
**Explanation:** `location` places the part's reference frame origin in global space. The pin marker is defined at local `(0, 0, 0)`, so the part's global location is exactly where the pin is. The ground pivot marker is at global `(0, 0, 0)`. If the part is placed at `(0, -100, 0)`, the pin marker lands at global `(0, -100, 0)`, which does not coincide with the ground pivot — causing an initial constraint violation on the revolute joint. The part must be placed at the pivot origin `(0, 0, 0)`; the 45° initial orientation is already set correctly by the `orientation` parameter.

---

### Bug 7 — Orientation angles missing `D` suffix
**Original:**
```cmd
orientation = 0.0, 0.0, 45.0
...
orientation = 0.0, 0.0, 0.0
```
**Fixed:**
```cmd
orientation = 0.0D, 0.0D, 45.0D
...
orientation = 0.0D, 0.0D, 0.0D
```
**Explanation:** Adams CMD orientation values should carry an explicit `D` suffix to unambiguously declare degrees. Without the suffix, Adams interprets the values according to the current angle unit setting, which may not always be degrees. The `D` suffix makes the intent explicit and portable.

---

### Bug 8 — `part create` used twice on the same part (mass properties)
**Original:**
```cmd
part create rigid_body mass_properties &
    part_name = .pendulum.link &
```
**Fixed:**
```cmd
part modify rigid_body mass_properties &
    part_name = .pendulum.link &
```
**Explanation:** Adams Core Rule: `part create` should only be called once per part (to create it with `name_and_position`). To set mass and inertia after creation, use `part modify rigid_body mass_properties`. Calling `part create` a second time on the same part name causes an error.

---

### Bug 9 — Manual `adams_id` specified
**Original:**
```cmd
adams_id = 5 &
```
**Fixed:** *(line removed)*

**Explanation:** Adams auto-assigns integer IDs to all objects. Manually supplying `adams_id` in a CMD script is error-prone — it will fail if the ID is already taken by another element. The parameter must be omitted entirely.

---

### Bug 10 — `center_of_mass_marker` passed before `.cm` exists
**Original:**
```cmd
center_of_mass_marker = pendulum.link.cm
```
**Fixed:** *(line removed)*

**Explanation:** Adams automatically creates the `.cm` marker when `part modify rigid_body mass_properties` runs. Passing `center_of_mass_marker` at that moment causes Adams to look for a marker named `cm` that has not yet been created, resulting in the error: *`No Marker was found because 'cm' does not exist`*. Additionally, the path `pendulum.link.cm` is missing its leading dot (should be `.pendulum.link.cm`). The parameter should only be used when redirecting the CM to a *different*, already-existing marker — never for the default `.cm`.

---

### Bug 11 — Wrong spring-damper keyword: `spring_damper`
**Original:**
```cmd
force create element_like spring_damper &
```
**Fixed:**
```cmd
force create element_like translational_spring_damper &
```
**Explanation:** The correct Adams element name is `translational_spring_damper`, not `spring_damper`. Using `spring_damper` causes an "unknown element type" error. (Note: `rotational_spring_damper` exists separately for torsional springs.)

---

### Bug 12 — Invalid spring free-length parameter: `length`
**Original:**
```cmd
length = 200.0
```
**Fixed:**
```cmd
displacement_at_preload = 200.0
```
**Explanation:** `translational_spring_damper` does not have a `length` parameter. The free (natural) length is specified via `displacement_at_preload` — the distance between the I and J markers at which the preload force equals zero. Using `length` will be silently ignored or cause a parameter error.

---

### Bug 13 — Wrong gravity command: `gravity create`
**Original:**
```cmd
gravity create &
    model_name = .pendulum &
    direction = gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0
```
**Fixed:**
```cmd
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0
```
**Explanation:** There is no `gravity create` command in Adams View CMD. Gravity is applied with `force create body gravitational`. Two invalid parameters were also removed: `model_name` (not a parameter of this command) and `direction = gravity` (not a valid parameter; gravity direction is specified by the x/y/z component values). The required `gravity_field_name` gives the element a named handle within the model.

---

### Bug 14 — Abbreviated and incorrect `simulation` command
**Original:**
```cmd
sim trans end_time = 2.0 step_size = 0.001
```
**Fixed:**
```cmd
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
```
**Explanation:** Four issues in one line:
1. `sim` and `trans` are abbreviations — must be `simulation` and `transient`.
2. `single_run` sub-command is required between `simulation` and `transient`.
3. `step_size` is not a valid parameter. Output frequency is controlled by `number_of_steps` (total output steps over the run). With `end_time = 2.0` and `step_size = 0.001`, the equivalent is `number_of_steps = 2000`.
4. Required parameters `type`, `model_name`, and `initial_static` were missing.

---

## Corrected Script

See `pendulum_fixed.cmd` in the same directory.
