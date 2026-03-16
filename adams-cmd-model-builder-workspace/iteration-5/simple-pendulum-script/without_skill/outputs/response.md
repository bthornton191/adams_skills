# Simple Pendulum – Adams CMD Script

## Model Description

A simple 2D pendulum consisting of a single rigid link pinned to ground at its top end. The link is released from rest at 45 degrees from the vertical.

| Parameter | Value |
|---|---|
| Link length | 200 mm |
| Link mass | 1 kg |
| Pivot location | Origin (0, 0, 0) |
| Joint type | Revolute (Z-axis) |
| Gravity | −Y direction, 9806.65 mm/s² |
| Initial angle from vertical | 45° |
| Initial angular velocity | 0 |

---

## Geometry and Initial Conditions

The pin is fixed at the origin. The pendulum is oriented 45° from the vertical (−Y axis), swinging in the X-Y plane.

At the initial position the key point coordinates are:

**Centre of mass** (mid-point of link):
```
x_cm =  (L/2) · sin(45°) =  100 · 0.70711 =  70.711 mm
y_cm = −(L/2) · cos(45°) = −100 · 0.70711 = −70.711 mm
```

**Free tip** (bottom end):
```
x_tip =  L · sin(45°) = 200 · 0.70711 =  141.421 mm
y_tip = −L · cos(45°) = 200 · 0.70711 = −141.421 mm
```

---

## Mass Properties

**Mass:** 1 kg

**Moment of inertia about the CM** (uniform slender rod, Z-axis governs the planar swing):
```
Izz = (1/12) · m · L²
    = (1/12) · 1.0 · (200)²
    = 3333.33 kg·mm²
```

Ixx and Iyy are set equal to Izz. They do not participate in this planar simulation but a non-degenerate inertia matrix is required by the solver.

**Moment of inertia about the pivot** (for reference, via parallel-axis theorem):
```
I_pivot = Izz_cm + m · d²
        = 3333.33 + 1.0 · (100)²
        = 3333.33 + 10000
        = 13333.33 kg·mm²
```

---

## Model Structure

### Parts

| Part | Type | Role |
|---|---|---|
| `ground` | Implicit ground body | Fixed reference frame |
| `LINK` | Rigid body | The pendulum link |

### Markers

| Marker | On part | Global location at t=0 | Purpose |
|---|---|---|---|
| `GROUND_PIVOT` | ground | (0, 0, 0) | Joint attachment on ground |
| `cm` | LINK | (70.711, −70.711, 0) | Centre of mass (auto-created) |
| `LINK_PIVOT` | LINK | (0, 0, 0) | Joint attachment on link |
| `LINK_TIP` | LINK | (141.421, −141.421, 0) | Free end reference marker |

### Constraints

| Joint | Type | DOF removed | Rotation axis |
|---|---|---|---|
| `REVOLUTE_JOINT` | Revolute | 5 | Z (global) |

The system has **1 degree of freedom**: rotation of the link about the Z-axis through the pivot.

---

## Script

```
! ============================================================
! simple_pendulum.cmd
! Adams/View Command Script
!
! Simple Pendulum Model
!   - Single rigid link, length = 200 mm, mass = 1 kg
!   - Revolute joint to ground at top end (origin)
!   - Gravity in the -Y direction (9806.65 mm/s^2)
!   - Initial angle = 45 degrees from vertical (-Y axis)
!   - Released from rest (zero initial velocity)
! ============================================================

defaults units &
   length = mm &
   angle = deg &
   force = newton &
   mass = kg &
   time = sec

! Create model
model create &
   model_name = SIMPLE_PENDULUM

! ------------------------------------------------------------
! Gravity: -Y direction
! In mm-kg-N units, g = 9806.65 mm/s^2
! ------------------------------------------------------------
force gravity &
   model_name = SIMPLE_PENDULUM &
   x_gravity = 0.0 &
   y_gravity = -9806.65 &
   z_gravity = 0.0

! ============================================================
! Ground pivot marker at the origin
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.ground.GROUND_PIVOT &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Pendulum link
!
! The pin is at the origin. At 45 degrees from the vertical
! (-Y axis), the CM of the link (mid-point) is located at:
!
!   x_cm =  (L/2) * sin(45 deg) = 100 * 0.70711 =  70.7107 mm
!   y_cm = -(L/2) * cos(45 deg) = 100 * 0.70711 = -70.7107 mm
!
! Moment of inertia of a uniform slender rod about its CM:
!   I_perp = (1/12) * m * L^2
!           = (1/12) * 1.0 kg * (200 mm)^2
!           = 3333.33 kg*mm^2
!
! The pendulum swings in the X-Y plane (rotates about Z), so
! Izz is the governing term. Ixx and Iyy are set equal to Izz
! for simplicity (they do not affect this planar motion).
! ============================================================
part create rigid_body name_and_position &
   part_name = .SIMPLE_PENDULUM.LINK &
   location = 70.7107, -70.7107, 0.0 &
   orientation = 0.0, 0.0, 0.0

part create rigid_body mass_properties &
   part_name = .SIMPLE_PENDULUM.LINK &
   mass = 1.0 &
   center_of_mass_marker = .SIMPLE_PENDULUM.LINK.cm &
   ixx = 3333.333 &
   iyy = 3333.333 &
   izz = 3333.333 &
   ixy = 0.0 &
   izx = 0.0 &
   iyz = 0.0

! ============================================================
! Marker on link at the pivot (top end, coincident with origin)
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.LINK.LINK_PIVOT &
   location = 0.0, 0.0, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Marker on link at the free tip (bottom end)
!
!   x_tip =  L * sin(45 deg) = 200 * 0.70711 = 141.4214 mm
!   y_tip = -L * cos(45 deg) = 200 * 0.70711 = -141.4214 mm
! ============================================================
marker create &
   marker_name = .SIMPLE_PENDULUM.LINK.LINK_TIP &
   location = 141.4214, -141.4214, 0.0 &
   orientation = 0.0, 0.0, 0.0

! ============================================================
! Revolute joint: LINK pivot pinned to GROUND pivot
! ============================================================
constraint create joint revolute &
   joint_name = .SIMPLE_PENDULUM.REVOLUTE_JOINT &
   i_marker_name = .SIMPLE_PENDULUM.LINK.LINK_PIVOT &
   j_marker_name = .SIMPLE_PENDULUM.ground.GROUND_PIVOT

! ============================================================
! Transient simulation: 5 seconds, 500 output steps
! No initial static equilibrium (released from 45 deg at rest)
! ============================================================
simulation single_run transient &
   model_name = .SIMPLE_PENDULUM &
   sim_name = .SIMPLE_PENDULUM.ANALYSIS_1 &
   time_duration = 5.0 &
   number_of_steps = 500 &
   initial_static = no
```

---

## Physics Notes

### Expected period

For a physical pendulum (uniform rod) pivoted at one end, the period of small oscillations is:

$$T = 2\pi \sqrt{\frac{I_{pivot}}{m \cdot g \cdot d}}$$

where:
- $I_{pivot} = \frac{1}{3} m L^2 = \frac{1}{3}(1)(0.2)^2 = 0.01\overline{3}\ \text{kg·m}^2$
- $d = L/2 = 0.1\ \text{m}$ (distance from pivot to CM)
- $g = 9.80665\ \text{m/s}^2$

$$T = 2\pi \sqrt{\frac{0.01333}{1 \times 9.80665 \times 0.1}} \approx 2\pi \sqrt{0.1360} \approx 0.733\ \text{s}$$

At 45° the amplitude is not small, so the true period will be slightly longer than this linear approximation.

### Units consistency

The script uses the Adams mm–kg–N unit system:
- Length: millimetres (mm)
- Mass: kilograms (kg)
- Force: Newtons (N)  → requires `g = 9806.65 mm/s²`
- Inertia: kg·mm²

---

## How to Run

1. Open Adams/View.
2. From the menu, choose **File → Import → Adams/View Command File**.
3. Navigate to and select `simple_pendulum.cmd`.
4. Adams will build the model and execute the 5-second transient simulation automatically.
5. Use the **Results** browser or **Strip Chart** to plot the angular displacement of `LINK` vs time.
