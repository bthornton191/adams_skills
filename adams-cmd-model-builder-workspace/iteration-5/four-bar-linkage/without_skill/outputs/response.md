# Four-Bar Linkage — Adams CMD Script

## Response

Below is an Adams/View CMD script that builds and simulates a planar four-bar crank-rocker linkage matching the specification.

---

## Mechanism Design

### Topology

A four-bar linkage has four links connected by four revolute (pin) joints, forming a closed kinematic loop:

```
Ground A ——— Crank ——— B
   |                   |
   D ——— Rocker ——— C
              (via Coupler B–C)
```

- **A** = crank pivot on ground at origin `(0, 0, 0)`
- **D** = rocker pivot on ground at `(300, 0, 0)`
- **B** = crank tip / coupler pin (moves with crank)
- **C** = rocker tip / coupler pin (moves with rocker)
- The coupler connects **B** to **C**

### Grashof Condition

For a crank-rocker mechanism (crank makes full rotations), the Grashof condition must be satisfied:

```
s + l ≤ p + q
```

where:
- s = shortest link = crank = **100 mm**
- l = longest link = ground = **300 mm**
- p = coupler = **250 mm**
- q = rocker = **200 mm**

```
100 + 300 = 400 ≤ 250 + 200 = 450  ✓
```

The shortest link (crank) is adjacent to the fixed ground link, confirming a **crank-rocker** configuration.

---

## Initial Position

The crank is placed at **90° from horizontal** (pointing straight up) as the starting configuration. This gives a non-degenerate initial position well away from kinematic singularities.

| Point | Coordinates (mm) | Description |
|-------|-----------------|-------------|
| A | (0, 0, 0) | Crank ground pivot |
| B | (0, 100, 0) | Crank tip (crank vertical) |
| C | (233.734, 188.702, 0) | Coupler/rocker junction |
| D | (300, 0, 0) | Rocker ground pivot |

### Derivation of point C

With B = (0, 100, 0) and D = (300, 0, 0), point C must satisfy:

```
|BC| = 250 mm  =>  x² + (y – 100)² = 62500
|DC| = 200 mm  =>  (x – 300)² + y² = 40000
```

Subtracting and solving the linear equation: `y = 3x – 512.5`

Substituting back: `10x² – 3675x + 312656.25 = 0`

```
x = (367.5 + √9993.75) / 2 ≈ 233.734 mm
y = 3(233.734) – 512.5   ≈ 188.702 mm
```

Verification:
- |BC| = √(233.734² + 88.702²) ≈ **250.000 mm** ✓
- |DC| = √(66.266² + 188.702²) ≈ **200.000 mm** ✓

---

## Mass and Inertia

Each link is modeled as a **uniform slender rod**. The centre-of-mass moment of inertia about the out-of-plane Z axis is:

$$I_{zz} = \frac{mL^2}{12}$$

| Link | Length (mm) | Mass (kg) | $I_{zz}$ (kg·mm²) |
|------|-------------|-----------|-------------------|
| Crank | 100 | 0.5 | 416.667 |
| Coupler | 250 | 0.5 | 2604.167 |
| Rocker | 200 | 0.5 | 1666.667 |

For this planar mechanism, only $I_{zz}$ drives the 2D rotational dynamics; $I_{xx}$ and $I_{yy}$ are provided as equal to $I_{zz}$ for numerical stability (the out-of-plane DOFs remain zero-loaded due to the revolute joints).

---

## Script Structure

### Units
```
defaults units  length=mm  mass=kg  force=newton  time=sec
```
Adams MMKS system: millimetres, kilograms, Newtons, seconds.

### Model hierarchy
```
four_bar
├── ground
│   ├── GRND_A       (0, 0, 0)
│   └── GRND_D       (300, 0, 0)
├── crank            CM at (0, 50, 0)
│   ├── CRANK_A      (0, 0, 0)
│   └── CRANK_B      (0, 100, 0)
├── coupler          CM at (116.867, 144.351, 0)
│   ├── COUPLER_B    (0, 100, 0)
│   └── COUPLER_C    (233.734, 188.702, 0)
└── rocker           CM at (266.867, 94.351, 0)
    ├── ROCKER_D     (300, 0, 0)
    └── ROCKER_C     (233.734, 188.702, 0)
```

### Joints
Four revolute joints (each constraining 5 DOF):

| Joint | Location | Parts connected |
|-------|----------|----------------|
| JNT_A | A | crank ↔ ground |
| JNT_B | B | coupler ↔ crank |
| JNT_C | C | rocker ↔ coupler |
| JNT_D | D | rocker ↔ ground |

### Driver

```adams
motion create joint_motion &
   joint_name      = .four_bar.JNT_A &
   type_of_freedom = rotational &
   function        = "360.0D * time"
```

The `D` suffix is Adams' degree-to-radian conversion factor (× π/180).
`360.0D * time = 2π · t` radians, giving:
- Angular displacement: 360° per second
- Angular velocity: 2π rad/s = **360 deg/s** (constant) ✓

### Simulation

```adams
simulation single_run transient &
   time_duration   = 2.0 &
   number_of_steps = 2000 &
   initial_static  = no
```

- Duration: **2 s** (2 full crank revolutions)
- Output step: 2.0 / 2000 = **0.001 s**
- `initial_static = no`: the prescribed crank motion determines all positions; no static equilibrium solve is needed at t = 0.

---

## Usage

1. Open Adams/View.
2. From the menu: **File → Import → Adams/View Command File**, then select `four_bar_linkage.cmd`.  
   Alternatively, in the Adams/View command window:
   ```
   file command read file_name = "four_bar_linkage.cmd"
   ```
3. The model `four_bar` will be built and the simulation will run automatically, producing 2001 time steps (t = 0, 0.001, …, 2.000 s).

---

## Notes and Limitations

- **Redundant constraints**: planar mechanisms simulated in 3D Adams have redundant constraints (the joints over-specify the planar motion). Adams handles this automatically via its constraint solver; no action is required.
- **Gravity**: the default Adams gravity (−9806.65 mm/s² in the −Y direction) is active. This affects reaction forces and the required driving torque but does not alter the prescribed kinematics.
- **Inertia simplification**: off-diagonal inertia products (Ixy, Iyz, Izx = 0) are used. For this constrained 2D mechanism this has no effect on the trajectory, only on joint reaction forces.
- **Marker locations**: all `marker create` locations are specified in the global (ground) frame at the initial configuration.
