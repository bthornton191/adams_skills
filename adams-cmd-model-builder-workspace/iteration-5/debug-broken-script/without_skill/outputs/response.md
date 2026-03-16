# Adams CMD Pendulum Script — Bug Report

Six bugs were found in the original script. Each is described below with the faulty line, diagnosis, and fix applied.

---

## Bug 1 — Invalid keyword abbreviation in `part create` (line: `part cre rig nam = ...`)

**Faulty line:**
```cmd
part cre rig nam = .pendulum.link &
```

**Problem:**  
`nam` is not a valid or unambiguous abbreviation for the `name` keyword in Adams CMD. Additionally, the sub-keyword `rig` for `rigid_body` is unnecessarily abbreviated in a position where the full form is unambiguous. Using truncated keywords here risks a parse error or silent misinterpretation.

**Fix:**  
Use the full keyword `name` (and `rigid_body` for clarity):
```cmd
part create rigid_body name = .pendulum.link &
```

---

## Bug 2 — Spurious `adams_id` parameter in `mass_properties` command

**Faulty line:**
```cmd
part create rigid_body mass_properties &
    part_name = .pendulum.link &
    adams_id = 5 &
    ...
```

**Problem:**  
The `mass_properties` sub-command of `part create rigid_body` does not accept an `adams_id` parameter. An `adams_id` can be assigned when constructing geometry (e.g., `part create rigid_body`), but it is not valid in the mass-properties context and will cause an error.

**Fix:**  
Remove the `adams_id = 5` line entirely.

---

## Bug 3 — Missing leading dot in `center_of_mass_marker` path

**Faulty line:**
```cmd
    center_of_mass_marker = pendulum.link.cm
```

**Problem:**  
All Adams object references must be given as fully-qualified paths beginning with a dot (`.`). The missing leading dot means Adams cannot resolve the marker name and the command will fail with an "object not found" error.

**Fix:**
```cmd
    center_of_mass_marker = .pendulum.link.cm
```

---

## Bug 4 — Superfluous zero-stiffness, zero-damping spring-damper force element

**Faulty block:**
```cmd
force create element_like spring_damper &
    spring_damper_name = .pendulum.gravity_spring &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr &
    stiffness = 0.0 &
    damping = 0.0 &
    length = 200.0
```

**Problem:**  
A spring-damper with `stiffness = 0.0` and `damping = 0.0` produces zero force regardless of displacement or velocity. This element contributes nothing to the simulation and is almost certainly a leftover artifact or a mistaken attempt to "model gravity" via a force element (gravity is correctly handled by the `gravity create` command that follows). Leaving it in adds unnecessary complexity and could confuse future readers.

**Fix:**  
Remove the entire `force create element_like spring_damper` block.

---

## Bug 5 — Invalid `direction = gravity` parameter in `gravity create`

**Faulty lines:**
```cmd
gravity create &
    model_name = .pendulum &
    direction = gravity &
    x_component_gravity = 0.0 &
    ...
```

**Problem:**  
`direction = gravity` is not a valid parameter for the `gravity create` command. The gravity direction in Adams is defined entirely by the `x_component_gravity`, `y_component_gravity`, and `z_component_gravity` values. The spurious `direction` keyword will cause a parse error.

**Fix:**  
Remove the `direction = gravity` line:
```cmd
gravity create &
    model_name = .pendulum &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0
```

---

## Bug 6 — Incomplete simulation command: missing `single_run` keyword

**Faulty line:**
```cmd
sim trans end_time = 2.0 step_size = 0.001
```

**Problem:**  
The Adams/View simulation command hierarchy is `simulation → single_run → transient`. The `single_run` level is required and cannot be skipped. `sim trans` is interpreted as `simulation transient`, which is not a valid command path and will fail at parse time.

**Fix:**
```cmd
simulation single_run transient &
    end_time = 2.0 &
    step_size = 0.001
```

---

## Summary Table

| # | Location | Bug Type | Description |
|---|----------|----------|-------------|
| 1 | `part cre rig nam = ...` | Syntax | `nam` is not a valid abbreviation for `name` |
| 2 | `adams_id = 5` in mass_properties | Invalid parameter | `adams_id` not accepted by the `mass_properties` sub-command |
| 3 | `center_of_mass_marker = pendulum.link.cm` | Missing dot | Fully-qualified path requires leading `.` |
| 4 | `force create element_like spring_damper` with zero stiffness/damping | Logic/dead code | Zero-valued spring-damper is a no-op; should be removed |
| 5 | `direction = gravity` in `gravity create` | Invalid parameter | `direction` is not a recognised parameter here |
| 6 | `sim trans end_time = ...` | Missing keyword | `single_run` is required between `simulation` and `transient` |
