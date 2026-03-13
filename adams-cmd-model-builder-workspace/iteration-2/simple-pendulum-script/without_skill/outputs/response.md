# Simple Pendulum — Adams CMD Script

## Summary

I created an Adams/View CMD script (`pendulum.cmd`) to model a simple pendulum with the following specification:

- **Link**: Single rigid body, 200 mm long, 1 kg mass
- **Joint**: Revolute joint at the top end of the link, connecting it to the ground
- **Gravity**: −Y direction, g = 9806.65 mm/s² (standard gravity in mm units)
- **Initial condition**: Released from rest at 45 degrees from the vertical (displaced toward +X)
- **Simulation**: 5 seconds, 500 output steps

---

## Model Construction

### Units
`mm`, `kg`, `N`, `s` — consistent with Adams/View SI-mm conventions.

### Coordinate System
- Y-axis is vertical (up)
- Gravity acts in the −Y direction
- The pendulum swings in the XY plane, rotating about the Z-axis

### Initial Position (45 degrees from vertical)
At 45° from the downward vertical (−Y axis), displaced toward +X:

| Point | World coordinates (mm) |
|-------|------------------------|
| Pivot (top end) | (0, 0, 0) |
| Centre of mass | (70.711, −70.711, 0) |
| Tip (bottom end) | (141.421, −141.421, 0) |

Computed as:
- Link direction unit vector: `(sin 45°, −cos 45°, 0) = (0.7071, −0.7071, 0)`
- CM at 100 mm from pivot along this direction

### Part Frame Orientation
The LINK part's local X-axis is aligned with the link direction. This is achieved by rotating the part frame **−45° about the world Z-axis**:

```
R_z(−45°) · [1, 0, 0] = (cos(−45°), sin(−45°), 0) = (0.7071, −0.7071, 0)  ✓
```

This means markers defined at `(−100, 0, 0)` in the part's local frame (the pivot end) map to world position `(0, 0, 0)` at time zero:

```
World = CM_world + R_z(−45°) · [−100, 0, 0]
      = (70.711, −70.711, 0) + (−70.711, 70.711, 0) = (0, 0, 0)  ✓
```

### Mass Properties
Modelled as a uniform thin rod (axis along local X):

| Property | Value | Formula |
|----------|-------|---------|
| Mass | 1.0 kg | — |
| I_xx (along rod) | 1.0 kg·mm² | ≈ 0 for thin rod |
| I_yy (perpendicular) | 3333.33 kg·mm² | m·L²/12 |
| I_zz (perpendicular) | 3333.33 kg·mm² | m·L²/12 |

The pendulum rotates about the Z-axis; `I_zz = 3333.33 kg·mm²` is the governing planar inertia. Because I_yy = I_zz, the apparent inertia is constant throughout the swing.

### Geometry
A rectangular box (200 mm × 10 mm × 10 mm) centred on the CM marker is used for visualisation.

### Markers
| Marker | Part | Local position | World position at t=0 |
|--------|------|----------------|----------------------|
| `GRND_PIVOT` | ground | (0, 0, 0) | (0, 0, 0) |
| `LINK_PIVOT` | LINK | (−100, 0, 0) | (0, 0, 0) |

Both markers have default orientation `(0, 0, 0)` in their respective frames, so their Z-axes both point in the world Z direction — the revolute joint rotation axis.

### Revolute Joint
```
i_marker = .PENDULUM.LINK.LINK_PIVOT
j_marker = .PENDULUM.ground.GRND_PIVOT
```
The joint removes 5 DOFs (3 translational + 2 rotational), leaving one rotational DOF about the Z-axis.

---

## Expected Behaviour

The pendulum should exhibit simple harmonic-like motion (large-angle pendulum). The theoretical period for a point mass at length L = 200 mm from the pivot is:

```
L_eq = L/2 + I_cm / (m·L/2) = 100 + 3333.33 / (1 × 100) = 133.33 mm
T = 2π √(L_eq / g) = 2π √(133.33 / 9806.65) ≈ 0.732 s
```

For a uniform rod released from 45°, the motion will be non-linear (not simple harmonic), so the actual period will differ slightly from this small-angle estimate.

---

## Issues / Notes

- No issues encountered during script construction.
- The `simulation single_run transient` block at the end will initiate the simulation when the CMD file is executed in Adams/View. If only model creation is desired, that block can be commented out before importing.
- Gravity is defined using `force create body gravitational`; ensure Adams/View does not already have a gravity object defined when importing into an existing model.
