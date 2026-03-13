# Creating a Spring-Damper Force in Adams CMD

## Overview

In Adams, a translational spring-damper is created as a **TSDA (Translational Spring-Damper-Actuator)** force element using the `force create element_like spring_damper` command. It acts along the line connecting an I marker (on one part) and a J marker (on another part), applying equal and opposite forces based on the relative displacement and velocity between those markers.

---

## Prerequisites

Before creating the spring-damper, you need:

1. Two parts already defined in the model.
2. A **marker on each part** at the desired attachment points. The spring acts along the vector from the I marker to the J marker.

---

## Step 1 – Define the Units

Ensure the model is set to mm/N/s units so that the stiffness (N/mm) and damping (N·s/mm) values are entered directly:

```cmd
units set &
   length = mm &
   mass = kg &
   force = newton &
   time = second
```

---

## Step 2 – Create Attachment Markers

Place a marker on each part at the spring attachment location. The free length is 250 mm, so if one end is at the origin of `part_1`, position the `part_2` marker 250 mm away along the spring axis (e.g., the X-axis):

```cmd
! Marker on the first part
marker create &
   marker_name = .model.part_1.spring_i &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! Marker on the second part (250 mm away along X)
marker create &
   marker_name = .model.part_2.spring_j &
   location = 250.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0
```

> **Note:** Adjust the `location` values to match the actual geometry of your model. The `orientation` of the markers does not affect the spring-damper behaviour — only their positions matter for a TSDA.

---

## Step 3 – Create the Spring-Damper Force

Use `force create element_like spring_damper` to define the TSDA with the specified stiffness, damping, and free length:

```cmd
force create element_like spring_damper &
   spring_damper_name = .model.spr_damp_1 &
   i_marker_name      = .model.part_1.spring_i &
   j_marker_name      = .model.part_2.spring_j &
   stiffness          = 5000.0 &
   damping            = 100.0 &
   free_length        = 250.0
```

| Parameter            | Value  | Units    | Description                                   |
|---------------------|--------|----------|-----------------------------------------------|
| `stiffness`         | 5000.0 | N/mm     | Linear spring stiffness coefficient           |
| `damping`           | 100.0  | N·s/mm   | Linear viscous damping coefficient            |
| `free_length`       | 250.0  | mm       | Natural (unstretched) length of the spring    |

---

## How Adams Computes the Force

Adams calculates the spring-damper force as:

$$F = k \cdot (L - L_0) + c \cdot \dot{L}$$

Where:
- $k$ = stiffness = 5000 N/mm
- $L$ = current distance between the I and J markers
- $L_0$ = free length = 250 mm
- $c$ = damping = 100 N·s/mm
- $\dot{L}$ = time derivative of $L$ (relative velocity along the spring axis)

A positive force (compression) acts to push the markers apart; a negative force (tension) pulls them together.

---

## Complete Example Script

The following self-contained CMD script creates a minimal two-part model with a spring-damper:

```cmd
! ============================================================
! Spring-Damper Example
! Units: mm, kg, N, s
! Stiffness: 5000 N/mm  Damping: 100 N*s/mm  Free length: 250 mm
! ============================================================

defaults model &
   model_name = .spring_model

units set &
   length = mm &
   mass = kg &
   force = newton &
   time = second

! --- Ground part (part_1 is the ground) ---
part create rigid_body ground &
   part_name = .spring_model.ground

! --- Moving part ---
part create rigid_body mass &
   part_name    = .spring_model.moving_part &
   mass         = 10.0 &
   center_of_mass_marker_name = .spring_model.moving_part.cm

! --- Attachment markers ---
marker create &
   marker_name = .spring_model.ground.spring_i &
   location    = 0.0, 0.0, 0.0

marker create &
   marker_name = .spring_model.moving_part.spring_j &
   location    = 250.0, 0.0, 0.0

! --- Spring-damper force element ---
force create element_like spring_damper &
   spring_damper_name = .spring_model.spr_damp_1 &
   i_marker_name      = .spring_model.ground.spring_i &
   j_marker_name      = .spring_model.moving_part.spring_j &
   stiffness          = 5000.0 &
   damping            = 100.0 &
   free_length        = 250.0
```

---

## Notes and Tips

- **Nonlinear stiffness/damping**: If you need nonlinear behaviour, replace the numeric constants with spline-based expressions using `AKISPL` or `CUBSPL` functions, e.g.:
  ```cmd
  stiffness = (AKISPL(DM(.spring_model.moving_part.spring_j, .spring_model.ground.spring_i), 0, .spring_model.stiffness_spline))
  ```

- **Preload**: To apply a preload force, set `free_length` to a value different from the initial distance between the markers. If the initial separation is 250 mm and `free_length = 240 mm`, the spring starts with 10 mm of compression (a 50,000 N preload at 5000 N/mm).

- **Viewing results**: After simulation, you can plot the spring force using the Measure or PostProcessor by selecting the `spr_damp_name` element and requesting the `force` output component.

- **Rotational spring-damper**: For a torsional spring-damper (RSDA), use `force create element_like rotational_spring_damper` with the same parameter structure but different units (N·mm/deg, etc.).
