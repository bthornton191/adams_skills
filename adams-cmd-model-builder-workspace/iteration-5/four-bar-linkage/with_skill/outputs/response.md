# Four-Bar Linkage — Adams CMD Script

## Summary

This script builds a Grashof crank-rocker four-bar linkage in Adams View, drives the crank at a constant 360 deg/s, and runs a 2-second transient simulation at 0.001 s steps.

---

## Mechanism Geometry

| Link | Length | Mass | From | To |
|------|--------|------|------|----|
| Ground | 300 mm | — | O2 (0, 0, 0) | O4 (300, 0, 0) |
| Crank | 100 mm | 0.5 kg | O2 (0, 0, 0) | A (100, 0, 0) |
| Coupler | 250 mm | 0.5 kg | A (100, 0, 0) | B (256.25, 195.156, 0) |
| Rocker | 200 mm | 0.5 kg | B (256.25, 195.156, 0) | O4 (300, 0, 0) |

### Grashof Condition

For a four-bar linkage to be a **crank-rocker**, the shortest link must be adjacent to ground and the Grashof condition must hold:

$$s + l \leq p + q$$

- $s = 100$ mm (crank, shortest)
- $l = 300$ mm (ground, longest)
- $p = 200$ mm (rocker)
- $q = 250$ mm (coupler)

$$100 + 300 = 400 \leq 200 + 250 = 450 \quad \checkmark$$

Grashof condition satisfied — the crank can rotate continuously while the rocker oscillates.

### Initial Configuration

The crank is placed horizontal (0°, pointing in +X). The initial position of joint B is solved geometrically:

Given $|O_4 B| = 200$ and $|AB| = 250$ with $A = (100, 0, 0)$ and $O_4 = (300, 0, 0)$:

$$\cos\alpha = \frac{-17500}{80000} = -0.21875 \implies \alpha \approx 102.6°$$

$$B = \left(300 + 200\cos\alpha,\; 200\sin\alpha,\; 0\right) = (256.25,\; 195.156,\; 0)$$

---

## Model Structure

```
.four_bar
├── ground
│   ├── crank_pivot_mkr     (O2: 0, 0, 0)
│   └── rocker_pivot_mkr    (O4: 300, 0, 0)
├── crank
│   ├── cm                  (auto-created by Adams at part origin: 50, 0, 0)
│   ├── pin_ground_mkr      (O2: 0, 0, 0)
│   ├── pin_coupler_mkr     (A: 100, 0, 0)
│   └── shape_body          (link geometry, 15 × 8 mm cross-section)
├── coupler
│   ├── cm                  (auto-created: 178.125, 97.578, 0)
│   ├── pin_crank_mkr       (A: 100, 0, 0)
│   ├── pin_rocker_mkr      (B: 256.25, 195.156, 0)
│   └── shape_body          (link geometry)
├── rocker
│   ├── cm                  (auto-created: 278.125, 97.578, 0)
│   ├── pin_ground_mkr      (O4: 300, 0, 0)
│   ├── pin_coupler_mkr     (B: 256.25, 195.156, 0)
│   └── shape_body          (link geometry)
├── rev_crank_ground        (revolute @ O2: crank ↔ ground)
├── rev_crank_coupler       (revolute @ A:  coupler ↔ crank)
├── rev_coupler_rocker      (revolute @ B:  rocker ↔ coupler)
├── rev_rocker_ground       (revolute @ O4: rocker ↔ ground)
├── motion_crank            (velocity = 360 deg/s on rev_crank_ground)
└── gravity                 (−9806.65 mm/s² in Y)
```

---

## Mass Properties

Each part is modeled as a uniform slender rod. The part reference frame is placed at the geometric center so Adams auto-creates the `.cm` marker at the correct location.

| Part | Mass | Izz = m·L²/12 | Part origin (= CM) |
|------|------|---------------|--------------------|
| Crank | 0.5 kg | 416.667 kg·mm² | (50.0, 0.0, 0.0) |
| Coupler | 0.5 kg | 2604.167 kg·mm² | (178.125, 97.578, 0.0) |
| Rocker | 0.5 kg | 1666.667 kg·mm² | (278.125, 97.578, 0.0) |

`Ixx = Iyy = Izz` is set for each part; since the mechanism moves in the XY plane, out-of-plane inertia values do not affect the dynamics.

---

## Constraints

Four revolute joints constrain the mechanism to its single kinematic degree of freedom, all rotating about the global Z-axis:

| Joint | Location | I marker | J marker |
|-------|----------|----------|----------|
| `rev_crank_ground` | O2 (0, 0, 0) | `crank.pin_ground_mkr` | `ground.crank_pivot_mkr` |
| `rev_crank_coupler` | A (100, 0, 0) | `coupler.pin_crank_mkr` | `crank.pin_coupler_mkr` |
| `rev_coupler_rocker` | B (256.25, 195.156, 0) | `rocker.pin_coupler_mkr` | `coupler.pin_rocker_mkr` |
| `rev_rocker_ground` | O4 (300, 0, 0) | `rocker.pin_ground_mkr` | `ground.rocker_pivot_mkr` |

> **Note on redundant constraints:** A four-bar linkage modeled with four revolute joints in 3D is overconstrained by 2 (Grübler gives −2 DOF before applying the motion). Adams handles this via internal redundant constraint resolution and will issue a warning during simulation setup. This is expected and does not prevent the simulation from running correctly.

---

## Motion

The crank is driven by a `motion_generator` applied to `rev_crank_ground`:

```cmd
constraint create motion_generator &
    motion_name     = .four_bar.motion_crank &
    joint_name      = .four_bar.rev_crank_ground &
    type_of_freedom = rotational &
    time_derivative = velocity &
    function        = "360D"
```

`"360D"` specifies a constant angular velocity of 360 degrees per second (2π rad/s). Using `time_derivative = velocity` means the function value IS the angular velocity — `time_derivative` is always specified explicitly to avoid ambiguity.

---

## Simulation

```cmd
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .four_bar &
    initial_static  = no
```

- Duration: 2 s (crank completes exactly 2 full revolutions)
- Step size: 2.0 / 2000 = 0.001 s
- `initial_static = no` — no static equilibrium step needed for a kinematically driven mechanism
- `type = auto_select` — lets Adams choose the integration method

---

## How to Run

1. Open Adams View (or Adams/Car Command Window).
2. Run the script:
   ```
   file command read file_name = "four_bar_linkage.cmd"
   ```
3. Adams will build the model, apply the motion, and run the 2-second simulation automatically.
4. After the run, use the post-processor to plot crank angle, rocker angle, joint forces, etc.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Part origins at geometric centroid | Ensures Adams auto-places `.cm` at the correct CM location without needing to manually specify `center_of_mass_marker` |
| All marker locations in global coordinates | Adams CMD `marker create location=` takes global coordinates; placing them correctly in the initial configuration is sufficient |
| `geometry create shape link` | The `link` shape draws a bar between two markers — ideal for rod-like linkage members; more representative than a cylinder |
| `time_derivative = velocity` for motion | Matches the requirement of "constant 360 deg/s"; explicitly stated to avoid Adams defaulting to displacement interpretation |
| `initial_static = no` | With a prescribed velocity motion already defining the kinematics, a static pre-analysis would stall on zero velocity at t=0 |
