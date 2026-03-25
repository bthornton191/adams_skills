# Creating a Spring-Damper Force in Adams CMD

## Overview

In Adams/View CMD scripting, a translational spring-damper is created using the `force create element_like translational_spring_damper` command. The force acts along the line joining two markers (one on each part).

## Prerequisites

Before creating the spring-damper, you need:
- Two parts already defined in your model
- One marker on each part to define the attachment points

## Example Script

```cmd
! Create markers on each part (if not already defined)
marker create &
    marker_name = .MODEL_1.PART_1.MAR_SPRING_I &
    adams_id = 1 &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

marker create &
    marker_name = .MODEL_1.PART_2.MAR_SPRING_J &
    adams_id = 2 &
    location = 250.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

! Create the translational spring-damper
force create element_like translational_spring_damper &
    translational_spring_damper_name = .MODEL_1.SPRING_1 &
    i_marker_name = .MODEL_1.PART_1.MAR_SPRING_I &
    j_marker_name = .MODEL_1.PART_2.MAR_SPRING_J &
    stiffness_coefficient = 5000.0 &
    damping_coefficient = 100.0 &
    free_length = 250.0
```

## Parameter Details

| Parameter | Value | Description |
|-----------|-------|-------------|
| `stiffness_coefficient` | `5000.0` | Spring stiffness in N/mm |
| `damping_coefficient` | `100.0` | Damping coefficient in N·s/mm |
| `free_length` | `250.0` | Natural (unstretched) length in mm |

## Notes on Units

- The values assume the model uses the **mm, N, s** unit system (MMKS).
- If using SI (m, N, s), convert: stiffness = 5,000,000 N/m, damping = 100,000 N·s/m, free_length = 0.25 m.
- Verify model units with: `units list`

## How It Works

- The spring-damper force is computed as:  
  `F = k * (L - L0) + c * dL/dt`  
  where `L` is the current length, `L0` is the free length, `k` is stiffness, and `c` is damping.
- The force is **compressive** when `L < L0` and **tensile** when `L > L0`.
- The I-marker is on the first part; the J-marker is on the second part.

## Verifying the Force

After creation, list forces to confirm:

```cmd
force list
```

Or check the specific element:

```cmd
force attributes &
    force_name = .MODEL_1.SPRING_1 &
    visibility = on
```

## Modifying the Spring-Damper

To change properties after creation:

```cmd
force modify element_like translational_spring_damper &
    translational_spring_damper_name = .MODEL_1.SPRING_1 &
    stiffness_coefficient = 5000.0 &
    damping_coefficient = 100.0 &
    free_length = 250.0
```
