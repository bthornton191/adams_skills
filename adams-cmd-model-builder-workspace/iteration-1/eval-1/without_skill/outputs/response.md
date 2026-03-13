# Creating a Spring-Damper Force Between Two Parts in Adams CMD

## Overview

A translational spring-damper (TSDA — Translational Spring Damper Actuator) connects two markers, one on each part. Adams computes the spring and damping forces along the line joining those two markers.

**Given parameters:**
- Stiffness: 5000 N/mm
- Damping: 100 N·s/mm
- Free length: 250 mm

---

## Prerequisites

You need one marker on each part at the desired attachment points. If they do not already exist, create them first.

### 1. Create Attachment Markers

```cmd
! Marker on Part 1 (e.g. at position 0, 0, 0 on Part 1)
marker create &
    marker_name = .MODEL.PART_1.SPRING_MAR_I &
    adams_id = 101 &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

! Marker on Part 2 (e.g. at position 0, 0, 250 on Part 2 — 250 mm away)
marker create &
    marker_name = .MODEL.PART_2.SPRING_MAR_J &
    adams_id = 102 &
    location = 0.0, 0.0, 250.0 &
    orientation = 0.0, 0.0, 0.0
```

> **Note:** Replace `.MODEL`, `PART_1`, and `PART_2` with your actual model and part names. If your parts already have suitable markers, skip this step and reference those markers instead.

---

## 2. Create the Spring-Damper Force Element

Use `force create element spring_damper_bushing` to create the translational spring-damper:

```cmd
force create element spring_damper_bushing &
    spring_damper_name = .MODEL.SPRING_DAMPER_1 &
    adams_id = 1 &
    i_marker_name = .MODEL.PART_1.SPRING_MAR_I &
    j_marker_name = .MODEL.PART_2.SPRING_MAR_J &
    stiffness = 5000.0 &
    damping = 100.0 &
    free_length = 250.0
```

### Parameter Explanation

| Parameter              | Value                         | Description                                                    |
|------------------------|-------------------------------|----------------------------------------------------------------|
| `spring_damper_name`   | `.MODEL.SPRING_DAMPER_1`      | Fully qualified name of the new force element                  |
| `adams_id`             | `1`                           | Integer ID (must be unique among TSDA elements in the model)   |
| `i_marker_name`        | `.MODEL.PART_1.SPRING_MAR_I`  | Marker on the first (action) part                              |
| `j_marker_name`        | `.MODEL.PART_2.SPRING_MAR_J`  | Marker on the second (reaction) part                           |
| `stiffness`            | `5000.0`                      | Spring stiffness in N/mm                                       |
| `damping`              | `100.0`                       | Damping coefficient in N·s/mm                                  |
| `free_length`          | `250.0`                       | Natural (unstretched) length of the spring in mm               |

---

## 3. Complete Example

The following is a self-contained example that builds two simple parts, places markers, and connects them with the spring-damper.

```cmd
! -------------------------------------------------------
! Model setup — assumes a model called MODEL already exists
! -------------------------------------------------------

! Create Part 1 (fixed ground connection handled separately)
part create rigid_body name_and_position &
    part_name = .MODEL.PART_1 &
    location = 0.0, 0.0, 0.0

! Create Part 2, offset 250 mm in the Z direction
part create rigid_body name_and_position &
    part_name = .MODEL.PART_2 &
    location = 0.0, 0.0, 250.0

! Add mass/inertia to Part 2 (example: 1 kg)
part create rigid_body mass_properties &
    part_name = .MODEL.PART_2 &
    mass = 1.0 &
    center_of_mass_marker = .MODEL.PART_2.cm &
    ixx = 1.0 &
    iyy = 1.0 &
    izz = 1.0

! -------------------------------------------------------
! Spring-damper attachment markers
! -------------------------------------------------------

marker create &
    marker_name = .MODEL.PART_1.SPRING_MAR_I &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

marker create &
    marker_name = .MODEL.PART_2.SPRING_MAR_J &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

! -------------------------------------------------------
! Spring-damper force element
! -------------------------------------------------------

force create element spring_damper_bushing &
    spring_damper_name = .MODEL.SPRING_DAMPER_1 &
    adams_id = 1 &
    i_marker_name = .MODEL.PART_1.SPRING_MAR_I &
    j_marker_name = .MODEL.PART_2.SPRING_MAR_J &
    stiffness = 5000.0 &
    damping = 100.0 &
    free_length = 250.0
```

---

## How Adams Computes the Force

Adams evaluates the spring-damper force at each time step as:

$$F = -k (d - l_0) - c \dot{d}$$

Where:
- $k = 5000$ N/mm — spring stiffness
- $l_0 = 250$ mm — free length
- $c = 100$ N·s/mm — damping coefficient
- $d$ — current distance between the I and J markers
- $\dot{d}$ — rate of change of that distance

A positive force is compressive (pushes markers apart when $d < l_0$); a negative force is tensile (pulls them together when $d > l_0$).

---

## Notes

- **Units:** The values above assume an **mm-N-s** unit system. If your model uses SI (m-N-s), convert: 5000 N/mm = 5,000,000 N/m and 250 mm = 0.25 m.
- **Marker alignment:** For a 1-D translational spring-damper the marker orientations do not affect the force direction — Adams always acts along the I-to-J line. However, aligned markers are good practice.
- **Free length vs. initial separation:** If you place the two attachment markers exactly 250 mm apart initially, there is no initial force. If the initial separation differs from 250 mm, the spring will produce a nonzero force at time zero.
- **`adams_id`:** Must be a positive integer unique among all TSDA elements. If you omit it, Adams assigns one automatically.
- **Modifying after creation:** Use `force modify element spring_damper_bushing` with the same parameters to change stiffness, damping, or free length after creation.
