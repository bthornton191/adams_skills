# Rubber Mount (Nonlinear Bushing) — Adams CMD Script

## Summary

The script `nonlinear_bushing.cmd` models a rubber mount connecting a **chassis** (fixed to ground) to a **subframe** using an Adams **GFORCE** element driven by a **SPLINE** look-up table for the nonlinear X-direction stiffness, and algebraic expressions for the linear Y/Z and rotational directions.

---

## Modelling approach

### Units

`MMKS` — millimetre, kilogram, Newton, second.  All geometry inputs are in mm, mass in kg, force in N, and angular stiffness in N·mm/deg.

### Model layout

```
[Ground/world]
     |
  [FIXED JOINT]
     |
 [Chassis]  (CM at x=0 mm)
     |
  marker 22 @ x=100 mm  (chassis bushing attachment, J-marker)
     |
  [GFORCE — rubber mount]
     |
  marker 31 @ x=100 mm  (subframe bushing attachment, I-marker)
     |
 [Subframe] (CM at x=200 mm)
```

### Parts

| Entity | Adams ID | Mass | Ixx = Iyy = Izz | Constraint |
|--------|----------|------|-----------------|------------|
| Chassis  | PART/2 | 10 kg | 1000 kg·mm² | Fixed to ground (JOINT/1, TYPE=FIXED) |
| Subframe | PART/3 | 10 kg | 1000 kg·mm² | Free; restrained by rubber mount |

Products of inertia are zero for both parts (symmetric bodies).

---

## Elastic joint implementation

### Why GFORCE, not BUSHING?

Adams' built-in **BUSHING** element supports only **linear** stiffness (constant K values).  Because the X-direction stiffness here is nonlinear, the mount is implemented as a **GFORCE** whose force expressions reference an **Akima spline** for X and linear formulae for the remaining five DOFs.

### SPLINE (SPLINE/1)

```
X  (mm) :  -10    -5     0     5    10
Y  (N)  : -8000 -3000    0  3000  8000
```

`LINEAR_EXTRAPOLATE = ON` gives a tangent-slope continuation beyond ±10 mm, avoiding a hard discontinuity at the table boundary.

The `AKISPL` function performs **Akima spline** interpolation, which passes exactly through all data points while minimising spurious oscillations between them (unlike cubic splines, which can overshoot with asymmetric data).

### GFORCE force expressions

Relative displacements and rotations are measured with marker 31 (subframe) **relative to** marker 22 (chassis), **resolved in the chassis frame** (RMID = 22):

| DOF | Expression | Notes |
|-----|-----------|-------|
| FX (N) | `-AKISPL(DX(31,22,22), 0, 1)` | Nonlinear; spline negated → restoring |
| FY (N) | `-5000.0 * DY(31,22,22)` | Linear 5000 N/mm |
| FZ (N) | `-5000.0 * DZ(31,22,22)` | Linear 5000 N/mm |
| TX (N·mm) | `-200.0 * RTOD * AX(31,22)` | 200 N·mm/deg × RTOD converts to N·mm/rad |
| TY (N·mm) | `-200.0 * RTOD * AY(31,22)` | Same stiffness about Y |
| TZ (N·mm) | `-200.0 * RTOD * AZ(31,22)` | Same stiffness about Z |

**Restoring sign convention:** A positive X displacement (`DX > 0`) causes the spline to return a positive value; negating it gives a negative FX on the subframe, pulling it back toward zero — the physically correct restoring behaviour.

**Rotational unit conversion:**  
Adams runtime functions `AX`, `AY`, `AZ` return angles in **radians**.  
The given stiffness is 200 N·mm/deg.

$$k_\text{rot,rad} = \frac{200 \text{ N·mm/deg}}{(\pi/180) \text{ rad/deg}} = 200 \times \frac{180}{\pi} \approx 11{,}459 \text{ N·mm/rad}$$

In Adams notation: `RTOD` is the built-in constant $180/\pi \approx 57.2958$, so:

$$T_X = -200 \times \text{RTOD} \times A_X$$

---

## Key modelling decisions

1. **Single GFORCE vs. BUSHING + GFORCE hybrid.**  A single GFORCE covering all six DOFs is cleaner and avoids force superposition artefacts.  A hybrid approach (BUSHING for linear DOFs, GFORCE for X) would work but introduces two overlapping force elements.

2. **RMID = chassis bushing marker.**  The force/torque components are resolved in the chassis (J) frame.  Since stiffness is defined in the mount's local body frame (which here coincides with the chassis frame), this is physically correct.  Were the chassis free to move the same choice would still be appropriate.

3. **J = 22 (non-floating).**  Because the chassis is rigidly fixed to ground, the bushing attachment point on the chassis never moves in the global frame.  A floating J-marker (JFLOAT) would produce identical results here; a fixed J is simpler.

4. **No damping.**  The problem specification defines stiffness only.  A real rubber mount would include viscous or structural damping terms (e.g. `+ CX * VX(31,22,22)` in FX).  These can be added without changing the stiffness representation.

5. **Small-angle Euler decomposition for rotations.**  `AX`, `AY`, `AZ` decompose the relative orientation using Euler angles and are reliable for the small rotational deflections typical of automotive rubber mounts.  For large-angle applications a different kinematic description (e.g. quaternions via user subroutine) would be warranted.

---

## Script entity index

| Adams entity | ID | Description |
|---|---|---|
| `PART` | 1 | Ground (inertial reference) |
| `PART` | 2 | Chassis |
| `PART` | 3 | Subframe |
| `MARKER` | 10 | Ground origin |
| `MARKER` | 20 | Chassis CM (at origin) |
| `MARKER` | 21 | Chassis ground-ref (fixed-joint I-marker) |
| `MARKER` | 22 | Chassis bushing J-marker / RMID |
| `MARKER` | 30 | Subframe CM |
| `MARKER` | 31 | Subframe bushing I-marker |
| `JOINT` | 1 | Fixed joint — chassis to ground |
| `SPLINE` | 1 | X nonlinear force-displacement table |
| `GFORCE` | 1 | Rubber mount elastic joint |
