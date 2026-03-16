# One-Sided Floor Contact FUNCTION= Expression

## IMPACT Function Expression

The `IMPACT` function is the standard Adams/View function for one-sided contact. For a floor at Z = 0:

```
FUNCTION = IMPACT(DZ(cm_marker, ground_marker, ground_marker), &
                  VZ(cm_marker, ground_marker, ground_marker), &
                  0.0, 1.0E5, 1.5, 50.0, 0.1)
```

With concrete marker IDs (e.g., Part 2 CM = marker 21, Ground origin marker = 11):

```
FUNCTION = IMPACT(DZ(21, 11, 11), VZ(21, 11, 11), 0.0, 1.0E5, 1.5, 50.0, 0.1)
```

---

## Parameter Breakdown

| Argument  | Value              | Description                                                   |
|-----------|--------------------|---------------------------------------------------------------|
| `x`       | `DZ(21, 11, 11)`   | Z displacement of part CM in the global frame                 |
| `ẋ`       | `VZ(21, 11, 11)`   | Z velocity of part CM in the global frame                     |
| `x1`      | `0.0`              | Contact boundary — floor at Z = 0                             |
| `k`       | `1.0E5`            | Stiffness coefficient (N/mm)                                  |
| `e`       | `1.5`              | Force-displacement exponent (Hertzian-style nonlinear contact) |
| `c_max`   | `50.0`             | Maximum damping coefficient (N·s/mm)                          |
| `d`       | `0.1`              | Penetration depth at which full damping is applied (mm)        |

---

## How IMPACT Works

The IMPACT function evaluates penetration as `δ = x1 − x = 0 − DZ`. It activates only when `DZ < 0` (part CM below the floor):

$$F = k \cdot \delta^{e} + c_{\max} \cdot \text{STEP}(\delta,\ 0,\ 0,\ d,\ 1) \cdot \dot{\delta}_{\text{approach}}$$

- **Stiffness term**: `k · δ^e` — grows nonlinearly with penetration  
- **Damping term**: ramps from 0 at first contact (δ = 0) to `c_max` at δ = `d = 0.1 mm`, avoiding a damping impulse at touch-down  
- **One-sided**: force is exactly **zero** when `DZ ≥ 0`; IMPACT never produces an attractive (tensile) force

---

## Complete CMD Snippet

To apply this as an upward (+Z) force on a part using `GFORCE`:

```
!--- One-sided floor contact force at Z = 0 ---
GFORCE/1,
, I=21,                   ! CM marker of the falling part
, JFLOAT=31,              ! Floating reference marker (auto-follows I)
, RM=11,                  ! Reference marker defining the output frame (global)
, FX=0.0,
, FY=0.0,
, FZ=IMPACT(DZ(21,11,11), VZ(21,11,11), 0.0, 1.0E5, 1.5, 50.0, 0.1),
, TX=0.0,
, TY=0.0,
, TZ=0.0
```

Alternatively, using `SFORCE` (translational, Z-direction only) when I and J are aligned along Z:

```
SFORCE/1,
, I=21,
, J=11,
, TRANSLATION,
, FUNCTION=IMPACT(DZ(21,11,11), VZ(21,11,11), 0.0, 1.0E5, 1.5, 50.0, 0.1)
```

---

## Notes

- **Units**: Expression above assumes Adams units of **mm, N, s**. If your model uses SI (m, N, s), change `k` to `1.0E5` N/m, `c_max` to `50.0` N·s/m, and `d` to `0.0001` m (= 0.1 mm).
- **Marker syntax**: `DZ(i, j, k)` returns the Z component of the displacement of marker `i` relative to marker `j`, expressed in the coordinate system of marker `k`. Using the ground marker for both `j` and `k` gives the part's global Z coordinate.
- **Exponent `e = 1.5`**: Typical for metal-on-metal Hertzian contact. Values between 1.5 and 2.2 are common.
- **Penetration depth `d = 0.1 mm`**: Controls the damping ramp width. A smaller value makes the damping onset more abrupt; larger values provide a smoother transition.
- Replace marker IDs (`21`, `11`, `31`) with the actual IDs from your model.
