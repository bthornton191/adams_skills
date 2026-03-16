# Response: Parametric Chain of 8 Point Masses (Adams CMD)

## Overview

The script `parametric_chain.cmd` builds an 8-mass spring-damper chain in Adams. Instead of writing out each part, marker, and spring individually, it uses a **FOR loop** together with the **EVAL**, **RTOI**, and **//** operators to construct all entities parametrically.

---

## Script Structure

### Section 1 — Point masses (FOR N = 1 to 8)

```cmd
FOR/VARIABLE = N, START = 1, END = 8, INC = 1

  PART/EVAL(RTOI(N)), &
      MASS  = 0.25, &
      IP    = 1.0E-6, 1.0E-6, 1.0E-6, &
      LABEL = "MASS_" // RTOI(N)

  MARKER/EVAL(RTOI(N)*10), &
      PART = EVAL(RTOI(N)), &
      QP   = EVAL((RTOI(N)-1)*50.0), 0.0, 0.0

  PART/EVAL(RTOI(N)), CM = EVAL(RTOI(N)*10)

  MARKER/EVAL(RTOI(N)*10+1), &
      PART = EVAL(RTOI(N)), &
      QP   = EVAL((RTOI(N)-1)*50.0), 0.0, 0.0

END_FOR
```

**What each operator does here:**

| Operator | Example | Purpose |
|----------|---------|---------|
| `EVAL(expr)` | `EVAL(RTOI(N)*10)` | Evaluates arithmetic at parse-time to produce a numeric entity ID or QP value |
| `RTOI(N)` | `RTOI(N)` | Converts the real-valued loop variable N to an integer, making ID arithmetic exact and enabling its use as a string in `//` expressions |
| `//` | `"MASS_" // RTOI(N)` | Concatenates string literals with integer-converted values to build human-readable entity labels |

Each part N is placed at X = (N − 1) × 50 mm, so the masses sit at:

| N | X position |
|---|-----------|
| 1 | 0 mm      |
| 2 | 50 mm     |
| 3 | 100 mm    |
| … | …         |
| 8 | 350 mm    |

Two markers are created on every part:
- **CM marker** `10·N` — the centre-of-mass reference
- **Connection marker** `10·N + 1` — the spring attachment point

### Section 2 — Fixed joint at the origin

Marker 901 is placed on ground (PART = 0) and marker 902 on Part 1, both at (0, 0, 0). A FIXED joint between them locks Mass 1 in place.

```cmd
MARKER/901, PART = 0, QP = 0.0, 0.0, 0.0
MARKER/902, PART = 1, QP = 0.0, 0.0, 0.0
JOINT/1, FIXED, I = 902, J = 901
```

### Section 3 — Spring-dampers (FOR N = 1 to 7)

```cmd
FOR/VARIABLE = N, START = 1, END = 7, INC = 1

  SPRING/EVAL(RTOI(N)+100), &
      I      = EVAL(RTOI(N)*10+1), &
      J      = EVAL(RTOI(N)*10+11), &
      K      = 100.0, &
      C      = 1.0, &
      LENGTH = 50.0, &
      LABEL  = "SPRING_" // RTOI(N) // "_" // RTOI(N+1)

END_FOR
```

The J marker formula uses the identity 10·(N+1) + 1 = 10·N + 11, so that `EVAL(RTOI(N)*10+11)` always resolves to the connection marker on the next mass.

| Spring ID | I marker | J marker | Connects |
|-----------|----------|----------|---------|
| 101 | 11 | 21 | Mass 1 → Mass 2 |
| 102 | 21 | 31 | Mass 2 → Mass 3 |
| … | … | … | … |
| 107 | 71 | 81 | Mass 7 → Mass 8 |

Spring parameters: **K = 100 N/mm**, **C = 1.0 N·s/mm**, **free length = 50 mm**.

### Section 4 — Simulation

```cmd
SIMULATE/TRANSIENT, END = 2.0, DTOUT = 0.01
```

Runs a transient dynamic analysis for 2 seconds with output every 0.01 s (200 frames).

---

## Physical Behaviour

The free length of every spring (50 mm) equals the initial gap between adjacent masses, so the chain starts at **static equilibrium**. No initial motion will be observed unless an initial condition or external perturbation is added. To introduce dynamics, you could add an initial velocity to the last mass:

```cmd
IC/MARKER = 81, VX = 100.0
```

or apply a short impulsive force.

---

## Unit System

All values use the **mm / kg / N / s** unit system:

- Stiffness K in N/mm
- Damping C in N·s/mm
- Mass in kg
- Length/position in mm
- Time in s

---

## Notes

1. **LABEL parameter**: The `LABEL` field is used on `PART` and `SPRING` commands to assign readable names via `//` string concatenation. This feature is supported in Adams/View 2019 and later. If you encounter a parsing error on older releases, simply remove the `LABEL = ...` lines — they are cosmetic annotations only and have no effect on the model.

2. **Inertia**: `IP = 1.0E-6, 1.0E-6, 1.0E-6` sets near-zero principal moments of inertia (Ixx, Iyy, Izz). Adams requires non-zero inertia for dynamic parts; these values approximate a true point mass.

3. **FOR loop variable type**: In Adams CMD, `VARIABLE` values are real numbers. RTOI converts them to integers before using them in arithmetic or string construction — without it, expressions like `N*10` could produce floating-point IDs such as `10.0` rather than `10`, which may not match expected integer IDs in all Adams versions.

4. **Marker reuse**: The same connection marker (e.g., marker 21 on Mass 2) serves as both the J marker for Spring 101 and the I marker for Spring 102. This is intentional and valid in Adams.
