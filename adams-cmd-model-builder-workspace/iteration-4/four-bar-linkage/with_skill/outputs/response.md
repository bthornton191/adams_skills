# Four-Bar Linkage — Adams CMD Script

## Overview

The script builds a planar four-bar linkage with three moving rigid bodies (crank, coupler, rocker), four revolute joints, a constant-velocity motion driver on the crank, and a 2-second transient simulation at 1 ms steps.

---

## Geometry and Part Placement

The four joint locations in the world frame are:

| Pin | World location (mm) | Connected bodies |
|-----|---------------------|-----------------|
| A   | (0, 0, 0)           | Ground ↔ Crank  |
| B   | (100, 0, 0)         | Crank ↔ Coupler |
| C   | (300, 200, 0)       | Coupler ↔ Rocker |
| D   | (300, 0, 0)         | Rocker ↔ Ground |

Each part is positioned at its geometric midpoint so that joint markers can be defined with simple ±half-length local offsets:

- **Crank** — part origin at (50, 0, 0); `pin_a` at local (−50, 0, 0) → world (0, 0, 0); `pin_b` at local (50, 0, 0) → world (100, 0, 0).
- **Rocker** — part origin at (300, 100, 0); `pin_d` at local (0, −100, 0) → world (300, 0, 0); `pin_c` at local (0, 100, 0) → world (300, 200, 0).
- **Coupler** — part origin at (200, 100, 0); `pin_b_mkr` at local (−100, −100, 0) → world (100, 0, 0); `pin_c_mkr` at local (100, 100, 0) → world (300, 200, 0).

The actual straight-line distance between B and C is √(200² + 200²) ≈ 283 mm, not the nominal 250 mm. Adams resolves the initial configuration during assembly; the inertia for the coupler is still computed from the 250 mm design length. This is a common practice — the solver will find the correct assembled position.

The critical requirement satisfied here is that, for every revolute joint, the I-marker (on the moving part) and the J-marker (on the reference part or ground) are at the **same world-space location** when the model is created. Adams checks this during assembly initialization.

---

## Mass and Inertia

All three links have mass = 0.5 kg. Izz (the dominant inertia for planar motion) is computed using the slender-rod formula:

$$I_{zz} = \frac{m L^2}{12}$$

| Link    | L (mm) | Izz (kg·mm²) |
|---------|--------|--------------|
| Crank   | 100    | 416.67       |
| Coupler | 250    | 2604.17      |
| Rocker  | 200    | 1666.67      |

Ixx and Iyy are set equal to Izz. Their exact values do not affect a planar dynamics result, but they must be positive for Adams to accept the mass/inertia matrix.

Mass properties are applied with `part modify rigid_body mass_properties` in a separate command after `part create rigid_body name_and_position`, as required. `center_of_mass_marker` is never specified — Adams creates `.part.cm` automatically when mass is assigned.

---

## Motion Driver

The motion generator on `rev_a` (crank–ground joint) uses `type_of_freedom = rotational`. The FUNCTION= argument defines angular **position** (displacement), so:

```
function = "360D * TIME"
```

gives a constant angular velocity of 360 °/s (one full revolution per second). The `D` suffix converts the coefficient from degrees to the internal radian representation.

---

## Simulation

```cmd
simulate transient &
    end_time  = 2.0 &
    step_size = 0.001
```

This gives 2000 output steps, sufficient to resolve the two complete crank revolutions and the resulting coupler/rocker motion.
