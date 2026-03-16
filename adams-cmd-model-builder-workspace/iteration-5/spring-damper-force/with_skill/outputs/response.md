# Creating a Spring-Damper Force in Adams CMD

## Key Command

Use `force create element_like translational_spring_damper` for a 1-DOF spring + damper acting along the line between two markers. The correct parameter for free length is `displacement_at_preload` — **not** `length`.

---

## Complete Example

```cmd
! ============================================================
! Spring-Damper Force Example
! Units: mm, N, kg, s
! Spring: K = 5000 N/mm, C = 100 N·s/mm, free length = 250 mm
! ============================================================

! 1. Create model and set units
model create model_name = .spring_model

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! 2. Gravity
force create body gravitational &
    gravity_field_name  = .spring_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! 3. Ground attachment marker (bottom of spring)
! ============================================================
marker create &
    marker_name = .spring_model.ground.spring_j_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! 4. Moving part — the body the spring acts on
!    Place it 250 mm above ground (spring at free length)
! ============================================================
part create rigid_body name_and_position &
    part_name   = .spring_model.mass_block &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part modify rigid_body mass_properties &
    part_name = .spring_model.mass_block &
    mass      = 10.0 &
    ixx       = 1000.0 &
    iyy       = 1000.0 &
    izz       = 1000.0

! Marker on the moving part (top of spring)
marker create &
    marker_name = .spring_model.mass_block.spring_i_mkr &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Add geometry so the part is visible
geometry create shape box &
    box_name    = .spring_model.mass_block.box_geom &
    material    = .spring_model.mass_block &
    ref_marker  = .spring_model.mass_block.spring_i_mkr &
    length      = 50.0 &
    height      = 50.0 &
    depth       = 50.0

! ============================================================
! 5. Spring-Damper Force
! ============================================================
force create element_like translational_spring_damper &
    spring_damper_name      = .spring_model.spring_main &
    i_marker_name           = .spring_model.mass_block.spring_i_mkr &
    j_marker_name           = .spring_model.ground.spring_j_mkr &
    stiffness               = 5000.0 &
    damping                 = 100.0 &
    preload                 = 0.0 &
    displacement_at_preload = 250.0

! ============================================================
! 6. Run simulation (1 second, 1000 steps)
! ============================================================
simulation single_run transient &
    type            = auto_select &
    end_time        = 1.0 &
    number_of_steps = 1000 &
    model_name      = .spring_model &
    initial_static  = no
```

---

## Parameter Reference

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | `5000.0` | Spring rate K = 5000 N/mm |
| `damping` | `100.0` | Damping coefficient C = 100 N·s/mm |
| `displacement_at_preload` | `250.0` | Free (natural) length = 250 mm |
| `preload` | `0.0` | Force applied at the free-length configuration (zero here) |

---

## Key Rules

1. **Use `translational_spring_damper`**, not `spring_damper` — the full element-type keyword is required.

2. **`displacement_at_preload` is the free length** — this is the I-to-J marker distance at which the spring force is zero (assuming `preload = 0`).

3. **Marker placement matters** — the I marker should be on the moving part and the J marker on the fixed part (or the other moving part). The spring force acts along the straight line connecting them.

4. **Units must match** — with `defaults units length = mm, force = newton`, stiffness is N/mm and damping is N·s/mm automatically.

5. **Force law**: `F = preload − K × (d − displacement_at_preload) − C × ḋ`  
   where `d` is the current I-to-J distance and `ḋ` is its time derivative.

---

## Common Mistakes to Avoid

| Mistake | Correct approach |
|---------|-----------------|
| `force create element_like spring_damper` | Use `translational_spring_damper` |
| Setting free length via `length = 250.0` | Use `displacement_at_preload = 250.0` |
| Placing I and J markers at the same location | Separate them by the free length (or expected operating distance) |
| Using `simulate transient` | Use `simulation single_run transient` |
