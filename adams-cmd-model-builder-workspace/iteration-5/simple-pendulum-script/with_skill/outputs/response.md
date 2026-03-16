# Simple Pendulum — Adams CMD Script

## Task

Create an Adams CMD script for a simple pendulum with:
- A single rigid link, 200 mm long, mass 1 kg
- Pinned to ground at its top end by a revolute joint
- Gravity in the -Y direction (−9806.65 mm/s²)
- Released from 45° from vertical

---

## Script: `simple_pendulum.cmd`

```cmd
! ============================================================
! Simple Pendulum
!
! A single 200 mm rigid link pinned to ground at the top.
! Released from 45 degrees and allowed to swing freely under gravity.
! Gravity acts in the -Y direction.
!
! Model topology:
!   .pendulum
!   ├── ground
!   │   └── pivot_mkr    (pin point on ground, at origin)
!   └── link
!       ├── cm           (auto-created by Adams when mass_properties is set)
!       ├── pin_mkr      (upper end of link, at part origin / joint location)
!       ├── tip_mkr      (lower end, 200 mm below pin in local -Y)
!       └── rod_mkr      (cylinder geometry reference, Z oriented toward tip)
! ============================================================

! --- 1. Model and units ---
model create model_name = pendulum

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Ground marker at the pivot ---
marker create &
    marker_name = .pendulum.ground.pivot_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 3. Create the link part ---
!     Part origin is placed at the pivot point (global origin).
!     Locating the part origin at the joint simplifies the initial-condition rotation.
part create rigid_body name_and_position &
    part_name   = .pendulum.link &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Set mass/inertia properties ---
!     Adams auto-creates .pendulum.link.cm at the CM when this command runs.
!     Do NOT pass center_of_mass_marker here — .cm does not exist yet.
!
!     For a uniform thin rod of length L = 200 mm, mass m = 1 kg, along the Y-axis:
!       Ixx = Izz = (1/12) * m * L^2 = (1/12) * 1 * 200^2 = 3333.3 kg*mm^2
!       Iyy = 0 (moment about the rod axis itself, zero for a thin rod)
part modify rigid_body mass_properties &
    part_name = .pendulum.link &
    mass      = 1.0 &
    ixx       = 3333.3 &
    iyy       = 0.0 &
    izz       = 3333.3

! --- 5. Markers on the link ---
! Pin marker at the top of the link (coincident with pivot_mkr when link is at 0 deg)
marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! Tip marker at the bottom of the link (200 mm below pin in local -Y direction)
marker create &
    marker_name = .pendulum.link.tip_mkr &
    location    = 0.0, -200.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 6. Revolute joint at the pivot (rotation about global Z axis) ---
!     I marker on the moving part, J marker on ground.
constraint create joint revolute &
    joint_name    = .pendulum.rev_pivot &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pivot_mkr

! --- 7. Set initial orientation: release from 45 degrees ---
!     Body-313 Euler angles (psi=0, theta=0, phi=45D) rotates the link 45 deg about Z.
!     Because the part origin is at the pivot, this rotates the link about the pin.
!     The tip moves from (0, -200, 0) to (141.4, -141.4, 0) in global coordinates.
part modify rigid_body name_and_position &
    part_name   = .pendulum.link &
    orientation = 0.0D, 0.0D, 45.0D

! --- 8. Gravity in the -Y direction ---
force create body gravitational &
    gravity_field_name  = .pendulum.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 9. Visualization geometry ---

! Sphere at the tip to represent the pendulum bob
geometry create shape sphere &
    sphere_name   = .pendulum.link.bob_sphere &
    part_name     = .pendulum.link &
    center_marker = .pendulum.link.tip_mkr &
    radius        = 12.0

! Cylinder for the rod body.
! The cylinder extends along the Z-axis of its center_marker. We need a marker
! whose Z-axis points from the pin toward the tip (in the -Y direction).
! Body-313 Euler orientation = (0D, 90D, 0D):
!   Step 1: rotate about Z by psi=0D  -> no change, Z=(0,0,1)
!   Step 2: rotate about body X by theta=90D -> Z becomes (0,-1,0) = -Y direction
!   Step 3: rotate about new Z by phi=0D -> no change
! Result: Z axis of rod_mkr points in -Y, so the cylinder extends pin -> tip.
marker create &
    marker_name = .pendulum.link.rod_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 90.0D, 0.0D

geometry create shape cylinder &
    cylinder_name            = .pendulum.link.rod_cyl &
    part_name                = .pendulum.link &
    center_marker            = .pendulum.link.rod_mkr &
    length                   = 200.0 &
    radius                   = 4.0 &
    angle_extent             = 360.0D &
    side_count_for_perimeter = 16

! --- 10. Transient simulation ---
!     Runs 2.0 seconds at 1000 steps/s output frequency.
!     initial_static = no: release from the IC without a static solve first.
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .pendulum &
    initial_static  = no
```

---

## Explanation

### Model Topology

| Object | Type | Location | Purpose |
|--------|------|----------|---------|
| `.pendulum.ground.pivot_mkr` | Marker (ground) | (0, 0, 0) | Fixed pivot reference for the joint J marker |
| `.pendulum.link` | Rigid part | (0, 0, 0) | The pendulum rod |
| `.pendulum.link.cm` | Marker (auto) | (0, −100, 0) | Centre of mass — auto-created by Adams |
| `.pendulum.link.pin_mkr` | Marker (link) | (0, 0, 0) | Joint I marker at the top of the rod |
| `.pendulum.link.tip_mkr` | Marker (link) | (0, −200, 0) | Bottom end / bob position |
| `.pendulum.link.rod_mkr` | Marker (link) | (0, 0, 0) | Cylinder geometry reference, Z→−Y |
| `.pendulum.rev_pivot` | Revolute joint | — | 1 rotational DOF about global Z |
| `.pendulum.gravity` | Gravity field | — | −9806.65 mm/s² in Y |

### Key Design Decisions

**Part origin at the pivot**  
Placing the link's part origin (location = 0, 0, 0) at the pivot means the pin marker is at the part origin. When `part modify ... orientation = 0D, 0D, 45D` is called to set the 45° initial condition, the rotation happens naturally about the pivot point — no translation of the pin occurs.

**Build order and `.cm` auto-creation**  
`part modify rigid_body mass_properties` is called *before* creating the pin_mkr and tip_mkr. This is intentional: Adams auto-creates the `.pendulum.link.cm` marker when mass properties are set. If `center_of_mass_marker` were passed to that command before `.cm` exists, Adams would error. Since the CM for a uniform rod falls at the midpoint, Adams places `.pendulum.link.cm` at (0, −100, 0) automatically.

**Inertia values**  
For a uniform thin rod of length L = 200 mm, mass m = 1 kg, lying along the part's Y-axis:

$$I_{xx} = I_{zz} = \frac{1}{12} m L^2 = \frac{1}{12}(1)(200^2) = 3333.3 \ \text{kg·mm}^2$$

$$I_{yy} = 0 \quad \text{(about the rod's own axis)}$$

The pendulum swings in the X-Y plane (rotation about Z), so $I_{zz} = 3333.3\ \text{kg·mm}^2$ is the dynamically significant term.

**Initial condition (45° release)**  
Adams Body-313 Euler angles use the convention (ψ, θ, φ):
- ψ = 0D — no initial Z rotation  
- θ = 0D — no X′ rotation  
- φ = 45D — 45° rotation about Z  

This rotates the hanging link 45° from vertical so that the tip is at:

$$\text{tip} = (200\sin 45°,\ -200\cos 45°,\ 0) = (141.4,\ -141.4,\ 0)\ \text{mm}$$

**Revolute joint**  
A revolute joint removes 5 DOF, leaving 1 rotational DOF about the J marker's Z-axis (global Z, since `pivot_mkr` has orientation 0, 0, 0). The pendulum is therefore constrained to swing in the X-Y plane.

**Geometry — cylinder orientation**  
The `geometry create shape cylinder` extends along the Z-axis of its `center_marker`. To make the cylinder run visually from the pin to the tip (in the −Y direction), a dedicated marker `rod_mkr` is created at the pin location with orientation (0D, 90D, 0D). In Body-313:
- Rotate about body X by θ = 90°: the Z-axis rotates from +Z toward −Y, landing on (0, −1, 0). The cylinder therefore aligns with the rod geometry.

**Simulation**  
`simulation single_run transient` with `initial_static = no` releases the model directly from its 45° initial configuration without first solving for static equilibrium. The solver runs for 2.0 s with 2000 output steps (1 ms resolution).

### Expected Behaviour

The pendulum will oscillate about the vertical. For small angles the period would be:

$$T \approx 2\pi\sqrt{\frac{L_{eff}}{g}} = 2\pi\sqrt{\frac{L/2}{g}} = 2\pi\sqrt{\frac{100\ \text{mm}}{9806.65\ \text{mm/s}^2}} \approx 0.635\ \text{s}$$

At 45° the amplitude is large enough that the nonlinear period will be slightly longer (~0.655 s). With no damping the amplitude will remain constant throughout the 2 s simulation.
