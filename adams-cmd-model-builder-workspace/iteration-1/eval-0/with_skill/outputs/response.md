# Adams CMD Script: Simple Pendulum

## Model Description

A single rigid rod (200 mm long, 1 kg uniform mass) pinned to ground at its top end by a revolute joint. Gravity acts in the −Y direction. The pendulum is released from rest at 45° from the downward vertical.

---

## Model Topology

```
.PENDULUM
├── ground
│   └── M_PIVOT          origin (0, 0, 0) — fixed pivot attachment point
└── LINK                 rigid part; origin at pivot
    ├── cm               auto-created; repositioned to (0, −100, 0)
    ├── M_PIN            top of rod — (0, 0, 0) in part frame
    ├── M_CM             centre of mass — (0, −100, 0) in part frame
    ├── M_TIP            bottom of rod — (0, −200, 0) in part frame
    └── M_ROD_VIS        geometry helper; Z axis points in −Y direction
```

---

## Design Notes

### Units
`mm`, `newton`, `kg`, `sec`. Gravity is therefore `−9806.65 mm/s²` (9.80665 m/s² × 1000 mm/m).

### Part placement and build order
The LINK part origin is placed at the pivot (0, 0, 0). In the default orientation (0°) the rod hangs straight down: M_PIN at the origin, M_TIP at (0, −200, 0). The initial 45° offset is applied **after** the joint is created so that Adams records it as an initial condition, not as a permanent geometry offset.

### Mass properties
For a uniform rigid rod of mass *m* = 1 kg and length *L* = 200 mm, with the rod axis along the part Y direction, the principal moments of inertia about the centre of mass are:

| Component | Formula | Value |
|-----------|---------|-------|
| $I_{xx}$ (bending, rod ⊥ X) | $\frac{1}{12}mL^2$ | **3333.33 kg·mm²** |
| $I_{yy}$ (torsion, rod ∥ Y) | ≈ 0 (thin rod) | **0.0 kg·mm²** |
| $I_{zz}$ (swing, rod ⊥ Z) | $\frac{1}{12}mL^2$ | **3333.33 kg·mm²** |

The pendulum swings in the XY plane (rotation about Z), so $I_{zz,cm} = 3333.33\ \text{kg·mm}^2$ is the physically important value. By the parallel-axis theorem the effective inertia about the pivot is:

$$I_{pin} = I_{zz,cm} + m\left(\tfrac{L}{2}\right)^2 = 3333.33 + 1 \times 100^2 = 13\,333.33\ \text{kg·mm}^2 = \tfrac{1}{3}mL^2\ ✓$$

### Revolute joint
A revolute joint between `LINK.M_PIN` (I marker, moving part) and `ground.M_PIVOT` (J marker, fixed part) locks all translational DOF and removes two of three rotational DOF, leaving one rotational DOF about the J-marker Z axis (= global Z). The pendulum is therefore free to swing only in the XY plane.

### Initial condition — 45° release
```cmd
part modify rigid_body name_and_position &
    part_name   = .PENDULUM.LINK        &
    orientation = 0.0D, 0.0D, 45.0D
```
Setting `phi = 45D` in the Body-313 Euler sequence rotates the part 45° counter-clockwise about Z. Starting from the down-hanging position the tip moves to approximately (141.4, −141.4, 0) mm — 45° from the vertical. No initial velocity is specified, so the pendulum is released from rest.

### Cylinder geometry orientation
Adams `geometry create shape cylinder` extends the cylinder along the **local Z axis** of its `center_marker`. Because the rod lies along the part −Y axis we use a dedicated marker `M_ROD_VIS` with `orientation = 0.0D, 90.0D, 0.0D`. The Body-313 Euler sequence (Z–X–Z) with θ = 90° rotates local Z onto global −Y, so the cylinder correctly extends from the pin to the tip along the rod.

### Expected simulation behaviour
Simulating for 2 s at 1 ms step size gives approximately 2–3 full swings:

| Quantity | Value |
|----------|-------|
| Small-angle period $T \approx 2\pi\sqrt{I_{pin}/(mgd)}$ | ≈ 0.733 s |
| Corrected period at 45° amplitude (elliptic integral) | ≈ 0.759 s |
| Maximum tip speed (at lowest point, from energy conservation) | ≈ 538 mm/s |

Energy conservation check for max tip speed: $v_{tip,max} = \sqrt{2g \cdot \frac{L}{2}(1 - \cos 45°)} \cdot \frac{L}{L/2}$  
More precisely: $\omega_{max} = \sqrt{2 m g (L/2)(1-\cos\alpha)/I_{pin}}$, $v_{tip} = \omega_{max} \cdot L$.

---

## CMD Script

```cmd
! ============================================================
! Simple Pendulum — Adams CMD Script
!
! A single 200 mm rigid link pinned to ground at the top end,
! released from 45° and allowed to swing freely under gravity.
! Gravity acts in the -Y direction.
!
! Model structure:
!   .PENDULUM
!   ├── ground
!   │   └── M_PIVOT          (pivot attachment point, at origin)
!   └── LINK
!       ├── cm               (auto-created; repositioned to midpoint)
!       ├── M_PIN            (upper end — coincides with M_PIVOT)
!       ├── M_CM             (center of mass, 100 mm below pin)
!       ├── M_TIP            (lower end, 200 mm below pin)
!       └── M_ROD_VIS        (geometry reference; Z axis → −Y direction)
!
! Pendulum properties:
!   Length        L = 200 mm
!   Mass          m = 1 kg  (uniform rod)
!   Ixx about CM  = (1/12)*m*L² = 3333.33 kg·mm²  (bending about X)
!   Iyy about CM  = 0.0 kg·mm²                     (thin-rod torsion)
!   Izz about CM  = (1/12)*m*L² = 3333.33 kg·mm²  (pendulum swing about Z)
!   Izz about pin = Izz_cm + m*(L/2)² = 13333.33 kg·mm²
!                 = (1/3)*m*L²  ✓
!   Release angle α = 45°  (from vertical, no initial velocity)
!   Period         T ≈ 2π√(Izz_pin / (m*g*(L/2)))
!                    ≈ 2π√(13333.33 / (1*9806.65*100))
!                    ≈ 0.733 s  (small-angle period; 45° elongates slightly)
! ============================================================


! --- 1. Model and units ---

model create model_name = PENDULUM

defaults units &
    length = mm    &
    force  = newton &
    mass   = kg    &
    time   = sec


! --- 2. Gravity (-Y direction, g = 9806.65 mm/s²) ---

forces create body_force gravity_field &
    gravity_field_name  = .PENDULUM.GRAVITY &
    x_component_gravity = 0.0      &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0


! --- 3. Ground marker at the pivot point ---

marker create &
    marker_name = .PENDULUM.ground.M_PIVOT &
    adams_id    = 1                        &
    location    = 0.0, 0.0, 0.0           &
    orientation = 0.0D, 0.0D, 0.0D


! --- 4. Create the link part ---
!     Part origin is placed at the pivot.
!     In equilibrium the rod hangs straight down (−Y direction).

part create rigid_body name_and_position &
    part_name   = .PENDULUM.LINK        &
    adams_id    = 2                     &
    location    = 0.0, 0.0, 0.0        &
    orientation = 0.0D, 0.0D, 0.0D

! Mass properties — uniform rigid rod, 1 kg, 200 mm long, rod axis along Y:
!   ixx = (1/12)*m*L² = 3333.33 kg·mm²   (bending, rod ⊥ X)
!   iyy = 0.0 kg·mm²                      (torsion, rod ∥ Y — thin rod)
!   izz = (1/12)*m*L² = 3333.33 kg·mm²   (pendulum swing, rod ⊥ Z)
part create rigid_body mass_properties &
    part_name             = .PENDULUM.LINK &
    mass                  = 1.0            &
    center_of_mass_marker = .PENDULUM.LINK.cm &
    ixx                   = 3333.33        &
    iyy                   = 0.0            &
    izz                   = 3333.33        &
    ixy                   = 0.0            &
    iyz                   = 0.0            &
    izx                   = 0.0


! --- 5. Markers on the link ---

! Pin marker at the top of the rod (coincident with M_PIVOT at part origin)
marker create &
    marker_name = .PENDULUM.LINK.M_PIN  &
    adams_id    = 2                     &
    location    = 0.0,    0.0, 0.0      &
    orientation = 0.0D, 0.0D, 0.0D

! Center-of-mass marker — 100 mm below pin along rod (part −Y)
marker create &
    marker_name = .PENDULUM.LINK.M_CM   &
    adams_id    = 3                     &
    location    = 0.0, -100.0, 0.0      &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker — 200 mm below pin (bottom end of rod)
marker create &
    marker_name = .PENDULUM.LINK.M_TIP  &
    adams_id    = 4                     &
    location    = 0.0, -200.0, 0.0      &
    orientation = 0.0D, 0.0D, 0.0D

! Visualization marker for cylinder geometry:
!   At pin location; orientation 0D, 90D, 0D orients the marker's
!   local Z axis to point in the part −Y direction (Body-313 Euler:
!   90° rotation about X maps Z → −Y).  The cylinder then extends
!   cleanly along the rod from pin to tip.
marker create &
    marker_name = .PENDULUM.LINK.M_ROD_VIS &
    adams_id    = 5                        &
    location    = 0.0, 0.0, 0.0           &
    orientation = 0.0D, 90.0D, 0.0D

! Reposition the auto-created cm marker from part origin to actual CM
marker modify &
    marker_name = .PENDULUM.LINK.cm &
    location    = 0.0, -100.0, 0.0


! --- 6. Revolute joint at the pivot ---
!     Allows rotation about the Z-axis of M_PIVOT (= global Z).
!     I marker is on the moving LINK; J marker is on fixed ground.

constraint create joint revolute &
    joint_name    = .PENDULUM.REV_PIVOT        &
    adams_id      = 1                          &
    i_marker_name = .PENDULUM.LINK.M_PIN       &
    j_marker_name = .PENDULUM.ground.M_PIVOT


! --- 7. Initial conditions: release from 45° ---
!     Rotate the link 45° about Z (CCW when viewed from +Z).
!     The rod starts at 45° from the downward vertical:
!       tip global position ≈ (141.4, −141.4, 0) mm
!     Zero initial angular velocity (released from rest).

part modify rigid_body name_and_position &
    part_name   = .PENDULUM.LINK        &
    orientation = 0.0D, 0.0D, 45.0D


! --- 8. Visualization geometry (purely cosmetic; no effect on dynamics) ---

! Sphere at the tip to represent the pendulum bob (r = 12 mm)
geometry create shape sphere &
    sphere_name   = .PENDULUM.LINK.SPHERE_BOB &
    adams_id      = 1                         &
    part_name     = .PENDULUM.LINK            &
    center_marker = .PENDULUM.LINK.M_TIP      &
    radius        = 12.0

! Cylinder for the rod body; extends 200 mm along M_ROD_VIS local Z (= part −Y)
geometry create shape cylinder                   &
    cylinder_name            = .PENDULUM.LINK.CYL_ROD &
    adams_id                 = 2                      &
    part_name                = .PENDULUM.LINK         &
    center_marker            = .PENDULUM.LINK.M_ROD_VIS &
    length                   = 200.0                  &
    radius                   = 4.0                    &
    angle_extent             = 360.0D                 &
    side_count_for_perimeter = 16


! ============================================================
! To simulate (2 s, 1 ms steps — gives ~3 full swings):
!
!   simulate transient end_time = 2.0 step_size = 0.001
!
! Expected behaviour:
!   - Pendulum released from 45° from vertical with zero velocity.
!   - Swings freely under gravity; no damping — energy is conserved.
!   - Small-angle period T ≈ 0.733 s; 45° amplitude period slightly
!     longer (~0.759 s by elliptic integral).
!   - Maximum tip speed occurs at the lowest point (θ = 0).
! ============================================================
```

---

## How to Load and Run

1. Open **Adams View**.
2. Go to **File → Import → Adams View Command File** (`.cmd`).
3. Select `pendulum.cmd`.
4. In the **Simulate** panel set **End Time = 2.0 s**, **Step Size = 0.001 s**, then click **Start**.

Alternatively, paste the simulation command directly into the Adams View command line after loading the model:

```cmd
simulate transient end_time = 2.0 step_size = 0.001
```

---

## Verification Checklist

| Check | Expected |
|-------|----------|
| DOF count | 1 (revolute removes 5 from 6, ground and gravity add none) |
| Initial angle | 45° — tip at ≈ (141.4, −141.4, 0) mm |
| CM location | (0, −100, 0) mm in part frame |
| Gravity direction | −Y |
| Period (animation) | ≈ 0.73–0.76 s |
| Energy (no damping) | Total mechanical energy conserved throughout |
