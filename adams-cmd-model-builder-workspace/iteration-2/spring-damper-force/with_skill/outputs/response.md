# Creating a Spring-Damper Force in Adams CMD

## Overview

Use `force create element_like spring_damper` to add a 1-DOF spring-damper between two parts. The element connects an **I marker** on one part to a **J marker** on another. Adams resolves the instantaneous distance between the markers and applies:

```
Force = −K × (current_length − free_length) − C × d/dt(current_length)
```

Positive force = compression (pushing the markers apart).

---

## Prerequisites: Markers on Each Part

Before creating the spring-damper, each part needs a marker at the connection point. The spring acts along the **line connecting the I and J markers**, so place them accurately.

```cmd
! Marker on part_a at the spring attach point
marker create &
    marker_name = .my_model.part_a.M_SPR_I &
    location    = 0.0, 0.0, 200.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Marker on part_b at the spring attach point
marker create &
    marker_name = .my_model.part_b.M_SPR_J &
    location    = 0.0, 0.0, 450.0 &
    orientation = 0.0D, 0.0D, 0.0D
```

> **Note:** The initial separation between `M_SPR_I` and `M_SPR_J` does not need to equal the free length — Adams handles preload automatically.

---

## Spring-Damper Command

```cmd
force create element_like spring_damper &
    spring_damper_name = .my_model.SPR_MAIN &
    i_marker_name      = .my_model.part_a.M_SPR_I &
    j_marker_name      = .my_model.part_b.M_SPR_J &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    length             = 250.0
```

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | `5000.0` | Spring stiffness K = 5000 N/mm |
| `damping` | `100.0` | Viscous damping C = 100 N·s/mm |
| `length` | `250.0` | Free (natural) length = 250 mm |

---

## Complete Worked Example

The example below creates a simple two-part model with a vertical spring-damper:

- **`ground`** — the fixed reference part (always present).
- **`slider`** — a moving part (mass = 2 kg) that can only translate vertically.
- A **translational joint** constrains the slider to the vertical axis.
- The **spring-damper** acts between the base of `ground` and the bottom of `slider`.

```cmd
! ============================================================
! Spring-Damper Example
! Units: mm, Newton, kg, second
! ============================================================

! 1. Create model
model create model_name = my_model

! 2. Set units
defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! 3. Gravity (−Y direction in mm-kg-s: −9806.65 mm/s²)
force create body gravitational &
    gravity_field_name  = .my_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! Parts and Markers
! ============================================================

! Ground reference marker (spring J end — fixed)
marker create &
    marker_name = .my_model.ground.M_SPR_J &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Ground reference marker for translational joint (J side)
marker create &
    marker_name = .my_model.ground.M_TRANS_J &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D  ! Z-axis of marker points along global Y

! Create the slider part at initial height = free length = 250 mm
part create rigid_body name_and_position &
    part_name   = .my_model.slider &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Mass properties for slider
part create rigid_body mass_properties &
    part_name             = .my_model.slider &
    mass                  = 2.0 &
    center_of_mass_marker = .my_model.slider.cm &
    ixx                   = 5000.0 &
    iyy                   = 5000.0 &
    izz                   = 500.0

! Slider marker for spring I end (at bottom of slider = its origin)
marker create &
    marker_name = .my_model.slider.M_SPR_I &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Slider marker for translational joint (I side)
marker create &
    marker_name = .my_model.slider.M_TRANS_I &
    location    = 0.0, 250.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D  ! Must match J marker orientation

! ============================================================
! Translational Joint (constrains slider to vertical axis)
! ============================================================

constraint create joint translational &
    joint_name   = .my_model.TRANS_VERT &
    i_marker_name = .my_model.slider.M_TRANS_I &
    j_marker_name = .my_model.ground.M_TRANS_J

! ============================================================
! Spring-Damper Force
! K = 5000 N/mm, C = 100 N·s/mm, free length = 250 mm
! ============================================================

force create element_like spring_damper &
    spring_damper_name = .my_model.SPR_MAIN &
    i_marker_name      = .my_model.slider.M_SPR_I &
    j_marker_name      = .my_model.ground.M_SPR_J &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    length             = 250.0
```

---

## Key Notes

### Units
The parameter values must match the model's active unit system. In this example (`mm`, `newton`, `kg`, `sec`):
- `stiffness` is in **N/mm**
- `damping` is in **N·s/mm**
- `length` is in **mm**

If your model uses MKS (m, N, kg, s), convert accordingly:
- 5000 N/mm → 5,000,000 N/m
- 100 N·s/mm → 100,000 N·s/m
- 250 mm → 0.25 m

### Free Length vs. Initial Separation
The `length` parameter is the **free (natural) length** — the length at which the spring force is zero. If the initial marker separation differs from `length`, the spring starts with a preload at t = 0. This is intentional and physically correct.

### Naming Convention
Following Adams CMD best practices:
- Spring-damper names are prefixed with `SPR_` (e.g., `SPR_MAIN`)
- Markers are prefixed with `M_` (e.g., `M_SPR_I`, `M_SPR_J`)
- Full dot-path names are always used in file-based scripts

### Rendering
To display the spring-damper graphically in Adams View, it is rendered automatically as a coil-and-dashpot symbol between the I and J markers. No additional geometry command is needed.

### Modifying After Creation
To change properties after creation, use `force modify`:

```cmd
force modify element_like spring_damper &
    spring_damper_name = .my_model.SPR_MAIN &
    stiffness          = 6000.0 &
    damping            = 120.0
```

---

## Summary

| Step | CMD construct |
|------|---------------|
| Create I marker on part_a | `marker create marker_name = .model.part_a.M_SPR_I ...` |
| Create J marker on part_b | `marker create marker_name = .model.part_b.M_SPR_J ...` |
| Create spring-damper | `force create element_like spring_damper spring_damper_name = ... stiffness = 5000.0 damping = 100.0 length = 250.0` |
