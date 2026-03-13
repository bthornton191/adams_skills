# Simple Pendulum — Adams CMD Script

## Model Description

A single rigid link of length 200 mm and mass 1 kg, pinned to the ground at its top end by a revolute joint. Gravity acts in the −Y direction. The pendulum is released from rest at 45° from the vertical.

---

## Coordinate System and Setup

| Quantity | Value |
|---|---|
| Length | mm |
| Mass | kg |
| Force | Newton |
| Time | s |
| Angle | deg |
| Gravity | −Y, 9806.65 mm/s² |

The pivot is fixed at the **global origin (0, 0, 0)**. The pendulum swings in the global XY-plane and rotates about the global Z-axis.

---

## Initial Configuration (45° from Vertical)

At release the link is tilted 45° from the downward vertical (−Y axis) toward +X:

| Point | Global position (mm) |
|---|---|
| Pivot end (top) | (0.000, 0.000, 0) |
| Centre of mass | (70.711, −70.711, 0) |
| Free end (bottom) | (141.421, −141.421, 0) |

The CM coordinates are derived from:

$$x_{cm} = \frac{L}{2}\sin(45°) = 100 \times 0.7071 = 70.711 \text{ mm}$$

$$y_{cm} = -\frac{L}{2}\cos(45°) = -100 \times 0.7071 = -70.711 \text{ mm}$$

---

## Part Properties

### Mass and Geometry

- **Mass:** 1 kg, uniformly distributed
- **Length:** 200 mm
- **Visualisation:** rectangular cross-section, 10 mm × 10 mm

### Moments of Inertia (about the CM, in the body frame)

The body X-axis is defined along the rod (from pivot toward free end). For a uniform slender rod of length $L = 200\text{ mm}$, mass $m = 1\text{ kg}$:

| Component | Axis | Formula | Value |
|---|---|---|---|
| $I_{xx}$ | Along rod | ≈ 0 | 1.0 kg·mm² *(nominal)* |
| $I_{yy}$ | ⊥ to rod | $\frac{1}{12}mL^2$ | 3333.33 kg·mm² |
| $I_{zz}$ | ⊥ to rod | $\frac{1}{12}mL^2$ | 3333.33 kg·mm² |

$I_{zz}$ (body Z = global Z = rotation axis) is the governing inertia for pendulum dynamics. The parallel-axis theorem confirms the moment of inertia about the pivot:

$$I_\text{pivot} = I_{zz,cm} + m \cdot d^2 = 3333.33 + 1 \times 100^2 = 13{,}333.33 \text{ kg·mm}^2 = \frac{1}{3}mL^2 \checkmark$$

---

## Part Orientation

The part is created with its body frame **rotated −45° about the global Z-axis** (Body 3-1-3 Euler angles: `−45, 0, 0`). This maps the body X-axis onto the direction $(\sin 45°,\ -\cos 45°,\ 0)$, i.e., along the link at the 45° starting angle.

---

## Joint and Constraints

A **revolute joint** (`rev_joint`) connects the pivot marker on the link to a ground-fixed marker at the origin. Both markers have their Z-axes aligned with the global Z-axis, so the joint allows rotation about Z only — exactly the single degree of freedom required.

---

## Validation: Small-Oscillation Period

For a uniform rod pendulum the linearised period is:

$$T = 2\pi\sqrt{\frac{I_\text{pivot}}{mgd}} = 2\pi\sqrt{\frac{13{,}333.33}{1 \times 9806.65 \times 100}} = 2\pi\sqrt{0.01360} \approx 0.733 \text{ s}$$

At the relatively large 45° release angle a small correction applies; the true period will be slightly longer (~2.5% by the elliptic-integral approximation), so expect a swing period of approximately **0.75 s**.

---

## Adams CMD Script

```cmd
! ==============================================================
! Simple Pendulum Model — Adams/View Command File
!
! Model properties:
!   Link length  : 200 mm (uniform slender rod)
!   Link mass    : 1 kg
!   Pivot point  : Global origin (0, 0, 0) — pinned to ground
!   Joint type   : Revolute (rotation about global Z-axis)
!   Gravity      : −Y direction, 9806.65 mm/s²
!   Initial angle: 45° from vertical (−Y axis), tilted toward +X
!
! Units: mm, kg, N, s, deg
!
! Initial global positions at 45° release angle:
!   Pivot end (top) : (  0.000,   0.000, 0)
!   Centre of mass  : ( 70.711, -70.711, 0)
!   Free end (bot)  : (141.421, -141.421, 0)
! ==============================================================


! --------------------------------------------------------------
! 1. Create model and set working units
! --------------------------------------------------------------
model create  &
   model_name = simple_pendulum

defaults units  &
   length = mm  &
   angle = deg  &
   force = newton  &
   mass = kg  &
   time = sec


! --------------------------------------------------------------
! 2. Gravity  (9806.65 mm/s² in the −Y direction)
! --------------------------------------------------------------
force create body gravitational  &
   model_name = .simple_pendulum  &
   x_component_gravity = 0.0  &
   y_component_gravity = -9806.65  &
   z_component_gravity = 0.0


! --------------------------------------------------------------
! 3. Pendulum link part
!
!    The CM is placed at the 45° initial position:
!      x = (L/2)·sin(45°) =  70.711 mm
!      y = (L/2)·cos(45°) = −70.711 mm  (below pivot)
!
!    Orientation: body X-axis points along the link
!    (from pivot toward free end).
!    A rotation of −45° about the global Z-axis maps global X
!    onto the direction (sin 45°, −cos 45°, 0) = link direction
!    at 45° from −Y vertical.
!    → Body 3-1-3 Euler angles: (psi = −45°, theta = 0°, phi = 0°)
! --------------------------------------------------------------
part create rigid_body name_and_position  &
   part_name = .simple_pendulum.link  &
   location = 70.711, -70.711, 0.0  &
   orientation = -45.0, 0.0, 0.0

! Inertia of a uniform slender rod about its CM (L = 200 mm, m = 1 kg):
!   Ixx  (along rod — body X-axis)    ≈ 0  →  set to 1.0 kg·mm²
!   Iyy = Izz (perpendicular to rod)  = (1/12)·m·L²
!                                     = (1/12)·1·200²
!                                     = 3333.33 kg·mm²
part modify rigid_body mass_properties  &
   part_name = .simple_pendulum.link  &
   mass = 1.0  &
   center_of_mass_marker = .simple_pendulum.link.cm  &
   ixx = 1.0  &
   iyy = 3333.333  &
   izz = 3333.333  &
   ixy = 0.0  &
   izx = 0.0  &
   iyz = 0.0


! --------------------------------------------------------------
! 4. Markers
!    All locations are given in global (ground) coordinates
!    at the 45° initial configuration.
! --------------------------------------------------------------

! I-marker on the link at the pivot end — also used for the joint
marker create  &
   marker_name = .simple_pendulum.link.pivot_I  &
   part_name = .simple_pendulum.link  &
   location = 0.0, 0.0, 0.0  &
   orientation = 0.0, 0.0, 0.0

! Marker on the link at the free (bottom) end — for geometry
marker create  &
   marker_name = .simple_pendulum.link.free_end  &
   part_name = .simple_pendulum.link  &
   location = 141.421, -141.421, 0.0  &
   orientation = 0.0, 0.0, 0.0

! J-marker on ground at the pivot point
marker create  &
   marker_name = .simple_pendulum.ground.pivot_J  &
   part_name = .simple_pendulum.ground  &
   location = 0.0, 0.0, 0.0  &
   orientation = 0.0, 0.0, 0.0


! --------------------------------------------------------------
! 5. Link geometry  (rectangular cross-section: 10 mm × 10 mm)
! --------------------------------------------------------------
geometry create shape link  &
   part_name = .simple_pendulum.link  &
   link_name = .simple_pendulum.link.geom  &
   i_marker_name = .simple_pendulum.link.pivot_I  &
   j_marker_name = .simple_pendulum.link.free_end  &
   width = 10.0  &
   depth = 10.0


! --------------------------------------------------------------
! 6. Revolute joint
! --------------------------------------------------------------
constraint create joint revolute  &
   joint_name = .simple_pendulum.rev_joint  &
   i_marker_name = .simple_pendulum.link.pivot_I  &
   j_marker_name = .simple_pendulum.ground.pivot_J


! --------------------------------------------------------------
! 7. Transient simulation  (5 s, 500 output steps)
! --------------------------------------------------------------
simulation single_run transient  &
   sim_name = .simple_pendulum.last_run  &
   time_duration = 5.0  &
   number_of_steps = 500  &
   model_name = .simple_pendulum
```

---

## How to Import into Adams/View

1. Open Adams/View.
2. **File → Import → Adams/View Command File…**
3. Select `pendulum.cmd`.
4. Adams will create the `simple_pendulum` model, build the geometry, apply the joint and gravity, and — if the simulation block is present — run a 5-second transient analysis automatically.

To run interactively instead, remove or comment out the `simulation single_run transient` block and use **Simulate → Interactive Simulation**.

---

## Design Decisions and Assumptions

| Decision | Rationale |
|---|---|
| 45° initial condition set by part position | Placing the CM and markers at their 45° global positions is the most portable approach across Adams versions, requiring no joint IC syntax. |
| Body X-axis along the link | Keeps the inertia tensor diagonal with Ixx along the (physically small) rod axis, making mass properties intuitive. |
| $I_{xx} = 1.0$ not 0 | Adams will warn or error on a zero principal inertia; 1.0 kg·mm² is negligible relative to 3333 kg·mm² and has no practical effect on the dynamics. |
| Marker orientations = (0, 0, 0) | Both joint markers have Z aligned with global Z, so the revolute joint correctly constrains rotation about the global Z-axis. |
| `geometry create shape link` | Creates a built-in Adams "link" primitive between the two end markers; visible in the Adams/View viewport without needing a separate part geometry. |
| Gravity = 9806.65 mm/s² | $g = 9.80665\ \text{m/s}^2$ converted to mm/s² for the mm–kg–N–s unit system. |
