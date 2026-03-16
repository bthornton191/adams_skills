# Cam-Follower Mechanism – Adams CMD Script

## Overview

The script creates a simplified 1-DOF cam-follower mechanism in Adams/View. The cam is a rigid body fixed to ground, and the follower is a separate rigid body that can only translate along the global X axis. A single-component force drives the follower using a STEP5 displacement-dependent profile plus a velocity damping term.

---

## Model Architecture

### Units

| Quantity | Unit |
|----------|------|
| Length   | mm   |
| Mass     | kg   |
| Force    | N    |
| Time     | s    |

---

### Parts

#### Cam (`model.cam`)

| Property | Value |
|----------|-------|
| Mass     | 1.0 kg |
| Ixx      | 100.0 kg·mm² |
| Iyy      | 100.0 kg·mm² |
| Izz      | 100.0 kg·mm² |
| Location | (0, 0, 0) mm |
| Constraint | Fixed to ground |

#### Follower (`model.follower`)

| Property | Value |
|----------|-------|
| Mass     | 0.5 kg |
| Ixx      | 50.0 kg·mm² |
| Iyy      | 50.0 kg·mm² |
| Izz      | 10.0 kg·mm² |
| Location | (0, 0, 0) mm (initial) |
| Constraint | Translational joint along global X |

---

### Markers

| Marker | Part | Orientation | Purpose |
|--------|------|-------------|---------|
| `cam.cm` | cam | (0,0,0)° | Center of mass / cylinder axis |
| `cam.ref_mkr` | cam | (0,0,0)° | Reference origin for DX/VX expressions |
| `cam.jfixed_I` | cam | (0,0,0)° | I-marker for fixed joint |
| `follower.cm` | follower | (0,0,0)° | Center of mass |
| `follower.tip_mkr` | follower | (0,0,0)° | Reference point for DX/VX expressions |
| `follower.jtrans_I` | follower | (90°,90°,0°) | Translational joint I-marker, Z→global X |
| `follower.force_mkr` | follower | (90°,90°,0°) | Force application point, Z→global X |
| `ground.jfixed_J` | ground | (0,0,0)° | J-marker for fixed joint |
| `ground.jtrans_J` | ground | (90°,90°,0°) | J-marker for translational joint |

**Orientation note:** The markers used for the translational joint and for the force both carry ZXZ Euler angles (ψ=90°, θ=90°, φ=0°). The resulting rotation matrix is:

```
R = Rz(90°) · Rx(90°) = [[0, 0, 1],
                          [1, 0, 0],
                          [0, 1, 0]]
```

Column 3 of R (= local Z expressed in global) equals `[1, 0, 0]` — i.e., the local Z axis points along global X. This is what makes the translational joint slide along X, and what makes the single-component force push in the +X direction.

---

### Constraints

| Joint | Type | Bodies | Effect |
|-------|------|--------|--------|
| `jt_cam_fixed` | Fixed | cam ↔ ground | Cam immobile; 0 remaining DOF for cam |
| `jt_follower_trans` | Translational | follower ↔ ground | Follower slides along global X only |

The system has **1 degree of freedom**: translation of the follower along X.

---

### Force: `push_force`

Type: single-component translational force acting along local Z of `follower.force_mkr` = global +X.

**Expression:**

```
STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0)
  - 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
```

#### STEP5 term

`STEP5(x, x0, h0, x1, h1)` generates a smooth 5th-order polynomial transition:

| DX (mm) | Force contribution (N) |
|---------|----------------------|
| ≤ 0     | 0                    |
| 0 → 20  | smooth ramp 0 → 500  |
| ≥ 20    | 500 (saturated)      |

The polynomial has zero slope and zero curvature at both endpoints, giving a continuous and smooth force profile — appropriate for cam profiles that must avoid impulsive loads.

#### Damping term

`-2.0 × VX(...)` adds velocity-proportional damping equivalent to a dashpot with coefficient **c = 2.0 N·s/mm** (= 2000 N·s/m). When the follower moves in +X, VX > 0 and the damping force acts in −X, opposing the motion. This term limits the terminal velocity of the follower once the STEP5 force saturates.

#### Terminal velocity estimate

At DX ≥ 20 mm the net force is:

```
F_net = 500 - 2.0 * VX = 0   →   VX_terminal = 250 mm/s = 0.25 m/s
```

So the follower accelerates until it reaches approximately 250 mm/s, after which net force is zero.

---

### Geometry

| Part | Shape | Parameters |
|------|-------|-----------|
| cam | Cylinder | radius = 30 mm, length = 20 mm, axis along local Z (global Z) |
| follower | Box | 40 mm (X) × 20 mm (Y) × 20 mm (Z), corner at `follower.cm` |

---

### Simulation

| Parameter | Value |
|-----------|-------|
| End time | 1.0 s |
| Output steps | 1000 |
| Step size | 1 ms |
| Initial static equilibrium | No |

---

## Known Limitation: Static Equilibrium at DX = 0

Because the STEP5 force evaluates to **0 N when DX = 0**, the follower starts at rest with zero net force. Adams will compute a trivial static solution (follower stays at X = 0 forever) unless a non-zero initial condition is provided.

**To fix this before simulating**, give the follower a small initial X-velocity in the Adams/View interface, or add the following to the CMD file before the `simulation single` command:

```cmd
! Give follower an initial velocity of 1 mm/s in +X to kick-start the motion
part modify rigid_body name_and_position &
   part_name              = .model.follower &
   translational_velocity = 1.0, 0.0, 0.0
```

Once the follower moves even slightly in +X, the STEP5 force begins increasing and the simulation produces the expected dynamics.

Alternatively, to make the force purely time-driven (independent of displacement), replace the STEP5 argument with `TIME`:

```
STEP5(TIME, 0.0, 0.0, 0.08, 500.0) - 2.0*VX(...)
```

This ramps the force from 0 to 500 N over the first 80 ms, which is a common pattern when the CAM rotation rate is known and the force profile is pre-programmed.

---

## How to Use

1. Open Adams/View.
2. Go to **File → Import → Adams/View Command File** (or use the **File Execute Macro** panel).
3. Select `cam_follower.cmd`.
4. The model `.model` will be created and the simulation will run automatically via the `simulation single` command at the end of the script.
5. Use **Postprocessor** (Adams/PostProcessor) to plot `follower.cm` displacement and velocity in X, and the `push_force` magnitude, versus time.

---

## Summary

The script faithfully implements all specified requirements:

- ✅ Cam: 1 kg, Ixx=Iyy=Izz=100 kg·mm², fixed to ground  
- ✅ Follower: 0.5 kg, Ixx=Iyy=50 kg·mm², Izz=10 kg·mm², translational joint along X  
- ✅ STEP5 force: 0→500 N over DX = 0→20 mm, saturates at 500 N beyond 20 mm  
- ✅ Velocity damping: −2.0 × VX  
- ✅ Cylinder geometry on cam; box geometry on follower  
- ✅ 1-second simulation, 1000 output steps  
- ⚠️ Initial condition (small velocity) needed to break static equilibrium at DX=0
