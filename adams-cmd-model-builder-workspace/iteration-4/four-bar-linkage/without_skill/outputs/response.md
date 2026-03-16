# Four-Bar Linkage — Adams CMD Script

## Overview

This script builds a planar four-bar linkage in Adams View using the CMD scripting interface. The mechanism consists of three moving rigid links (crank, coupler, rocker) connected by revolute joints to each other and to the fixed ground link.

## Mechanism Geometry

The four pivot points in the initial (crank-horizontal) configuration are:

| Point | Description | Location (mm) |
|-------|-------------|---------------|
| A | Crank / ground pivot | (0, 0, 0) |
| B | Crank tip / coupler pin | (100, 0, 0) |
| C | Coupler / rocker pin | (256.25, 195.16, 0) |
| D | Rocker / ground pivot | (300, 0, 0) |

Point C is calculated from the closure equations:

- |BC| = 250 mm (coupler length)
- |DC| = 200 mm (rocker length)

Solving simultaneously gives C = (256.25, 195.16, 0) mm.

### Grashof Condition

For continuous crank rotation the Grashof condition must hold:

```
shortest + longest ≤ sum of remaining two
100 + 300 = 400 ≤ 250 + 200 = 450  ✓
```

This is a **crank-rocker** mechanism: the crank (shortest link connected to ground) rotates fully; the rocker oscillates.

## Link Properties

| Link | Length (mm) | Mass (kg) | Izz (kg·mm²) |
|------|------------|-----------|--------------|
| Crank | 100 | 0.5 | 416.67 |
| Coupler | 250 | 0.5 | 2604.17 |
| Rocker | 200 | 0.5 | 1666.67 |

Inertia about the link's own centre of mass, treating each link as a uniform slender rod: $I_{zz} = mL^2/12$.

## Script Structure

1. **Model & units** — Create model `four_bar`, set mm/kg/s/N/deg units and gravity.
2. **Ground markers** — Fixed reference points at A (origin) and D (300 mm along X).
3. **Parts** — Create `crank`, `coupler`, and `rocker` rigid bodies with mass, CM marker, and inertia.
4. **Connection markers** — One marker per joint location on each part.
5. **Revolute joints** — Four revolutes (JNT_A through JNT_D) constraining the chain.
6. **Crank motion** — Angular displacement function `360d * time` drives the crank at a constant 360 °/s.
7. **Simulation** — 2-second dynamic analysis with 0.001 s output steps (2000 output frames).

## Key CMD Patterns Used

- `part create rigid_body name_and_position` — creates a part at a given location/orientation
- `part modify rigid_body mass_properties` — assigns mass and inertia tensor
- `marker create` — defines reference points on a part
- `constraint create joint revolute` — creates a revolute joint between two markers
- `motion create` with `type_of_freedom = rotational` and `function = "360.0d * time"` — imposes constant crank speed
- `simulation single` with `end_time`, `step_size`, `type = dynamic` — runs the analysis

## Notes

- All lengths are in millimetres; gravity is −9806.65 mm/s².
- The `d` suffix in `360.0d` instructs Adams to interpret the value as degrees.
- The motion function gives **displacement** (deg) as a linear function of time, directly producing a constant angular velocity.
- `initial_static = no` skips a static equilibrium solve before the dynamic run so the driven motion starts immediately at t = 0.
