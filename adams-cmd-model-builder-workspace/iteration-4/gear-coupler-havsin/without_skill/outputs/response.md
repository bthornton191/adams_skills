# Adams CMD: Gear Coupler with Haversine Ramp Motion

## Overview

Two commands are needed:
1. A **coupler constraint** to link the two revolute joints with a 3:1 gear relationship.
2. A **motion** on the input joint driving angular velocity via the haversine STEP function.

---

## Step 1 – Create the Gear Coupler Constraint

Adams uses a **coupler** primitive to enforce a linear relationship between joint velocities:

$$\sum_i R_i \, \dot{q}_i = 0$$

For a 3:1 ratio with opposite rotation: $\dot{\theta}_\text{input} = -3\,\dot{\theta}_\text{output}$, which is enforced by choosing $R_\text{input} = 1$ and $R_\text{output} = 3$ (both positive → opposite-sign velocities).

```cmd
constraint create coupler &
  coupler_name           = .model.gear_coupler &
  joint_name             = .model.rev_input, .model.rev_output &
  type_of_freedom        = rotational, rotational &
  scale_of_joint_freedom = 1.0, 3.0
```

### Parameter notes

| Parameter | Value | Meaning |
|---|---|---|
| `joint_name` | `.model.rev_input, .model.rev_output` | The two revolute joints to couple |
| `type_of_freedom` | `rotational, rotational` | Both joints contribute their rotational DOF |
| `scale_of_joint_freedom` | `1.0, 3.0` | Enforces $1·\omega_\text{in} + 3·\omega_\text{out} = 0$, i.e., $\omega_\text{in} = -3\,\omega_\text{out}$ |

The **negative sign** that arises from the equation means the shafts rotate in **opposite directions**, which matches the requirement.

---

## Step 2 – Add a Motion Generator on the Input Joint

The input angular velocity must ramp smoothly from 0 to 120 °/s over the first 0.5 s (haversine step), then hold.

Adams' built-in `STEP` function is haversine-based. Its signature is:

```
STEP(x, x0, h0, x1, h1)
```

This returns `h0` for `x ≤ x0`, `h1` for `x ≥ x1`, and a smooth haversine polynomial transition between them. Setting `TIME, 0.0, 0.0, 0.5, 120.0D` gives exactly the required ramp, and the value naturally holds at 120 °/s for all `TIME > 0.5`.

```cmd
motion create &
  motion_name     = .model.motion_input &
  joint_name      = .model.rev_input &
  type_of_freedom = rotational &
  time_derivative = 1 &
  function        = "STEP(TIME, 0.0, 0.0, 0.5, 120.0D)"
```

### Parameter notes

| Parameter | Value | Meaning |
|---|---|---|
| `joint_name` | `.model.rev_input` | Apply motion to the input revolute joint |
| `type_of_freedom` | `rotational` | Drives the rotational DOF |
| `time_derivative` | `1` | The function represents **velocity** (0 = displacement, 1 = velocity, 2 = acceleration) |
| `function` | `STEP(TIME, 0.0, 0.0, 0.5, 120.0D)` | Haversine ramp 0 → 120 °/s from t = 0 → 0.5 s |

> **Note on `D` suffix:** In Adams functions, the `D` (or `d`) suffix converts degrees to radians internally. `120.0D` means 120 degrees per second.

---

## Complete Script

```cmd
! -------------------------------------------------------
! Gear coupler: rev_input drives rev_output at 3:1 ratio,
! opposite rotation direction
! -------------------------------------------------------
constraint create coupler &
  coupler_name           = .model.gear_coupler &
  joint_name             = .model.rev_input, .model.rev_output &
  type_of_freedom        = rotational, rotational &
  scale_of_joint_freedom = 1.0, 3.0

! -------------------------------------------------------
! Motion on input joint: haversine ramp 0 -> 120 deg/s
! over first 0.5 s, then hold at 120 deg/s
! -------------------------------------------------------
motion create &
  motion_name     = .model.motion_input &
  joint_name      = .model.rev_input &
  type_of_freedom = rotational &
  time_derivative = 1 &
  function        = "STEP(TIME, 0.0, 0.0, 0.5, 120.0D)"
```

---

## Velocity Profile

| Time (s) | Input ω (deg/s) | Output ω (deg/s) |
|---|---|---|
| 0.0 | 0 | 0 |
| 0.25 | ~60 (haversine midpoint) | ~−20 |
| 0.5 | 120 | −40 |
| > 0.5 | 120 (constant) | −40 (constant) |

The output shaft runs at **−40 °/s** (one-third the speed, opposite sign) once the ramp completes.
