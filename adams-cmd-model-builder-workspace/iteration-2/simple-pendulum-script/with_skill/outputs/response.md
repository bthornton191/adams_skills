# Simple Pendulum — Adams CMD Script

## Task

Write an Adams CMD script to create a simple pendulum with:
- A single rigid link of length 200 mm and mass 1 kg
- Pinned to the ground at its top end by a revolute joint
- Gravity acting in the –Y direction
- Released from 45 degrees from the vertical

---

## Approach

The script follows the Adams CMD build-order convention from the skill:

> **model → parts → markers → geometry → data elements → constraints → forces/motions**

### Model topology

```
.pendulum
├── ground
│   └── pivot_mkr        (fixed pin point at global origin)
└── link
    ├── cm               (centre of mass, auto-placed at midpoint)
    ├── pin_mkr          (top end of rod — coincides with pivot_mkr)
    └── tip_mkr          (bottom end, 200 mm below pin along –Y)
```

The revolute joint connects `link.pin_mkr` (I marker, on the moving part) to `ground.pivot_mkr` (J marker, fixed), constraining rotation to the global Z-axis.

---

## Key Design Decisions

### Coordinate layout

The link hangs in the –Y direction at rest. With units in mm:

| Marker | Local position on `link` |
|--------|--------------------------|
| `pin_mkr` | 0, 0, 0 (part origin, coincides with pivot) |
| `cm` | 0, –100, 0 (midpoint of rod) |
| `tip_mkr` | 0, –200, 0 (free end) |

### Mass and inertia

For a uniform slender rod (m = 1 kg, L = 200 mm), the principal moments of inertia about the centre of mass are:

| Component | Value | Notes |
|-----------|-------|-------|
| `ixx` | 3333.33 kg·mm² | (1/12) m L² — bending about X |
| `iyy` | 0.0 kg·mm² | Along rod axis — negligible for thin rod |
| `izz` | 3333.33 kg·mm² | (1/12) m L² — **pendulum swing axis** |

### Initial condition (45°)

Achieved with a `part modify` call setting the part orientation to Body-313 Euler angles (PSI=0°, THETA=0°, PHI=45°), which is a net 45° rotation about global Z. The revolute joint constraint is satisfied because the pin marker (at the part origin = 0,0,0) remains coincident with the ground pivot marker throughout.

After rotation the tip position in global coordinates is:
- x = 200 × sin(45°) ≈ 141.4 mm
- y = –200 × cos(45°) ≈ –141.4 mm

### Gravity

`force create body gravitational` with `y_component_gravity = -9806.65` (mm/s²).

### Visualization geometry

A `geometry create shape link` is used for the rod (draws a bar directly between `pin_mkr` and `tip_mkr`, always aligned with the rod regardless of orientation). A sphere of radius 12 mm is added at `tip_mkr` as a bob.

---

## Theoretical period (small-angle approximation)

For a physical pendulum:

$$T = 2\pi \sqrt{\frac{I_{\text{pivot}}}{mgd}}$$

where:
- $I_{\text{pivot}} = \tfrac{1}{3}mL^2 = \tfrac{1}{3}(1)(200)^2 = 13{,}333.33 \text{ kg·mm}^2$
- $g = 9806.65 \text{ mm/s}^2$
- $d = 100 \text{ mm}$ (pivot-to-CM distance)

$$T = 2\pi \sqrt{\frac{13333.33}{1 \times 9806.65 \times 100}} \approx 2\pi \times 0.03687 \approx 0.897 \text{ s}$$

> Note: 45° is outside the small-angle regime, so the actual period from simulation will be slightly longer (~4–5 % longer at 45°).

---

## Script summary

| Step | Command | Notes |
|------|---------|-------|
| 1 | `model create` | Model name: `pendulum` |
| 2 | `defaults units` | mm, newton, kg, sec |
| 3 | `marker create` (ground) | `pivot_mkr` at origin |
| 4 | `part create … name_and_position` | `link` at origin |
| 5 | `marker create` × 3 (link) | `cm`, `pin_mkr`, `tip_mkr` |
| 6 | `part create … mass_properties` | m=1 kg, Ixx=Izz=3333.33 |
| 7 | `geometry create shape link` | Rod shape pin→tip |
| 8 | `geometry create shape sphere` | Bob at tip, r=12 mm |
| 9 | `constraint create joint revolute` | Pivot joint |
| 10 | `part modify … name_and_position` | 45° initial orientation |
| 11 | `force create body gravitational` | g = –9806.65 mm/s² in Y |

---

## Output file

`pendulum.cmd` — complete, ready-to-import Adams CMD script.

To run a simulation after importing:

```cmd
simulate transient end_time = 2.0 step_size = 0.002
```

---

## Issues encountered

None. The script follows all Adams CMD rules from the skill:
- All keywords spelled in full (no abbreviations)
- Dot-path hierarchy used throughout (`.pendulum.link.pin_mkr`)
- Line continuation with `&`
- `adams_id` not manually specified
- Angles expressed with `D` suffix (e.g., `45.0D`)
- Build order respected (model → parts → markers → geometry → constraints → forces)
