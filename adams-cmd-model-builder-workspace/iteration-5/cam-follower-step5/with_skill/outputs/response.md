# Cam-Follower Mechanism — Adams CMD Script

## Overview

This script builds a complete cam-follower multibody model in Adams View:

- A **cam** body (1 kg, Ixx=Iyy=Izz=100 kg·mm²) rigidly fixed to ground at the origin.
- A **follower** body (0.5 kg, Ixx=Iyy=50 kg·mm², Izz=10 kg·mm²) constrained to translate only along the global X axis via a translational joint.
- A **single-component force** using `STEP5` that pushes the follower in +X, ramping from 0 N to 500 N as DX goes from 0 mm to 20 mm, then holding at 500 N, with a velocity-dependent term of 2.0 × VX.
- Visual **cylinder geometry** on both the cam (disk shape, 30 mm thick, 40 mm radius) and follower (rod shape, 60 mm long, 10 mm radius).
- A 1-second transient simulation with 1000 output steps.

---

## FUNCTION= Expression

```
function = "STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0) + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)"
```

---

## Design Decisions

### Why STEP5 Instead of STEP

`STEP5` uses a **quintic (5th-degree) polynomial** to transition between values. It guarantees continuous first **and second** derivatives at both endpoints (x = 0 mm and x = 20 mm). `STEP` uses only a cubic polynomial, which produces a discontinuous second derivative at the transition boundaries. In a cam-follower mechanism where the force feeds directly into the equation of motion, a second-derivative discontinuity creates impulsive acceleration spikes that can cause the integrator to stall or take extremely small timesteps. `STEP5` avoids this by ensuring the force ramps on and off with zero slope and zero curvature at both ends of the transition.

### Hold-at-500 N Behaviour

`STEP5(x, x0, h0, x1, h1)` saturates naturally:

- `x ≤ x0` (DX ≤ 0 mm) → returns `h0 = 0.0 N`
- `x0 < x < x1` (0 mm < DX < 20 mm) → quintic interpolation from 0 N to 500 N
- `x ≥ x1` (DX ≥ 20 mm) → returns `h1 = 500.0 N` indefinitely

No additional conditional logic is required.

### DX Displacement Measurement

`DX(.model.follower.tip_mkr, .model.cam.ref_mkr)` returns the X-component of the position vector from `cam.ref_mkr` to `follower.tip_mkr`, measured along the global X axis (default). Both markers start at the global origin and the follower is initially at DX = 0 mm, so the STEP5 ramp begins correctly from rest.

### Velocity-Dependent Term

`VX(.model.follower.tip_mkr, .model.cam.ref_mkr)` returns the X-component of the relative velocity of `tip_mkr` with respect to `cam.ref_mkr` in the global frame. Since the cam is fixed to ground, this is equal to the absolute X velocity of the follower. Multiplied by 2.0 (N·s/mm), this contributes a velocity-proportional term to the force.

### Force Direction

The `single_component_force` acts along the line of sight from the I marker (`follower.tip_mkr`) to the J marker (`ground.force_j_mkr`). `force_j_mkr` is placed at (1000, 0, 0) on the ground. Since the follower is constrained to translate along X with y = 0 and z = 0 throughout the simulation, the I-to-J direction is always exactly (1, 0, 0) — the global +X unit vector. The force always pushes in +X regardless of follower displacement.

### Translational Joint Orientation

The translational joint permits motion along the **z-axis of the J marker**. To align this with the global +X axis, both joint markers use:

```
orientation = 90.0D, 90.0D, 0.0D
```

This is a ZXZ Body-313 Euler rotation: first 90° about Z, then 90° about the new X. The resulting rotation matrix is:

```
R = [[0, 0, 1],
     [1, 0, 0],
     [0, 1, 0]]
```

The third column (local z-axis expressed in global coordinates) is (1, 0, 0) = global +X. The translational joint therefore constrains the follower to slide along the global X axis.

### Cam Geometry

A cylinder with `center_marker = cam.geom_mkr` (positioned at z = −15 mm) and `length = 30 mm` spans from z = −15 mm to z = +15 mm, centred visually on the cam origin. With `radius = 40 mm`, this represents a compact cam disk.

### Follower Geometry

A cylinder with `center_marker = follower.geom_mkr` (orientation 90D, 90D, 0D — local z → global +X) and `length = 60 mm` extends from the follower tip position 60 mm in the +X direction, representing the follower rod.

### Build Order

The script follows the required Adams CMD build order:
1. Model and units
2. Gravity
3. Ground markers
4. Parts (create → mass properties → markers)
5. Geometry
6. Constraints (fixed joint, translational joint)
7. Forces (single-component STEP5 force)
8. Simulation

`part modify rigid_body mass_properties` is called **after** `part create` and **without** `center_of_mass_marker` — Adams auto-creates `.cm` at this point. The `.cm` marker is never referenced explicitly since the default placement is correct.

No `adams_id` values are specified anywhere; Adams assigns all IDs automatically.

---

## Expected Simulation Behaviour

Starting from rest with DX = 0:

1. Force = 0 N initially. As the follower begins to accelerate under the cam force, DX grows from 0.
2. Over the interval DX ∈ [0, 20 mm], the force ramps smoothly from 0 to 500 N via the quintic STEP5 curve.
3. Beyond DX = 20 mm, the force holds at 500 N (plus the velocity term), and the follower continues to accelerate in +X.

Since there is no return spring in this model, the follower travels in the +X direction throughout the 1-second simulation. Gravity acts in −Y but is fully absorbed by the translational joint constraint, contributing only to joint reaction forces.

---

## File: `cam_follower.cmd`

The complete Adams CMD script is in `cam_follower.cmd` alongside this response.
