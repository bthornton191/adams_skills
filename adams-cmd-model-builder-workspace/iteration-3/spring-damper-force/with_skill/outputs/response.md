# Creating a Spring-Damper Force in Adams CMD

Use the `force create element_like spring_damper` command. You need two markers — one on each part — that define the line of action for the spring-damper.

## Steps

1. Create the two parts (if not already created).
2. Create an `i_marker` on the first part and a `j_marker` on the second part (or ground), aligned along the spring's axis.
3. Create the spring-damper referencing those markers.

## Example CMD Script

```cmd
! --- Define parts ---
part create rigid_body name_and_position &
    part_name = .model.body_1

part create rigid_body name_and_position &
    part_name = .model.body_2

! --- Create markers for spring attachment points ---
marker create &
    marker_name = .model.body_1.spring_i_mkr &
    location = 0.0, 0.0, 0.0

marker create &
    marker_name = .model.body_2.spring_j_mkr &
    location = 0.0, 250.0, 0.0

! --- Create the spring-damper ---
force create element_like spring_damper &
    spring_damper_name = .model.spring_main &
    i_marker_name      = .model.body_1.spring_i_mkr &
    j_marker_name      = .model.body_2.spring_j_mkr &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    length             = 250.0
```

## Key Notes

- **`stiffness = 5000.0`** — stiffness in N/mm (Adams uses the model's unit system; confirm your model is set to N/mm/s).
- **`damping = 100.0`** — damping coefficient in N·s/mm.
- **`length = 250.0`** — free (natural) length in mm. This is the length at which the spring force is zero.
- The force law applied is: `F = -K × (current_length - free_length) - C × (rate_of_change_of_length)`.
- Spell out all keywords in full — abbreviated forms work interactively but will fail in scripts and macros.
- Use dot-path notation for all object names (`.model_name.part_name.marker_name`).
- Do **not** specify `adams_id` manually.

## When to Use `spring_damper`

`spring_damper` is the right choice here because you have a 1-DOF spring and damper acting along a single line of action with known K and C values. If you needed a 6-DOF compliant connection (e.g., a rubber mount), you would use `bushing` instead.
