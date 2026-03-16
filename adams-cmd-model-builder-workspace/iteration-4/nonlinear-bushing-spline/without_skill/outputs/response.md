# Nonlinear Rubber Mount — Approach

## Strategy

A rubber mount with mixed linear/nonlinear stiffness requires two force elements:

1. **BUSHING element** — handles Y/Z translational stiffness (linear) and all three rotational stiffnesses (linear). The X stiffness is set to zero in this element.
2. **GFORCE (general force)** — handles the nonlinear X-direction translational stiffness by evaluating a cubic spline (AKISPL) at the current relative displacement DX(I,J,J).

This split approach is cleaner than replacing the entire bushing with six individual SFORCE elements, since the built-in BUSHING correctly handles small-angle rotational kinematics internally.

---

## Spline Data Element

The nonlinear force-displacement relationship is stored as an Adams SPLINE data element:

| Displacement (mm) | Force (N) |
|---|---|
| −10 | −8000 |
| −5  | −3000 |
|   0 |      0 |
|  +5 | +3000 |
| +10 | +8000 |

**Sign convention:** The spline stores the characteristic curve where `y = f(x)` is odd-symmetric. In the GFORCE expression the spline output is negated:

```
FX = -AKISPL(DX(I, J, J), 0, spline)
```

- At DX = +5 mm → AKISPL returns +3000 → FX on subframe = −3000 N (restoring)
- At DX = −5 mm → AKISPL returns −3000 → FX on subframe = +3000 N (restoring)

---

## Unit Conversions

The rotational stiffness is specified as 200 N·mm/deg. Adams expressions and bushing stiffness arrays expect consistent internal units. In an MMKS model (mm, kg, N, s), angles are in **radians** internally:

```
K_rot = 200 N·mm/deg × (180/π) deg/rad = 11459.156 N·mm/rad
```

This value is used directly in the `rotational_stiffness` array of the BUSHING element.

---

## Model Structure

```
.rubber_mount_model
  ├── ground                           (Adams built-in ground part)
  │     └── ground_ref                 (fixed-joint marker)
  ├── chassis                          (rigid, 10 kg, fixed to ground)
  │     ├── chassis_cm                 (CM / fixed-joint I-marker)
  │     └── mount_j                    (J-side bushing marker at z=50 mm)
  ├── subframe                         (rigid, 10 kg, free to move)
  │     └── mount_i                    (I-side bushing marker at z=50 mm)
  ├── x_stiffness_spline               (DATA_ELEMENT spline)
  ├── chassis_ground                   (FIXED joint)
  ├── rubber_mount_linear              (BUSHING: KY=KZ=5000, KROTX/Y/Z=11459.156)
  └── rubber_mount_x_nonlinear         (GFORCE: FX only from spline)
```

---

## Limitations / Notes

- **No damping** is specified in the problem, so all damping coefficients are set to zero. Real rubber mounts have significant viscous damping; add `damping` and `rotational_damping` arrays as needed.
- The BUSHING X stiffness is set to zero to avoid double-counting. The GFORCE exclusively provides the X restoring force.
- The AKISPL interpolation will perform cubic Akima interpolation between the five data points. The spline is only defined between −10 mm and +10 mm; dynamic simulations that exceed this range will extrapolate linearly.
- Part centers of mass are placed at their respective reference origins. For a real model, geometry and inertia offsets should reflect the actual CAD.
