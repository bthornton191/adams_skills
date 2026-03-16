# Adams CMD: Two-Shaft Gear System with 3:1 Gear Ratio

## Overview

The script `gear_coupler.cmd` builds a complete two-shaft gear model in Adams/View:

| Element | Detail |
|---|---|
| **shaft_input** | 0.5 kg · Ixx=Iyy=1000 · Izz=50 kg·mm² · revolute to ground at (0,0,0) |
| **shaft_output** | 0.5 kg · Ixx=Iyy=1000 · Izz=50 kg·mm² · revolute to ground at (0,150,0) |
| **gear_coupler** | Links `rev_input` and `rev_output`, 3:1 speed ratio, opposite directions |
| **motion_input** | Haversine velocity ramp 0 → 120 °/s over first 0.5 s, then holds |
| **Geometry** | 100 mm cylinder (r = 20 mm) on each shaft |
| **Simulation** | 2 s transient, 200 steps |

---

## Part Properties

Both shafts share identical inertial properties, reflecting thin cylinders spinning primarily about their longitudinal (Z) axis:

| Property | Value |
|---|---|
| Mass | 0.5 kg |
| Ixx = Iyy | 1000 kg·mm² |
| Izz | 50 kg·mm² (low — rotation axis) |

---

## Revolute Joints

Both joints rotate about the **Z-axis** of their ground markers. Default marker orientation (0°, 0°, 0°) aligns the local Z with the global Z, so no extra orientation transform is needed.

```cmd
constraint create joint revolute &
    joint_name    = .model.rev_input &
    i_marker_name = .model.shaft_input.rev_conn_mkr &
    j_marker_name = .model.ground.input_pivot_mkr

constraint create joint revolute &
    joint_name    = .model.rev_output &
    i_marker_name = .model.shaft_output.rev_conn_mkr &
    j_marker_name = .model.ground.output_pivot_mkr
```

---

## Gear Coupler — 3:1 Ratio, Opposite Directions

Adams enforces the gear constraint as a linear relationship between joint velocities:

$$\text{scale}_1 \cdot \dot{\theta}_\text{input} + \text{scale}_2 \cdot \dot{\theta}_\text{output} = 0$$

Choosing `scale_of_joint_freedom = 1.0, 3.0`:

$$1 \cdot \omega_\text{input} + 3 \cdot \omega_\text{output} = 0 \implies \omega_\text{input} = -3\,\omega_\text{output}$$

- The **negative sign** means opposite rotation directions. ✓  
- The **magnitude ratio 3:1** means input is 3 × faster than output. ✓

```cmd
constraint create coupler &
    coupler_name           = .model.gear_coupler &
    joint_name             = .model.rev_input, .model.rev_output &
    type_of_freedom        = rotational, rotational &
    scale_of_joint_freedom = 1.0, 3.0
```

---

## Motion Generator — Haversine Velocity Ramp

The input shaft angular velocity is driven by the `HAVSIN` (haversine step) function:

```
HAVSIN(x, x0, h0, x1, h1)
```

| Argument | Value | Meaning |
|---|---|---|
| `x` | `TIME` | Independent variable |
| `x0` | `0` | Ramp starts at t = 0 s |
| `h0` | `0` | Initial velocity: 0 deg/s |
| `x1` | `0.5` | Ramp ends at t = 0.5 s |
| `h1` | `120D` | Final velocity: 120 deg/s |

For `TIME > 0.5`, `HAVSIN` naturally returns `h1 = 120D`, so the velocity **holds at 120 °/s** without any additional IF logic.

```cmd
constraint create motion_generator &
    motion_name     = .model.motion_input &
    joint_name      = .model.rev_input &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "HAVSIN(TIME, 0, 0, 0.5, 120D)"
```

> **Note on `D` suffix:** In Adams function expressions, the `D` suffix converts degrees to radians internally. `120D` = 120 °/s ≈ 2.094 rad/s.

---

## Expected Velocity Profile

| Time (s) | ω_input (°/s) | ω_output (°/s) |
|---|---|---|
| 0.00 | 0 | 0 |
| 0.25 | ~60 (haversine mid) | ~−20 |
| 0.50 | 120 | −40 |
| 0.50 – 2.00 | 120 (constant) | −40 (constant) |

Once the ramp completes, the input runs at **120 °/s** and the output at **−40 °/s** (one-third the magnitude, opposite sign).

---

## Cylinder Geometry

Each shaft is visualised as a cylinder centred on its automatic `cm` marker and extending 50 mm in each ±Z direction from the joint center:

```cmd
geometry create shape cylinder &
    geometry_name          = .model.shaft_input.cyl_shape &
    part_name              = .model.shaft_input &
    center_marker          = .model.shaft_input.cm &
    angle_extent           = 360.0 &
    length                 = 100.0 &
    radius                 = 20.0 &
    side_count_for_body    = 20 &
    segment_count_for_ends = 2
```

---

## Simulation

```cmd
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .model &
    initial_static  = no
```

A 2-second run with 200 output steps (10 ms intervals) is sufficient to capture the full ramp transient (0–0.5 s) and a 1.5 s steady-state window.

---

## Complete Script

See [`gear_coupler.cmd`](gear_coupler.cmd) for the full Adams CMD script.
