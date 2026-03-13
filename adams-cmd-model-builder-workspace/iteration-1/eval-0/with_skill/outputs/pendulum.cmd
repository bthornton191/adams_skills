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
